import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Map2Widget extends StatefulWidget {
  final List<LatLng> disasterPoints;
  final LatLng? userLocation;
  final MapController mapController;
  final String selectedStyle;
  final Map<String, dynamic> tileStyles;
  final Function(String) onStyleChange;
  final Animation<double> pulseAnimation;

  const Map2Widget({
    super.key,
    required this.disasterPoints,
    required this.userLocation,
    required this.mapController,
    required this.selectedStyle,
    required this.tileStyles,
    required this.onStyleChange,
    required this.pulseAnimation,
  });

  @override
  State<Map2Widget> createState() => _Map2WidgetState();
}

class _Map2WidgetState extends State<Map2Widget>
    with SingleTickerProviderStateMixin {
  bool _didZoom = false;

  // Track our current zoom (classic MapController doesn't expose zoom reliably)
  double _currentZoom = 5.0;

  AnimationController? _zoomController;

  bool _isInDangerZone() {
    if (widget.userLocation == null) return false;
    const Distance distance = Distance();
    for (final p in widget.disasterPoints) {
      if (distance(widget.userLocation!, p) <= 20000) return true; // 20 km
    }
    return false;
  }

  void _startZoomAnimation({
    required LatLng center,
    double targetZoom = 12.0, // ~20 km radius view
    Duration duration = const Duration(seconds: 2),
  }) {
    // Clean up any previous animation
    _zoomController?.dispose();
    _zoomController = AnimationController(vsync: this, duration: duration);

    final curve = CurvedAnimation(parent: _zoomController!, curve: Curves.easeInOut);
    final double startZoom = _currentZoom;

    _zoomController!.addListener(() {
      final t = curve.value;
      final zoom = startZoom + (targetZoom - startZoom) * t;
      widget.mapController.move(center, zoom);
      _currentZoom = zoom; // keep our zoom state in sync
    });

    _zoomController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Snap to final just in case of rounding
        widget.mapController.move(center, targetZoom);
        _currentZoom = targetZoom;
      }
    });

    _zoomController!.forward();
  }

  // Run when we have a location and haven't zoomed yet
  void _autoZoomIfReady() {
    if (_didZoom) return;
    final loc = widget.userLocation;
    if (loc == null) return;

    _didZoom = true;

    // Ensure FlutterMap is laid out before moving camera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startZoomAnimation(center: loc, targetZoom: 12.0, duration: const Duration(seconds: 2));
    });
  }

  @override
  void initState() {
    super.initState();
    _autoZoomIfReady(); // if location already available when Map2 mounts
  }

  @override
  void didUpdateWidget(covariant Map2Widget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If location changes (null -> value or moved), allow re-zoom
    if (oldWidget.userLocation != widget.userLocation) {
      _didZoom = false;
      // reset starting zoom to whatever map is currently at (we track it)
    }
    _autoZoomIfReady();
  }

  @override
  void dispose() {
    _zoomController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSource = widget.tileStyles[widget.selectedStyle];
    final inDanger = _isInDangerZone();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.5937, 78.9629),
              initialZoom: _currentZoom, // start from tracked zoom
            ),
            children: [
              // Base map
              TileLayer(
                key: ValueKey(currentSource.url),
                urlTemplate: currentSource.url,
                subdomains: List<String>.from(currentSource.subdomains),
                userAgentPackageName: 'com.example.myoceanapp',
              ),

              // Blinking red danger points within 20 km
              if (inDanger)
                MarkerLayer(
                  markers: [
                    for (final point in widget.disasterPoints)
                      if (widget.userLocation != null &&
                          const Distance()(widget.userLocation!, point) <= 20000)
                        Marker(
                          point: point,
                          width: 50,
                          height: 50,
                          child: AnimatedBuilder(
                            animation: widget.pulseAnimation,
                            builder: (context, child) => Container(
                              width: widget.pulseAnimation.value,
                              height: widget.pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withOpacity(
                                  1 - (widget.pulseAnimation.value / 30),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),

              // User marker: yellow if danger, green if safe (pulsing)
              if (widget.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.userLocation!,
                      width: 100,
                      height: 100,
                      child: AnimatedBuilder(
                        animation: widget.pulseAnimation,
                        builder: (context, child) => Container(
                          width: widget.pulseAnimation.value,
                          height: widget.pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: inDanger
                                ? Colors.yellow.withOpacity(
                                    1 - (widget.pulseAnimation.value / 30),
                                  )
                                : Colors.green.withOpacity(
                                    1 - (widget.pulseAnimation.value / 30),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Style selector
          Positioned(
            top: 12,
            right: 12,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.layers),
                initialValue: widget.selectedStyle,
                onSelected: widget.onStyleChange,
                itemBuilder: (context) => widget.tileStyles.keys
                    .map((name) => PopupMenuItem(value: name, child: Text(name)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
