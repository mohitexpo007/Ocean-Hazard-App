import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  WebSocketChannel? _channel;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // ✅ Initialize local notifications
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

    await _localNotifications.initialize(initSettings);

    // ✅ Connect to backend WebSocket ONCE
    _channel = WebSocketChannel.connect(
      Uri.parse("wss://paronymic-noncontumaciously-clarence.ngrok-free.dev/ws/notifications"),
    );

    _channel!.stream.listen((event) {
      final data = jsonDecode(event);
      _showNotification(data);
    });
  }

  Future<void> _showNotification(Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alerts_channel', // channel ID
      'Alerts', // channel name
      channelDescription: 'Incoming hazard alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      data["title"] ?? "Alert",
      data["message"] ?? "New alert received",
      platformDetails,
    );
  }

  void dispose() {
    _channel?.sink.close();
  }
}
