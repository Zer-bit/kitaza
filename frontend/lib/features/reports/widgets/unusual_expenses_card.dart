import 'package:flutter/material.dart';

import '../../../core/formatting/day_formatter.dart';
import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/report_models.dart';

/// Spending that stands out against the store's own history. Each row says
/// exactly why it was flagged, so the owner can dismiss it in their head
/// without wondering what the app is doing.
class UnusualExpensesCard extends StatelessWidget {
  const UnusualExpensesCard({super.key, required this.expenses});

  final List<UnusualExpense> expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Worth a second look', style: theme.textTheme.titleMedium),
              ],
            ),
            AppSpacing.gapMd,
            for (final expense in expenses)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.label,
                            style: theme.textTheme.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          PesoFormatter.format(expense.amount),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Text(
                      '${expense.timesAboveAverage}x your usual '
                      '${PesoFormatter.plain(expense.categoryAverage)} · '
                      '${DayFormatter.dayMonth(expense.occurredAt)}',
                      style: theme.textTheme.bodySmall,
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
