import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/dashboard_summary.dart';

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
        title: Text(bestSeller.productName),
        subtitle: Text(
          '${_quantity(bestSeller.quantitySold)} sold · '
          '${PesoFormatter.format(bestSeller.revenue)}',
        ),
        trailing: Text('Top seller', style: theme.textTheme.labelMedium),
      ),
    );
  }

  String _quantity(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
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
        title: Text('$count product${count == 1 ? '' : 's'} running low'),
        subtitle: const Text('Tap to see what needs restocking'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
