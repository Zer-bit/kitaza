import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/sync_coordinator.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_body.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../authentication/auth_controller.dart';
import '../settings/widgets/sync_indicator.dart';
import 'dashboard_controller.dart';
import 'widgets/health_banner.dart';
import 'widgets/highlight_tiles.dart';
import 'widgets/period_selector.dart';
import 'widgets/quick_action_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final storeName =
        ref.watch(currentSessionProvider)?.store.name ?? 'Your store';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(storeName, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(_greeting(), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          const SyncIndicator(),
          IconButton(
            onPressed: () => context.push(RoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Pulling down is the owner asking "is this up to date?", so in
          // cloud mode it syncs first rather than just re-reading SQLite.
          await ref.read(syncCoordinatorProvider.notifier).syncNow(force: true);
          ref.read(dataRevisionProvider.notifier).bump();
        },
        child: AsyncContent<DashboardSummary>(
          value: summary,
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
          builder: (data) => _DashboardBody(summary: data),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Magandang umaga';
    if (hour < 18) return 'Magandang hapon';
    return 'Magandang gabi';
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      // Always scrollable so pull-to-refresh works even on a short screen.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        PageBody(
          maxWidth: 1000,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuickActionBar(
                onRecordSale: () => context.push(RoutePaths.recordSale),
                onRecordExpense: () => context.push(RoutePaths.recordExpense),
                onViewReports: () => context.go(RoutePaths.reports),
              ),
              AppSpacing.gapXl,
              PeriodSelector(
                selected: summary.period,
                onChanged: (period) =>
                    ref.read(selectedPeriodProvider.notifier).select(period),
              ),
              AppSpacing.gapLg,
              HealthBanner(health: summary.health),
              AppSpacing.gapXl,
              const SectionHeader(title: 'Money this period'),
              _StatGrid(summary: summary),
              AppSpacing.gapXl,
              if (!summary.hasActivity)
                const EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Nothing recorded yet',
                  message:
                      'Tap "Add sale" after your next customer. It takes about '
                      'five seconds and everything else fills in from there.',
                )
              else ...[
                if (summary.bestSeller != null) ...[
                  BestSellerTile(bestSeller: summary.bestSeller!),
                  AppSpacing.gapMd,
                ],
                if (summary.lowStockCount > 0) ...[
                  LowStockTile(
                    count: summary.lowStockCount,
                    onTap: () => context.go(RoutePaths.products),
                  ),
                  AppSpacing.gapMd,
                ],
                _WithdrawalPrompt(total: summary.withdrawalsTotal),
              ],
              AppSpacing.gapXl,
            ],
          ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        label: 'Sales',
        amount: summary.salesTotal,
        icon: Icons.trending_up_rounded,
        caption:
            '${summary.saleCount} sale${summary.saleCount == 1 ? '' : 's'}',
      ),
      StatCard(
        label: 'Expenses',
        amount: summary.expensesTotal,
        icon: Icons.trending_down_rounded,
        caption: 'Cost of goods ${summary.costOfGoods.toStringAsFixed(2)}',
      ),
      StatCard(
        label: 'Profit',
        amount: summary.netProfit,
        icon: Icons.savings_outlined,
        colorBySign: true,
        caption: '${summary.marginPercent.toStringAsFixed(0)}% of sales',
      ),
      StatCard(
        label: 'Cash kept',
        amount: summary.cashMovement,
        icon: Icons.account_balance_wallet_outlined,
        colorBySign: true,
        caption: 'After your withdrawals',
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: context.statColumns,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.55,
      children: cards,
    );
  }
}

class _WithdrawalPrompt extends StatelessWidget {
  const _WithdrawalPrompt({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push(RoutePaths.withdrawals),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: const CircleAvatar(child: Icon(Icons.wallet_rounded)),
        title: const Text('Owner withdrawals'),
        subtitle: Text(
          total > 0
              ? 'You took out ${total.toStringAsFixed(2)} this period'
              : 'Record money you take for personal use',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
