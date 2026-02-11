import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'config.dart';

class MyReportsPage extends StatefulWidget {
  final String userId;
  const MyReportsPage({super.key, required this.userId});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  WebSocketChannel? _reportsChannel;
  WebSocketChannel? _notificationsChannel;

  // Store notifications + reports together
  final List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchReports();

    // 🔹 WebSocket for real-time reports
    _reportsChannel = WebSocketChannel.connect(
      Uri.parse(getWsUrl("/citizen/ws/reports")),
    );

    _reportsChannel!.stream.listen((event) {
      final data = jsonDecode(event);
      if (data["user_id"] == widget.userId) {
        setState(() {
          _reportsFuture = _fetchReports();
        });
      }
    });

    // 🔹 WebSocket for notifications
    _notificationsChannel = WebSocketChannel.connect(
      Uri.parse(getWsUrl("/ws/notifications")),
    );

    _notificationsChannel!.stream.listen((event) {
      try {
        final data = jsonDecode(event);
        if (data is Map<String, dynamic>) {
          setState(() {
            _notifications.insert(0, data); // add new notification on top
          });
        }
        print("📩 Notification received: $data");
      } catch (e) {
        print("⚠️ Failed to parse notification: $e");
      }
    });
  }

  @override
  void dispose() {
    _reportsChannel?.sink.close();
    _notificationsChannel?.sink.close();
    super.dispose();
  }

  // ---------------- FETCH REPORTS ----------------
  Future<List<Map<String, dynamic>>> _fetchReports() async {
    final uri = Uri.parse("$baseUrlx/citizen/reports/status/${widget.userId}");
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch reports");
    }

    final json = jsonDecode(res.body);
    final List reports = json["reports"] ?? [];
    return reports.cast<Map<String, dynamic>>();
  }

  // ---------------- REFRESH (Pull to refresh) ----------------
  Future<void> _refreshReports() async {
    setState(() {
      _reportsFuture = _fetchReports();
    });
  }

  // ---------------- UTILS ----------------
  Color _severityColor(String sev) {
    switch (sev.toLowerCase()) {
      case "low":
        return Colors.green.shade400;
      case "medium":
        return Colors.orange.shade400;
      case "high":
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  Widget _severityChip(String sev) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _severityColor(sev).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        sev,
        style: TextStyle(
          color: _severityColor(sev),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getHazardImage(String type) {
    switch (type.toLowerCase()) {
      case "tsunami":
        return "assets/tsunami.png";
      case "flood":
        return "assets/flood.png";
      case "earthquake":
        return "assets/earthquake.png";
      case "landslide":
        return "assets/landslide.png";
      case "cyclone": // ✅ NEW
        return "assets/cyclone.png";
      default:
        return "assets/back.png";
    }
  }

  String _alertTitle(String type) {
    switch (type.toLowerCase()) {
      case "tsunami":
        return "Tsunami Warning";
      case "flood":
        return "Flood Alert";
      case "earthquake":
        return "Earthquake Alert";
      case "landslide":
        return "Landslide Alert";
      case "cyclone": // ✅ NEW
        return "Cyclone Alert";
      default:
        return "General Alert";
    }
  }

  // ---------------- SHOW DETAILS DIALOG ----------------
  void _showDetailsDialog(Map<String, dynamic> report) {
    final status = (report["status"] ?? "pending").toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _alertTitle(report["hazard_type"] ?? "Alert"),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Description: ${report["text"] ?? report["message"] ?? "(No description)"}"),
              const SizedBox(height: 8),
              if (report["lat"] != null && report["lon"] != null)
                Text("Location: Lat ${report["lat"]}, Lon ${report["lon"]}"),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Status: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == "verified"
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: status == "verified"
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              "assets/bitmoji.png", // your logo
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text(
              "Disaster Analytics",
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          final reports = snap.data ?? [];
          final combined = [
            ..._notifications, // newest notifications first
            ...reports, // then fetched reports
          ];

          if (combined.isEmpty) {
            return const Center(child: Text("No alerts found"));
          }

          return RefreshIndicator(
            onRefresh: _refreshReports,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: combined.length,
              itemBuilder: (context, i) {
                final r = combined[i];

                final type =
                (r["hazard_type"] ?? r["title"] ?? "Alert").toString();
                final sev = (r["severity"] ?? "Low").toString();
                final desc = (r["text"] ??
                    r["message"] ??
                    "(No description)")
                    .toString();
                final place = (r["lat"] != null && r["lon"] != null)
                    ? "Lat: ${r["lat"]}, Lon: ${r["lon"]}"
                    : "";

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: _severityColor(sev).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              _getHazardImage(type),
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _alertTitle(type),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    _severityChip(sev),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                if (place.isNotEmpty)
                                  Text(
                                    place,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  desc,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _showDetailsDialog(r); // 👈 Show dialog here
                            },
                            icon:
                            const Icon(Icons.remove_red_eye, size: 18),
                            label: const Text("View Details"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              // TODO: implement acknowledge action
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Acknowledge"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFFF5F6FA),
    );
  }
}
