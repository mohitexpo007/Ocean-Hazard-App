import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'hazard_alerts_channel', // 👈 NEW channel id
      'Hazard Alerts',
      channelDescription: 'Critical hazard and disaster alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: const Color(0xFFFF0000), // 🔴 red accent
      ticker: '🚨 Emergency Alert',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: '🚨 ALERT: $title',
        htmlFormatContent: true,
        htmlFormatTitle: true,
      ),
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }
}
