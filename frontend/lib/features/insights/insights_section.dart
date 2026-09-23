import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/benchmark_report.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/section_header.dart';
import 'insights_providers.dart';
import 'widgets/benchmark_card.dart';
import 'widgets/pattern_card.dart';
import 'widgets/price_card.dart';
import 'widgets/restock_card.dart';

/// What the store's own records suggest, and how they compare with similar
/// stores. Everything here says what it is based on, and nothing acts on its
/// own.
class InsightsSection extends ConsumerWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final insights = ref.watch(storeInsightsProvider).value;
    final benchmarks = ref.watch(benchmarkReportProvider).value;
    if (insights == null) return const SizedBox.shrink();

    final showBenchmarks =
        benchmarks != null &&
        (benchmarks.available ||
            benchmarks.unavailableBecause == NoComparison.notSharing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.gapLg,
        SectionHeader(title: l10n.insightsTitle),
        if (insights.isEarlyDays && !insights.hasAnything)
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Text(l10n.insightsEarlyDays),
            ),
          ),
        if (insights.restock.isNotEmpty) ...[
          RestockCard(advice: insights.restock),
          AppSpacing.gapMd,
        ],
        if (insights.prices.isNotEmpty) ...[
          PriceCard(advice: insights.prices),
          AppSpacing.gapMd,
        ],
        if (PatternCard.worthShowing(insights.payday, insights.busiestDay)) ...[
          PatternCard(
            payday: insights.payday,
            nextPayday: insights.nextPayday,
            busiestDay: insights.busiestDay,
          ),
          AppSpacing.gapMd,
        ],
        if (showBenchmarks) ...[
          BenchmarkCard(report: benchmarks),
          AppSpacing.gapMd,
        ],
        if (insights.hasAnything) const _HowThisWorks(),
      ],
    );
  }
}

/// The arithmetic, for an owner who wants to check it.
class _HowThisWorks extends StatelessWidget {
  const _HowThisWorks();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline_rounded),
        title: Text(l10n.insightsHowTitle),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l10n.insightsHowBody),
          ),
        ],
      ),
    );
  }
}
