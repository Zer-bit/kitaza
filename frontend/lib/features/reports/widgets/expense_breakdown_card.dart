import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/report_models.dart';

class ExpenseBreakdownCard extends StatelessWidget {
  const ExpenseBreakdownCard({super.key, required this.slices});

  final List<ExpenseSlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<double>(
      0,
      (sum, slice) => sum + slice.totalAmount,
    );

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where your money goes', style: theme.textTheme.titleMedium),
            AppSpacing.gapMd,
            for (final slice in slices)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        slice.categoryName,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      total == 0
                          ? '0%'
                          : '${((slice.totalAmount / total) * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 96,
                      child: Text(
                        PesoFormatter.plain(slice.totalAmount),
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
