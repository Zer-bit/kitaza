import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/formatting/quantity_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/product.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Text(
            '${_stockLabel()} ${product.unitLabel}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: product.isLowOnStock ? theme.colorScheme.error : null,
              fontWeight: product.isLowOnStock ? FontWeight.w700 : null,
            ),
          ),
          if (product.isLowOnStock) ...[
            const SizedBox(width: AppSpacing.sm),
            const _LowStockBadge(),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            PesoFormatter.format(product.sellingPrice),
            style: theme.textTheme.titleMedium,
          ),
          Text(
            '${product.marginPercent.toStringAsFixed(0)}% margin',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _stockLabel() => QuantityFormatter.exact(product.stockQuantity);
}

class _LowStockBadge extends StatelessWidget {
  const _LowStockBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        'Restock',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
