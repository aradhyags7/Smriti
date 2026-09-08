import 'package:flutter/material.dart';

/// Smriti Gentle Care Design System Tokens
class SmritiTheme {
  // Backgrounds
  static const Color backgroundWarm = Color(0xFFF9F6F0);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFEBE6DD);

  // Primary & Secondary Brand Colors
  static const Color forestGreen = Color(0xFF134E42);
  static const Color sageGreen = Color(0xFF1E6554);
  static const Color mintAccent = Color(0xFF9DE0CD);
  static const Color mintSoftBg = Color(0xFFE8F7F2);
  static const Color amberSoftBg = Color(0xFFF9EEDC);
  static const Color amberAccent = Color(0xFFD97706);

  // High-Contrast Stress-Free Typography Colors
  static const Color textDark = Color(0xFF11221C);
  static const Color textSubtle = Color(0xFF4A6B60);
  static const Color textMuted = Color(0xFF7A948B);

  // Theme Data
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundWarm,
      colorScheme: ColorScheme.fromSeed(
        seedColor: forestGreen,
        primary: forestGreen,
        surface: cardWhite,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
        bodyLarge: TextStyle(color: textDark, fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(color: textSubtle, fontSize: 14, height: 1.4),
      ),
    );
  }
}
