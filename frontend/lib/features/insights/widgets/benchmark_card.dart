import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/benchmark_report.dart';
import '../../../l10n/l10n.dart';
import '../insights_text.dart';

/// Where this store sits among others of its kind and size. Medians over at
/// least twenty stores, so nothing here is any one store's business.
class BenchmarkCard extends StatelessWidget {
  const BenchmarkCard({super.key, required this.report});

  final BenchmarkReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.benchmarkTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            if (!report.available)
              Text(
                report.unavailableBecause == NoComparison.notSharing
                    ? l10n.benchmarkNotSharing
                    : l10n.benchmarkNotEnough,
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              Text(
                l10n.benchmarkFrom(report.sampleSize),
                style: theme.textTheme.bodySmall,
              ),
              AppSpacing.gapMd,
              for (final comparison in report.comparisons) ...[
                _ComparisonRow(comparison: comparison),
                AppSpacing.gapSm,
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.comparison});

  final Comparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final ahead = comparison.isAhead;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.benchmarkMetric(comparison),
          style: theme.textTheme.titleSmall,
        ),
        AppSpacing.gapXs,
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              l10n.benchmarkYours(
                l10n.benchmarkValue(comparison, comparison.yours),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ahead
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              l10n.benchmarkTypical(
                l10n.benchmarkValue(comparison, comparison.typical),
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
