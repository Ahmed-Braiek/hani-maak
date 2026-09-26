import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class HaniColors {
  static const ink = Color(0xFF12324A);
  static const inkSoft = Color(0xFF42647E);
  static const primary = Color(0xFF199AED);
  static const primaryDeep = Color(0xFF0E61C6);
  static const primarySoft = Color(0xFFEAF6FF);
  static const mint = Color(0xFFB9E8FF);
  static const aqua = Color(0xFFEAF8FF);
  static const surface = Color(0xFFF7FBFE);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6E8496);
  static const line = Color(0xFFDDECF6);
  static const warm = Color(0xFFFFF0DC);
  static const warning = Color(0xFFB06C20);
  static const danger = Color(0xFFD85858);
  static const lilac = Color(0xFFEAF0FF);
  static const lilacInk = Color(0xFF345AB8);
}

abstract final class HaniGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF18BFF6), Color(0xFF199AED), Color(0xFF0E61C6)],
  );

  static const soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5FBFF), Color(0xFFEAF6FF)],
  );

  static const wellbeing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8EE), Color(0xFFFFEBD2)],
  );
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

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: HaniColors.ink,
      displayColor: HaniColors.ink,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: HaniColors.surface,
        foregroundColor: HaniColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: HaniColors.ink,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: HaniColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: HaniColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HaniColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HaniColors.ink,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: const BorderSide(color: HaniColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: HaniColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: HaniColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: HaniColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: HaniColors.primarySoft,
        elevation: 0,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? HaniColors.primaryDeep
                : HaniColors.muted,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: HaniColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HaniColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
