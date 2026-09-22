import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/formatting/quantity_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/dashboard_summary.dart';
import '../../../l10n/l10n.dart';

class BestSellerTile extends StatelessWidget {
  const BestSellerTile({super.key, required this.bestSeller});

  final BestSeller bestSeller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.star_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(context.l10n.displayProductName(bestSeller.productName)),
        subtitle: Text(
          context.l10n.dashboardSoldSummary(
            QuantityFormatter.exact(bestSeller.quantitySold),
            PesoFormatter.format(bestSeller.revenue),
          ),
        ),
        trailing: Text(
          context.l10n.dashboardTopSeller,
          style: theme.textTheme.labelMedium,
        ),
      ),
    );
  }
}

class LowStockTile extends StatelessWidget {
  const LowStockTile({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.errorContainer,
          child: Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
        title: Text(context.l10n.dashboardLowStock(count)),
        subtitle: Text(context.l10n.dashboardLowStockHint),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
