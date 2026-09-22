import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/formatting/quantity_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/product.dart';
import '../../../l10n/l10n.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
    this.showMargin = true,
  });

  final Product product;

  /// Null for someone who may not edit products.
  final VoidCallback? onTap;

  /// Off for staff who may not see costs, since a margin reveals them.
  final bool showMargin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      // Details wrap onto a second line instead of pushing sideways: a long
      // name, the stock, a restock badge and the margin did not fit one line
      // on a small phone at large text.
      subtitle: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            context.l10n.productStockUnits(_stockLabel(), product.unitLabel),
            style: theme.textTheme.bodySmall?.copyWith(
              color: product.isLowOnStock ? theme.colorScheme.error : null,
              fontWeight: product.isLowOnStock ? FontWeight.w700 : null,
            ),
          ),
          if (product.isLowOnStock) const _LowStockBadge(),
          if (showMargin)
            Text(
              context.l10n.productMargin(
                product.marginPercent.toStringAsFixed(0),
              ),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      trailing: Text(
        PesoFormatter.format(product.sellingPrice),
        style: theme.textTheme.titleMedium,
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
        context.l10n.productRestock,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
