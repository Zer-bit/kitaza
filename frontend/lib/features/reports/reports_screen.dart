import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/report_models.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_body.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/widgets/period_selector.dart';
import '../insights/insights_section.dart';
import 'report_controller.dart';
import 'widgets/expense_breakdown_card.dart';
import 'widgets/profit_trend_chart.dart';
import 'widgets/top_products_card.dart';
import 'widgets/unusual_expenses_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(periodReportProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reportTitle)),
      body: AsyncContent<PeriodReport>(
        value: report,
        onRetry: () => ref.invalidate(periodReportProvider),
        builder: (data) {
          final hasAnything =
              data.trend.isNotEmpty ||
              data.topProducts.isNotEmpty ||
              data.expenseBreakdown.isNotEmpty;

          // Nothing sold yet means nothing to chart and nothing to suggest.
          if (!hasAnything) {
            return EmptyState(
              icon: Icons.insights_rounded,
              title: context.l10n.reportEmptyTitle,
              message: context.l10n.reportEmptyMessage,
            );
          }

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              PageBody(
                maxWidth: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PeriodSelector(
                      selected: ref.watch(selectedPeriodProvider),
                      onChanged: (period) => ref
                          .read(selectedPeriodProvider.notifier)
                          .select(period),
                    ),
                    AppSpacing.gapLg,
                    if (data.trend.isNotEmpty) ...[
                      ProfitTrendChart(points: data.trend),
                      AppSpacing.gapMd,
                    ],
                    if (data.topProducts.isNotEmpty) ...[
                      TopProductsCard(products: data.topProducts),
                      AppSpacing.gapMd,
                    ],
                    if (data.expenseBreakdown.isNotEmpty) ...[
                      ExpenseBreakdownCard(slices: data.expenseBreakdown),
                      AppSpacing.gapMd,
                    ],
                    if (data.unusualExpenses.isNotEmpty) ...[
                      UnusualExpensesCard(expenses: data.unusualExpenses),
                      AppSpacing.gapMd,
                    ],
                    const InsightsSection(),
                    AppSpacing.gapXl,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
