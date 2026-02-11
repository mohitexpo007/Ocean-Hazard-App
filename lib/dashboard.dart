import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';
import 'analyticspage.dart';
import 'report_form_widget.dart';
import 'profile.dart';
import 'my_reports_page.dart';
// import 'map1.dart'; // ⛔️ Not needed anymore; Map1Widget is inlined below
import 'map2.dart';
import 'chatbot_page.dart';
import 'fetched_reports.dart';
import 'emergency_service.dart'; // ⬅️ new


// ✅ i18n
import 'l10n/app_localizations.dart';

// 🔹 locale helper shared with main.dart
import 'app_locale.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  const DashboardPage({super.key, required this.username});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _TileSource {
  final String url;
  final List<String> subdomains;
  const _TileSource(this.url, this.subdomains);
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<LatLng> disasterPoints = [];
  LatLng? userLocation;

  final MapController _mapController1 = MapController(); // Prediction map
  final MapController _mapController2 = MapController(); // Live incidents map
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  late WebSocketChannel channel;

  int _selectedPage = 0;
  int _unreadNotifications = 3;
  int _selectedMap = 1; // 1 = Live Incidents, 2 = Predictions (with pins)
  bool _showReportForm = false;

  final Map<String, _TileSource> _tileStyles = const {
    'Mapbox Streets': _TileSource(
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoibWFqZXN0aWMxMDAiLCJhIjoiY21mczYyaWV1MGhiZTJpcG9reWZ5NWQ4diJ9.21rREeVNLvNnEqrGoSH-0Q',
      [],
    ),
    'OSM Standard': _TileSource(
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      ['a', 'b', 'c'],
    ),
    'Carto Dark': _TileSource(
      'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}{r}.png',
      ['a', 'b', 'c', 'd'],
    ),
    'OpenTopoMap': _TileSource(
      'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      ['a', 'b', 'c'],
    ),
  };

  String _selectedStyle = 'Mapbox Streets';

  @override
  void initState() {
    super.initState();
    loadDisasters();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 8, end: 25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });
    });

    channel = WebSocketChannel.connect(
      Uri.parse(getWsUrl("/ws/alerts")),
    );

    channel.stream.listen((data) {
      try {
        final alert = data is String ? jsonDecode(data) : data;
        if (alert["lat"] != null && alert["lon"] != null) {
          setState(() {
            disasterPoints.add(LatLng(alert["lat"], alert["lon"]));
            _unreadNotifications++;
          });
        }
      } catch (e) {
        debugPrint("❌ Error parsing WebSocket data: $e");
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    channel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadDisasters() async {
    try {
      final url = Uri.parse("$baseUrlx/alerts/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          disasterPoints =
              data.map((d) => LatLng(d["lat"], d["lon"])).toList();
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching disasters: $e");
    }
  }

  void _scrollToForm() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      endDrawer: _buildDrawer(context),
      endDrawerEnableOpenDragGesture: true,
      drawerEnableOpenDragGesture: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(108),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          leading: const SizedBox.shrink(),
          actions: const [SizedBox.shrink()],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3C8CE7), Color(0xFF00EAFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
                top: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left profile chip
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfilePage(username: widget.username),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            widget.username.isNotEmpty
                                ? widget.username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.hello,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              widget.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(child: _buildDashboardTab(t)),
    );
  }

  Widget _buildDashboardTab(AppLocalizations t) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Actions
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.quickActions,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.report, color: Colors.white),
                          label: Text(t.reportHazard,
                              style: const TextStyle(color: Colors.white)),
                          onPressed: () {
                            setState(() => _showReportForm = true);
                            _scrollToForm();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.remove_red_eye,
                              color: Colors.white),
                          label: Text(t.liveMonitoring,
                              style: const TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const InvestigationAnalysisPage()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hazard Map View
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF3C8CE7), Color(0xFF00EAFF)]),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.hazardMapView,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: _selectedMap == 1
                  // 👇 Live Incidents (unchanged, uses your existing Map2Widget)
                      ? Map2Widget(
                    disasterPoints: disasterPoints,
                    userLocation: userLocation,
                    mapController: _mapController2,
                    selectedStyle: _selectedStyle,
                    tileStyles: _tileStyles.map(
                          (k, v) =>
                          MapEntry(k, _MapTileSource(v.url, v.subdomains)),
                    ),
                    onStyleChange: (value) =>
                        setState(() => _selectedStyle = value),
                    pulseAnimation: _pulseAnimation,
                  )
                  // 👇 Predictions map — shows RED PIN markers + icon-only layer control
                      : Map1Widget(
                    disasterPoints: disasterPoints,
                    userLocation: userLocation,
                    mapController: _mapController1,
                    selectedStyle: _selectedStyle,
                    tileStyles: _tileStyles,
                    onStyleChange: (value) =>
                        setState(() => _selectedStyle = value),
                    pulseAnimation: _pulseAnimation,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMap = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedMap == 1
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              t.liveIncidents,
                              style: TextStyle(
                                color: _selectedMap == 1
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMap = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedMap == 2
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              t.predictions,
                              style: TextStyle(
                                color: _selectedMap == 2
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statCard("24", t.activeAlerts, Colors.blue),
              _statCard("1.2K", t.reportsToday, Colors.green),
              _statCard("98%", t.accuracy, Colors.purple),
            ],
          ),

          const SizedBox(height: 16),

          // Submit Hazard Report
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.report, color: Colors.white),
            label: Text(t.submitHazardReport,
                style: const TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() => _showReportForm = !_showReportForm);
              _scrollToForm();
            },
          ),

          if (_showReportForm) ...[
            const SizedBox(height: 16),
            ReportFormWidget(userId: widget.username),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3C8CE7), Color(0xFF00EAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTileTheme(
          iconColor: Colors.white,
          textColor: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 12),
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Text(
                  t.navigation,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: Text(t.dashboard),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: Text(t.analytics),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalyticsPage(username: widget.username),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text('Emergency Services'),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmergencyServicesPage()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.list),
                title: Text(t.myReports),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyReportsPage(userId: widget.username),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(t.chatbot),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatBotPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud),
                title: const Text('Live Social Media Feeds'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InvestigationAnalysisPage()),
                  );
                },
              ),

              const Divider(color: Colors.white24, height: 24, thickness: 1),

              // NEW: Translate (EN / HI)
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text("Translate"),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguagePicker(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet with English / Hindi + non-functional names
  /// of all other officially recognized Indian languages.
  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Choose Language",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // ✅ Functional options (unchanged)
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("English"),
                  onTap: () {
                    saveLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                  trailing: (appLocale.value?.languageCode ?? 'en') == 'en'
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: const Text("हिन्दी"),
                  onTap: () {
                    saveLocale(const Locale('hi'));
                    Navigator.pop(context);
                  },
                  trailing: (appLocale.value?.languageCode ?? 'en') == 'hi'
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
                ),

                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('অসমীয়া'), // Assamese
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('বাংলা'), // Bengali
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('बोडो'), // Bodo
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('डोगरी'), // Dogri
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('ગુજરાતી'), // Gujarati
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('ಕನ್ನಡ'), // Kannada
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('کٲشُر'), // Kashmiri (Perso-Arabic)
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('कोंकणी'), // Konkani
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('मैथिली'), // Maithili
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('മലയാളം'), // Malayalam
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('ꯃꯩꯇꯩ ꯂꯣꯟ'), // Manipuri / Meiteilon (Meitei Mayek)
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('मराठी'), // Marathi
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('नेपाली'), // Nepali
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('ଓଡ଼ିଆ'), // Odia
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('ਪੰਜਾਬੀ'), // Punjabi (Gurmukhi)
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('संस्कृतम्'), // Sanskrit
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('ᱥᱟᱱᱛᱟᱲᱤ'), // Santali (Ol Chiki)
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('سنڌي'), // Sindhi (Arabic)
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('தமிழ்'), // Tamil
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('తెలుగు'), // Telugu
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('اردو'), // Urdu
                  enabled: false,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A tiny adapter so we can pass your existing tile styles map
/// to Map2Widget which expects a (url, subdomains) structure.
class _MapTileSource {
  final String url;
  final List<String> subdomains;
  const _MapTileSource(this.url, this.subdomains);
}

/// ─────────────────────────────────────────────────────────────
/// Map 1 widget (Predictions): shows RED PIN markers for hazards
/// and an icon-only layer control (no “Mapbox Streets” text shown)
/// ─────────────────────────────────────────────────────────────
class Map1Widget extends StatelessWidget {
  final List<LatLng> disasterPoints;
  final LatLng? userLocation;
  final MapController mapController;

  final String selectedStyle;
  final Map<String, _TileSource> tileStyles;
  final ValueChanged<String> onStyleChange;
  final Animation<double>? pulseAnimation;

  const Map1Widget({
    super.key,
    required this.disasterPoints,
    required this.userLocation,
    required this.mapController,
    required this.selectedStyle,
    required this.tileStyles,
    required this.onStyleChange,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final _TileSource style = tileStyles[selectedStyle]!;
    final initial = userLocation ??
        (disasterPoints.isNotEmpty
            ? disasterPoints.first
            : const LatLng(20.5937, 78.9629)); // India approx

    // 🔴 Build red pin markers for disaster points (Predictions)
    final hazardMarkers = disasterPoints
        .map(
          (p) => Marker(
        point: p,
        width: 40,
        height: 40,
        alignment: Alignment.bottomCenter,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40,
        ),
      ),
    )
        .toList();

    // 🟦 Optional user-location (blue dot + pulse)
    final List<Widget> userLayers = [];
    if (userLocation != null) {
      userLayers.add(
        MarkerLayer(
          markers: [
            Marker(
              point: userLocation!,
              width: 18,
              height: 18,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      );
      if (pulseAnimation != null) {
        userLayers.add(
          AnimatedBuilder(
            animation: pulseAnimation!,
            builder: (_, __) {
              return CircleLayer(
                circles: [
                  CircleMarker(
                    point: userLocation!,
                    useRadiusInMeter: false,
                    radius: pulseAnimation!.value,
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderStrokeWidth: 0,
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: initial,
            initialZoom: 4.8,
            interactionOptions: const InteractionOptions(
              enableMultiFingerGestureRace: true,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: style.url,
              subdomains: style.subdomains,
              userAgentPackageName: 'com.example.app',
            ),

            // 🔴 Prediction pins
            MarkerLayer(markers: hazardMarkers),

            // 🟦 User location layers
            ...userLayers,
          ],
        ),

        // 🔧 Icon-only style control (no style text on the button)
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStyle,
                isDense: true,
                icon: const Icon(Icons.layers), // 👈 just an icon
                selectedItemBuilder: (context) =>
                    tileStyles.keys.map((_) => const SizedBox.shrink()).toList(),
                items: tileStyles.keys
                    .map(
                      (k) => DropdownMenuItem(
                    value: k,
                    child: Text(k, overflow: TextOverflow.ellipsis),
                  ),
                )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onStyleChange(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
