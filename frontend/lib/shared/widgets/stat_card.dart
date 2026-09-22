import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'money_text.dart';

/// One number with its label. The dashboard is mostly these, so the card keeps
/// itself plain and lets the figure do the talking.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.amount,
    this.icon,
    this.caption,
    this.colorBySign = false,
    this.onTap,
  });

  final String label;
  final double amount;
  final IconData? icon;
  final String? caption;
  final bool colorBySign;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              MoneyText(amount, size: 22, colorBySign: colorBySign),
              if (caption != null) ...[
                AppSpacing.gapXs,
                Text(
                  caption!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
