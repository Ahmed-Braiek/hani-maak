import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class HaniColors {
  // Official Heni Maak identity sampled directly from the supplied
  // 2026 logo pack (blue / white, stacked / horizontal / icon variants).
  //
  // Dominant sampled stops:
  // #0040B0 -> #1080E0 -> #20A0F0 -> #20B0F0
  static const brandBlueDeep = Color(0xFF0040B0);
  static const brandBlueMid = Color(0xFF1060C0);
  static const brandBlue = Color(0xFF1080E0);
  static const brandSky = Color(0xFF20A0F0);
  static const brandCyan = Color(0xFF20B0F0);
  static const brandWhite = Color(0xFFFFFFFF);
  static const brandIce = Color(0xFFF3FAFF);

  static const ink = Color(0xFF063A78);
  static const inkSoft = Color(0xFF456B91);
  static const primary = brandBlue;
  static const primaryDeep = brandBlueDeep;
  static const primarySoft = Color(0xFFEAF5FF);
  static const mint = Color(0xFFD9F3FF);
  static const aqua = Color(0xFFF2FAFF);
  static const surface = Color(0xFFF7FBFF);
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
      HaniColors.brandBlue,
      HaniColors.brandBlueDeep,
    ],
    stops: [0, .48, 1],
  );

  static const brandPanel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF20B0F0),
      Color(0xFF1080E0),
      Color(0xFF0040B0),
    ],
    stops: [0, .48, 1],
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
