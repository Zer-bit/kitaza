import 'package:flutter/widgets.dart';

/// A four-point spacing scale. Sticking to it is what makes unrelated screens
/// feel like one product.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Below this, a tap target is hard to hit for anyone with less steady
  /// hands. Kitaza never goes smaller.
  static const double minTapTarget = 52;

  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
}

abstract final class AppRadius {
  static const Radius card = Radius.circular(16);
  static const Radius field = Radius.circular(12);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius cardAll = BorderRadius.all(card);
  static const BorderRadius fieldAll = BorderRadius.all(field);
  static const BorderRadius pillAll = BorderRadius.all(pill);
}

abstract final class AppMotion {
  /// Short enough to feel instant, long enough to read as a transition.
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 240);
  static const Curve easing = Curves.easeOutCubic;
}
