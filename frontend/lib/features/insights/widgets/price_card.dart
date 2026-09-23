import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/analysis/price_advisor.dart';
import '../../../l10n/l10n.dart';
import '../insights_text.dart';

/// Prices that are losing money or barely making any, with the arithmetic
/// on show. Nothing here changes a price; that stays the owner's decision.
class PriceCard extends StatelessWidget {
  const PriceCard({super.key, required this.advice});

  final List<PriceAdvice> advice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Icon(Icons.sell_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.priceTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          for (final item in advice) ...[
            const Divider(height: 1),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.displayProductName(item.product.name),
                    style: theme.textTheme.titleSmall,
                  ),
                  AppSpacing.gapXs,
                  Text(
                    l10n.priceReason(item),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: item.issue == PriceIssue.belowCost
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                  AppSpacing.gapSm,
                  if (item.suggestedPrice case final price?)
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.priceTry(PesoFormatter.format(price)),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (item.extraPerMonth > 0)
                          Text(
                            l10n.priceExtraPerMonth(
                              PesoFormatter.format(item.extraPerMonth),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    )
                  else
                    Text(
                      l10n.priceSlowAdvice,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
