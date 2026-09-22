import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/report_models.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_body.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/widgets/period_selector.dart';
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
      appBar: AppBar(title: const Text('Reports')),
      body: AsyncContent<PeriodReport>(
        value: report,
        onRetry: () => ref.invalidate(periodReportProvider),
        builder: (data) {
          final hasAnything =
              data.trend.isNotEmpty ||
              data.topProducts.isNotEmpty ||
              data.expenseBreakdown.isNotEmpty;

          if (!hasAnything) {
            return const EmptyState(
              icon: Icons.insights_rounded,
              title: 'Nothing to report yet',
              message:
                  'Record a few sales and expenses and this screen will show '
                  'which products earn, where your money goes, and how your '
                  'profit is trending.',
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
