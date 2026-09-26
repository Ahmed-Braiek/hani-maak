import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class HaniColors {
  // Official Hani Maak identity sampled from the supplied logo pack.
  static const brandBlueDeep = Color(0xFF084BB4);
  static const brandBlue = Color(0xFF0E66C8);
  static const brandSky = Color(0xFF1896EA);
  static const brandCyan = Color(0xFF18A8F0);

  static const ink = Color(0xFF083B78);
  static const inkSoft = Color(0xFF3F6388);
  static const primary = brandSky;
  static const primaryDeep = brandBlueDeep;
  static const primarySoft = Color(0xFFEAF6FF);
  static const mint = Color(0xFFC7EEFF);
  static const aqua = Color(0xFFF0FAFF);
  static const surface = Color(0xFFF8FCFF);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6A8198);
  static const line = Color(0xFFDCEBF7);
  static const warm = Color(0xFFFFF0DC);
  static const warning = Color(0xFFB06C20);
  static const danger = Color(0xFFD85858);
  static const lilac = Color(0xFFE8F3FF);
  static const lilacInk = brandBlueDeep;
}

abstract final class HaniGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      HaniColors.brandCyan,
      HaniColors.brandSky,
      HaniColors.brandBlueDeep,
    ],
  );

  static const soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FCFF), Color(0xFFEAF6FF)],
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
