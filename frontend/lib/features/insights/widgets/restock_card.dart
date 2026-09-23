import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/analysis/restock_advisor.dart';
import '../../../l10n/l10n.dart';
import '../insights_text.dart';

/// What to buy before it runs out, soonest first, with the reason beside it.
class RestockCard extends StatelessWidget {
  const RestockCard({super.key, required this.advice});

  final List<RestockAdvice> advice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.restockTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          for (final item in advice) ...[
            const Divider(height: 1),
            // A row rather than a ListTile with a trailing widget: at large
            // text the order line is wider than a small phone's tile.
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.displayProductName(item.product.name),
                    style: theme.textTheme.titleSmall,
                  ),
                  AppSpacing.gapXs,
                  Text(context.l10n.restockReason(item)),
                  AppSpacing.gapSm,
                  Text(
                    context.l10n.restockOrderLine(item),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
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
