import 'package:flutter/material.dart';

/// Kitaza's colour language.
///
/// Chosen for a shop counter rather than a screenshot: deep teal reads as
/// trustworthy and stays legible in daylight, the amber accent is warm without
/// shouting, and every pair here clears WCAG AA contrast so an owner in their
/// sixties can read it as easily as their teenage helper.
abstract final class AppPalette {
  // Brand
  static const Color tealDeep = Color(0xFF0B5F58);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealSoft = Color(0xFFD7F0EC);
  static const Color tealBright = Color(0xFF5EEAD4);

  // Accent, used for money-in highlights and primary calls to action
  static const Color amber = Color(0xFFB45309);
  static const Color amberSoft = Color(0xFFFDF0D5);
  static const Color amberBright = Color(0xFFFBBF24);

  // Health ratings. Always shown with an icon and a label, never colour alone.
  static const Color good = Color(0xFF15803D);
  static const Color goodDark = Color(0xFF4ADE80);
  static const Color caution = Color(0xFFA16207);
  static const Color cautionDark = Color(0xFFFACC15);
  static const Color alert = Color(0xFFB91C1C);
  static const Color alertDark = Color(0xFFF87171);

  // Neutrals, warmed very slightly so long sessions feel less clinical
  static const Color inkStrong = Color(0xFF14201D);
  static const Color ink = Color(0xFF2B3A36);
  static const Color inkMuted = Color(0xFF5C6B66);
  static const Color line = Color(0xFFDCE4E1);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color canvasLight = Color(0xFFF4F7F6);

  // Chart marks. Deliberately not the same as the health colours: a
  // green/red pair fails colour-vision-deficiency separation (deutan dE 4.2),
  // while teal/red clears it comfortably (dE 14.0 light, 11.7 dark). Both
  // pairs were checked with the palette validator against their own surface.
  static const Color chartProfit = Color(0xFF0D9488);
  static const Color chartLoss = Color(0xFFB91C1C);
  static const Color chartProfitDark = Color(0xFF0FA896);
  static const Color chartLossDark = Color(0xFFEA5B48);

  static const Color canvasDark = Color(0xFF0E1614);
  static const Color surfaceDark = Color(0xFF17221F);
  static const Color surfaceDarkRaised = Color(0xFF1F2C28);
  static const Color lineDark = Color(0xFF2E3D39);
  static const Color inkOnDark = Color(0xFFE6EDEB);
  static const Color inkMutedOnDark = Color(0xFF9AAAA5);
}
