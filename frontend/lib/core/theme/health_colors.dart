import 'package:flutter/material.dart';

import '../../data/models/business_health.dart';
import 'app_palette.dart';

/// Maps a health rating to colour, icon and plain words. The icon and label
/// carry the meaning on their own, so the colour is reinforcement rather than
/// the only signal.
class HealthAppearance {
  const HealthAppearance({
    required this.color,
    required this.surface,
    required this.icon,
    required this.label,
  });

  final Color color;
  final Color surface;
  final IconData icon;
  final String label;

  static HealthAppearance of(BuildContext context, HealthRating rating) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return switch (rating) {
      HealthRating.green => HealthAppearance(
        color: isLight ? AppPalette.good : AppPalette.goodDark,
        surface: isLight ? const Color(0xFFE6F4EA) : const Color(0xFF14301F),
        icon: Icons.trending_up_rounded,
        label: 'Good',
      ),
      HealthRating.yellow => HealthAppearance(
        color: isLight ? AppPalette.caution : AppPalette.cautionDark,
        surface: isLight ? const Color(0xFFFBF3DC) : const Color(0xFF332A10),
        icon: Icons.remove_rounded,
        label: 'Average',
      ),
      HealthRating.red => HealthAppearance(
        color: isLight ? AppPalette.alert : AppPalette.alertDark,
        surface: isLight ? const Color(0xFFFBE9E9) : const Color(0xFF3A1717),
        icon: Icons.trending_down_rounded,
        label: 'Warning',
      ),
    };
  }
}
