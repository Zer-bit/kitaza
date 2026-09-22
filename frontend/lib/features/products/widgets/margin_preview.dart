import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';

/// Shows the profit per unit as the owner types the two prices. Catching a
/// losing price here is far better than discovering it in a monthly report.
class MarginPreview extends StatelessWidget {
  const MarginPreview({super.key, required this.cost, required this.price});

  final double cost;
  final double price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final margin = price - cost;
    final percent = price <= 0 ? 0.0 : (margin / price) * 100;
    final isLoss = margin < 0;

    final color = isLoss ? theme.colorScheme.error : theme.colorScheme.primary;

    return AnimatedContainer(
      duration: AppMotion.quick,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.fieldAll,
      ),
      child: Row(
        children: [
          Icon(
            isLoss ? Icons.warning_amber_rounded : Icons.savings_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              isLoss
                  ? 'You would lose ${PesoFormatter.format(margin.abs())} per sale'
                  : 'You earn ${PesoFormatter.format(margin)} '
                        '(${percent.toStringAsFixed(0)}%) per sale',
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
