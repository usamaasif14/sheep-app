// app_theme.dart - Main theme configuration for Sheep Manager App
import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - Deep Forest & Gold
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryMedium = Color(0xFF1B2A3D);
  static const Color primaryLight = Color(0xFF243447);
  static const Color accent = Color(0xFFE8A838);
  static const Color accentLight = Color(0xFFFFCC66);
  static const Color accentGreen = Color(0xFF4CAF7D);
  static const Color accentRed = Color(0xFFEF5350);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF607D8B);
  static const Color cardBg = Color(0xFF1B2A3D);
  static const Color cardBorder = Color(0xFF2D3F54);
  static const Color divider = Color(0xFF1E2D3D);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentGreen,
        surface: cardBg,
        background: primaryDark,
        onPrimary: primaryDark,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        error: accentRed,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRed),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryMedium,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: primaryDark,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        selectedColor: accent.withOpacity(0.2),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: textSecondary, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: textMuted, fontFamily: 'Inter'),
        labelLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
    );
  }
}
