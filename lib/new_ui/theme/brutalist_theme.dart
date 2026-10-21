import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrutalColors {
  BrutalColors._();

  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F4);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE2E2E2);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF000000);
  static const Color textMuted = Color(0xFF5F5E61);
  static const Color textSubtle = Color(0xFF7E7576);
  static const Color border = Color(0xFF000000);
  static const Color red = Color(0xFFBA1A1A);
  static const Color green = Color(0xFF1B8A3D);
  static const Color yellow = Color(0xFFFACC15);
}

class BrutalTheme {
  BrutalTheme._();

  static const Border brutalBorderSm = Border.fromBorderSide(
    BorderSide(color: BrutalColors.black, width: 1.5),
  );

  static const Border brutalBorder = Border.fromBorderSide(
    BorderSide(color: BrutalColors.black, width: 2.0),
  );

  static const Border brutalBorderLg = Border.fromBorderSide(
    BorderSide(color: BrutalColors.black, width: 3.0),
  );

  static const List<BoxShadow> brutalShadowSm = [
    BoxShadow(
      color: BrutalColors.black,
      offset: Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> brutalShadow = [
    BoxShadow(
      color: BrutalColors.black,
      offset: Offset(3, 3),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> brutalShadowLg = [
    BoxShadow(
      color: BrutalColors.black,
      offset: Offset(4, 4),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> brutalShadowWhite = [
    BoxShadow(
      color: BrutalColors.white,
      offset: Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static TextStyle headline({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.bold,
    Color color = BrutalColors.black,
    double? letterSpacing = -0.3,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  static TextStyle label({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.bold,
    Color color = BrutalColors.black,
    double? letterSpacing = 0.5,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static TextStyle body({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
    Color color = BrutalColors.black,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  static ThemeData get themeData {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: BrutalColors.background,
      primaryColor: BrutalColors.black,
      colorScheme: const ColorScheme.light(
        primary: BrutalColors.black,
        onPrimary: BrutalColors.white,
        surface: BrutalColors.surface,
        onSurface: BrutalColors.black,
        error: BrutalColors.red,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: BrutalColors.surface,
        foregroundColor: BrutalColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: BrutalColors.black, width: 2),
        ),
      ),
    );
  }
}
