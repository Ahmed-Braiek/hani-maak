import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class HaniColors {
  static const ink = Color(0xFF142B3A);
  static const primary = Color(0xFF227C89);
  static const primarySoft = Color(0xFFE2F1F2);
  static const surface = Color(0xFFF8FAF9);
  static const card = Colors.white;
  static const muted = Color(0xFF6C7C83);
  static const warm = Color(0xFFF5E9D8);
  static const warning = Color(0xFF9A6228);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: HaniColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: HaniColors.primary,
        brightness: Brightness.light,
        surface: HaniColors.surface,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: HaniColors.ink,
        displayColor: HaniColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: HaniColors.surface,
        foregroundColor: HaniColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: HaniColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE8EEEC)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: HaniColors.primarySoft,
        height: 72,
      ),
    );
  }
}
