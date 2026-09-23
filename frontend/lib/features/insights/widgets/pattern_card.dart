import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/analysis/seasonality.dart';
import '../../../l10n/l10n.dart';
import '../insights_text.dart';

/// When this store sells: payday weeks and the best day of the week, both
/// measured from its own takings rather than assumed.
class PatternCard extends StatelessWidget {
  const PatternCard({
    super.key,
    required this.payday,
    required this.nextPayday,
    this.busiestDay,
  });

  final PaydayPattern payday;
  final DateTime nextPayday;
  final BusiestDay? busiestDay;

  static bool worthShowing(PaydayPattern payday, BusiestDay? busiest) =>
      payday.isReliable || (busiest?.isReliable ?? false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final busiest = busiestDay;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.patternTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            if (payday.isReliable) ...[
              Text(l10n.paydayLine(payday.upliftPercent)),
              AppSpacing.gapXs,
              Text(
                l10n.nextPaydayLine(nextPayday),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (busiest != null && busiest.isReliable) ...[
              if (payday.isReliable) AppSpacing.gapMd,
              Text(l10n.busiestDayLine(busiest.weekday, busiest.upliftPercent)),
            ],
          ],
        ),
      ),
    );
  }
}
