import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'my_reports_page.dart';
import 'chatbot_page.dart';
import 'fetched_reports.dart';

class AnalyticsPage extends StatefulWidget {
  final String username;
  const AnalyticsPage({super.key, required this.username});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late final WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse(getWsUrl("/ws/alerts")),
  );

  List alerts = [];
  int _unreadNotifications = 3; // keep unread count same as Dashboard

  @override
  void initState() {
    super.initState();
    fetchInitialAlerts();

    channel.stream.listen((data) {
      try {
        final decoded =
        data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
        setState(() {
          alerts.add(decoded);
          _unreadNotifications++;
        });
      } catch (e) {
        debugPrint("❌ Error parsing WebSocket data: $e");
      }
    });
  }

  @override
  void dispose() {
    try {
      channel.sink.close();
    } catch (_) {}
    super.dispose();
  }

  Future<void> fetchInitialAlerts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrlx/alerts/"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          alerts = data;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching alerts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount =
        alerts.where((a) => (a['severity'] ?? "").toLowerCase() == "critical").length;
    final highCount =
        alerts.where((a) => (a['severity'] ?? "").toLowerCase() == "high").length;
    final mediumCount =
        alerts.where((a) => (a['severity'] ?? "").toLowerCase() == "medium").length;
    final lowCount =
        alerts.where((a) => (a['severity'] ?? "").toLowerCase() == "low").length;

    final total =
    (criticalCount + highCount + mediumCount + lowCount).clamp(1, 999999);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          automaticallyImplyLeading: false,          // no default back/hamburger on the left
          actions: const [SizedBox.shrink()],        // 👈 suppresses default endDrawer icon
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3C8CE7), Color(0xFF00EAFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button + Title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Disaster Analytics",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Right-side notifications + custom menu button
                    Row(
                      children: [
                        const Icon(Icons.notifications,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 16),
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      endDrawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Latest Alerts
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.show_chart,
                            color: Colors.blueAccent, size: 20),
                        SizedBox(width: 6),
                        Text(
                          "Latest Alerts",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (alerts.isEmpty) const Text("No alerts yet"),
                    ...alerts.reversed.take(3).map(
                          (alert) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(color: Colors.red, width: 3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning,
                                    color: Colors.red, size: 28),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert['disaster_type'] ?? "Unknown",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      alert['location'] ?? "Unknown",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _severityColor(
                                      (alert['severity'] ?? "").toLowerCase(),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (alert['severity'] ?? "").toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "2m ago",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Severity Distribution
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bar_chart, color: Colors.green, size: 20),
                        SizedBox(width: 6),
                        Text(
                          "Severity Distribution",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _progressRow("Critical", criticalCount, total, Colors.red),
                    _progressRow("High", highCount, total, Colors.orange),
                    _progressRow("Medium", mediumCount, total, Colors.yellow),
                    _progressRow("Low", lowCount, total, Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(String label, int count, int total, Color color) {
    final percent = (count / total) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: count / total,
              color: color,
              backgroundColor: Colors.grey.shade300,
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text("${percent.toStringAsFixed(0)}%"),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case "critical":
        return Colors.red;
      case "high":
        return Colors.orange;
      case "medium":
        return Colors.amber;
      case "low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Navigation Drawer (synced with Dashboard naming)
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3C8CE7), Color(0xFF00EAFF)],
              ),
            ),
            child: Text(
              "Navigation",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Analytics"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text("My Reports"),
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
            title: const Text("OceanIQ"), // renamed from "Chatbot"
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatBotPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text("Live Social Media Feeda"), // renamed
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InvestigationAnalysisPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: Colors.black),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text("Notifications"),
            onTap: () {
              setState(() => _unreadNotifications = 0);
              Navigator.pop(context);
              Navigator.pushNamed(context, "/notifications");
            },
          ),
        ],
      ),
    );
  }
}
