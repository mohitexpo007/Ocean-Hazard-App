import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onClear;

  const NotificationsPage({
    super.key,
    required this.notifications,
    required this.onClear,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black87, size: 26),
              onPressed: widget.onClear,
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white, // top
              Color(0xFFB3E5FC), // light blue
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          // ✅ Add gap equal to appbar + safe area
          padding: const EdgeInsets.only(top: kToolbarHeight + 24),
          child: widget.notifications.isEmpty
              ? const Center(
                  child: Text(
                    "No notifications yet",
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.notifications.length,
                  itemBuilder: (context, index) {
                    final n = widget.notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔴 Big alert icon
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 🔹 Notification text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n["title"] ?? "Alert",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    n["message"] ?? "No details",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 🔹 Timestamp
                            Text(
                              n["timestamp"]?.toString().substring(11, 16) ?? "",
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
