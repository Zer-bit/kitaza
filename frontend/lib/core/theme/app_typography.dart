import 'package:flutter/material.dart';

/// Body text starts at 16 and money never drops below 20. Small type is the
/// single most common reason an owner hands the phone to someone younger.
abstract final class AppTypography {
  static const String _family = 'Roboto';

  static TextTheme forColor(Color ink, Color muted) {
    return TextTheme(
      displaySmall: _style(34, FontWeight.w700, ink, height: 1.15),
      headlineMedium: _style(26, FontWeight.w700, ink, height: 1.2),
      headlineSmall: _style(22, FontWeight.w700, ink, height: 1.25),
      titleLarge: _style(19, FontWeight.w600, ink),
      titleMedium: _style(17, FontWeight.w600, ink),
      bodyLarge: _style(16, FontWeight.w400, ink, height: 1.45),
      bodyMedium: _style(15, FontWeight.w400, ink, height: 1.45),
      bodySmall: _style(14, FontWeight.w400, muted, height: 1.4),
      labelLarge: _style(16, FontWeight.w600, ink),
      labelMedium: _style(14, FontWeight.w600, muted, letterSpacing: 0.2),
      labelSmall: _style(12, FontWeight.w600, muted, letterSpacing: 0.6),
    );
  }

  /// Tabular figures keep peso columns aligned as digits change.
  static TextStyle money(Color color, double size) => TextStyle(
    fontFamily: _family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
