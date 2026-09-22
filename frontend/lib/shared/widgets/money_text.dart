import 'package:flutter/material.dart';

import '../../core/formatting/peso_formatter.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';

/// Renders a peso amount at a readable size, colouring it only when the sign
/// carries meaning.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.size = 24,
    this.showSign = false,
    this.colorBySign = false,
    this.compact = false,
  });

  final double amount;
  final double size;
  final bool showSign;
  final bool colorBySign;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final color = switch ((colorBySign, amount)) {
      (true, < 0) => isLight ? AppPalette.alert : AppPalette.alertDark,
      (true, > 0) => isLight ? AppPalette.good : AppPalette.goodDark,
      _ => Theme.of(context).colorScheme.onSurface,
    };

    final label = switch ((showSign, compact)) {
      (true, _) => PesoFormatter.signed(amount),
      (_, true) => PesoFormatter.compact(amount),
      _ => PesoFormatter.format(amount),
    };

    return Text(
      label,
      style: AppTypography.money(color, size),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
