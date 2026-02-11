import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF1E1E2C);
  static const Color secondary = Color(0xFF4A90E2);
  static const Color accent = Color(0xFFE94E77);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  static const Color overlay = Colors.white24;
  static const Color borderFocus = Color(0xFF6C63FF);
  static const Color error = Colors.redAccent;
  static const Color success = Colors.greenAccent;

  static const Color surface = Color(0xFF2A2A40);
  static const Color surfaceVariant = Color(0xFF383854);
  static const Color surfaceContainer = Color(0xFF1F1F2E);

  static const Color shadow = Colors.black54;
  static const Color scrim = Colors.black87;

  // ThemeData (dark base)
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: primary,
    primaryColor: secondary,
    colorScheme: const ColorScheme.dark().copyWith(
      primary: secondary,
      secondary: accent,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      bodySmall: TextStyle(fontSize: 12, color: textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}
