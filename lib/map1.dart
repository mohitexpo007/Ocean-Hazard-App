import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Map1Widget extends StatelessWidget {
  final List<LatLng> disasterPoints;
  final LatLng? userLocation;
  final MapController mapController;
  final String selectedStyle;
  final Map<String, dynamic> tileStyles;
  final Function(String) onStyleChange;
  final Animation<double> pulseAnimation;

  const Map1Widget({
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
  Widget build(BuildContext context) {
    final currentSource = tileStyles[selectedStyle];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: LatLng(20.5937, 78.9629), // Center on India
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                key: ValueKey(currentSource.url),
                urlTemplate: currentSource.url,
                subdomains: List<String>.from(currentSource.subdomains),
                userAgentPackageName: 'com.example.myoceanapp',
              ),
              CircleLayer(
                circles: [
                  for (final point in disasterPoints)
                    CircleMarker(
                      point: point,
                      color: Colors.red.withOpacity(0.5),
                      borderStrokeWidth: 2,
                      borderColor: Colors.red,
                      radius: 60,
                    ),
                ],
              ),
              if (userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation!,
                      width: 100,
                      height: 100,
                      child: AnimatedBuilder(
                        animation: pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: pulseAnimation.value,
                            height: pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(
                                1 - (pulseAnimation.value / 30),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
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
                initialValue: selectedStyle,
                onSelected: onStyleChange,
                itemBuilder: (context) => tileStyles.keys
                    .map(
                      (name) => PopupMenuItem(
                        value: name,
                        child: Text(name),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
