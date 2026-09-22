import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/report_models.dart';
import '../../../l10n/l10n.dart';

/// Ranked by profit, not revenue. The item that sells most is often not the
/// item that earns most, and that gap is the most useful thing this screen
/// can tell an owner.
class TopProductsCard extends StatelessWidget {
  const TopProductsCard({super.key, required this.products});

  final List<ProductPerformance> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = products.isEmpty
        ? 0.0
        : products.map((p) => p.profit.abs()).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.reportTopProducts,
              style: theme.textTheme.titleMedium,
            ),
            AppSpacing.gapMd,
            for (final product in products)
              _ProductRow(product: product, best: best),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.best});

  final ProductPerformance product;
  final double best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = best == 0 ? 0.0 : (product.profit / best).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.displayProductName(product.productName),
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                PesoFormatter.plain(product.profit),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          AppSpacing.gapXs,
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
