import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand royal blue matching the web reference screenshot (#0A33FF / #2563EB)
  static const Color bluePrimary = Color(0xFF1442FF);
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color blueDark = Color(0xFF1D4ED8);

  static const Color emeraldGain = Color(0xFF10B981);
  static const Color roseLoss = Color(0xFFEF4444);
  static const Color amberAccent = Color(0xFFF59E0B);

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.bluePrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color(0xFF1E3A8A),
      secondary: AppColors.emeraldGain,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD1FAE5),
      onSecondaryContainer: Color(0xFF065F46),
      tertiary: AppColors.amberAccent,
      onTertiary: Colors.white,
      error: AppColors.roseLoss,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.slate900,
      surfaceContainerHighest: AppColors.slate100,
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.slate50,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.blueLight,
      onPrimary: AppColors.slate900,
      primaryContainer: Color(0xFF1E3A8A),
      onPrimaryContainer: Color(0xFFDBEAFE),
      secondary: AppColors.emeraldGain,
      onSecondary: Color(0xFF022C22),
      secondaryContainer: Color(0xFF064E3B),
      onSecondaryContainer: Color(0xFFD1FAE5),
      tertiary: AppColors.amberAccent,
      onTertiary: AppColors.slate900,
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      surface: AppColors.slate800,
      onSurface: Color(0xFFF8FAFC),
      surfaceContainerHighest: AppColors.slate700,
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF475569),
      outlineVariant: Color(0xFF334155),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.slate900,
      cardTheme: CardThemeData(
        color: AppColors.slate800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.slate700, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate800,
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
