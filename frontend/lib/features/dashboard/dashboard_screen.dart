import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/formatting/peso_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/access_grant.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/sync_coordinator.dart';
import '../../l10n/l10n.dart';
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
import 'widgets/starter_prompt_card.dart';
import 'widgets/store_picker.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(dashboardSummaryProvider);
    final session = ref.watch(currentSessionProvider);
    final storeName = session?.store.name ?? l10n.dashboardYourStore;
    final canSwitch = (session?.stores.length ?? 0) > 1;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (canSwitch) const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
        Text(_greeting(l10n), style: Theme.of(context).textTheme.bodySmall),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        // The store name doubles as the switcher for an owner with several
        // stores: where they would look to see which store they are in.
        title: canSwitch
            ? Semantics(
                button: true,
                hint: l10n.storesSwitchHint,
                child: InkWell(
                  onTap: () => StorePicker.show(context),
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 1,
                      child: title,
                    ),
                  ),
                ),
              )
            : title,
        actions: [
          const SyncIndicator(),
          IconButton(
            onPressed: () => context.push(RoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.commonSettings,
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

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.dashboardGoodMorning;
    if (hour < 18) return l10n.dashboardGoodAfternoon;
    return l10n.dashboardGoodEvening;
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(currentAccessProvider);
    final seesProfit = access.can(Permission.viewProfit);

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
                onRecordExpense: access.can(Permission.recordExpenses)
                    ? () => context.push(RoutePaths.recordExpense)
                    : null,
                onViewReports: seesProfit
                    ? () => context.go(RoutePaths.reports)
                    : null,
              ),
              if (access.can(Permission.manageProducts))
                const StarterPromptCard(),
              AppSpacing.gapXl,
              PeriodSelector(
                selected: summary.period,
                onChanged: (period) =>
                    ref.read(selectedPeriodProvider.notifier).select(period),
              ),
              AppSpacing.gapLg,
              if (seesProfit) ...[
                HealthBanner(health: summary.health),
                AppSpacing.gapXl,
              ],
              SectionHeader(title: context.l10n.dashboardMoneyThisPeriod),
              _StatGrid(summary: summary, seesProfit: seesProfit),
              AppSpacing.gapXl,
              if (!summary.hasActivity)
                EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: context.l10n.dashboardEmptyTitle,
                  message: context.l10n.dashboardEmptyMessage,
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
                if (access.isOwner)
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
  const _StatGrid({required this.summary, required this.seesProfit});

  final DashboardSummary summary;

  /// Without it, only takings are shown: the other figures are worked out
  /// from costs this phone was never sent.
  final bool seesProfit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sales = StatCard(
      label: l10n.dashboardSales,
      amount: summary.salesTotal,
      icon: Icons.trending_up_rounded,
      caption: l10n.dashboardSaleCount(summary.saleCount),
    );
    if (!seesProfit) return sales;

    final cards = [
      sales,
      StatCard(
        label: l10n.dashboardExpenses,
        amount: summary.expensesTotal,
        icon: Icons.trending_down_rounded,
        caption: l10n.dashboardCostOfGoods(
          PesoFormatter.format(summary.costOfGoods),
        ),
      ),
      StatCard(
        label: l10n.dashboardProfit,
        amount: summary.netProfit,
        icon: Icons.savings_outlined,
        colorBySign: true,
        caption: l10n.dashboardMarginOfSales(
          summary.marginPercent.toStringAsFixed(0),
        ),
      ),
      StatCard(
        label: l10n.dashboardCashKept,
        amount: summary.cashMovement,
        icon: Icons.account_balance_wallet_outlined,
        colorBySign: true,
        caption: l10n.dashboardAfterWithdrawals,
      ),
    ];

    // Rows that grow with their content rather than a fixed-ratio grid: at
    // large text sizes a fixed ratio clipped the figures. Cards in a row
    // share the tallest card's height so the grid still looks even.
    final columns = context.statColumns;
    return Column(
      children: [
        for (var start = 0; start < cards.length; start += columns) ...[
          if (start > 0) AppSpacing.gapMd,
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) AppSpacing.gapMd,
                  Expanded(
                    child: i < cards.length
                        ? cards[i]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
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
        title: Text(context.l10n.dashboardWithdrawalsTitle),
        subtitle: Text(
          total > 0
              ? context.l10n.dashboardWithdrawalsTaken(
                  PesoFormatter.format(total),
                )
              : context.l10n.dashboardWithdrawalsPrompt,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
