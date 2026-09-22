import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/formatting/peso_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/sale.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/sale_repository.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/money_text.dart';
import '../../shared/widgets/page_body.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/widgets/period_selector.dart';
import '../receipts/receipt_sheet.dart';
import 'sale_history_controller.dart';

class SaleHistoryScreen extends ConsumerWidget {
  const SaleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(saleHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navSales)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.recordSale),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.actionAddSale),
      ),
      body: Column(
        children: [
          PageBody(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: PeriodSelector(
              selected: ref.watch(selectedPeriodProvider),
              onChanged: (period) =>
                  ref.read(selectedPeriodProvider.notifier).select(period),
            ),
          ),
          Expanded(
            child: AsyncContent<List<Sale>>(
              value: sales,
              onRetry: () => ref.invalidate(saleHistoryProvider),
              builder: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.point_of_sale_rounded,
                    title: context.l10n.saleHistoryEmptyTitle,
                    message: context.l10n.saleHistoryEmptyMessage,
                    actionLabel: context.l10n.saleHistoryEmptyAction,
                    onAction: () => context.push(RoutePaths.recordSale),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _SaleRow(sale: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends ConsumerWidget {
  const _SaleRow({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      title: Text(_summary(sale, context.l10n)),
      subtitle: Text(
        context.l10n.commonSeparator(
          context.l10n.relativeDay(sale.occurredAt),
          context.l10n.paymentMethod(sale.paymentMethod),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(sale.totalAmount, size: 17),
          Text(
            context.l10n.saleProfitAmount(
              PesoFormatter.plain(sale.profitAmount),
            ),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      onTap: () => ReceiptSheet.show(context, sale),
      onLongPress: () => _confirmVoid(context, ref),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.saleVoidTitle),
        content: Text(context.l10n.saleVoidMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.saleVoidKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.saleVoidConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(saleRepositoryProvider).voidSale(sale.id);
    ref.read(dataRevisionProvider.notifier).localWrite();

    if (context.mounted) {
      FeedbackMessenger.success(context, context.l10n.saleVoided);
    }
  }
}

/// The history row title: the product when there is one line, otherwise a
/// count.
String _summary(Sale sale, AppLocalizations l10n) =>
    switch (sale.lines.length) {
      0 => l10n.saleGeneric,
      1 => l10n.displayProductName(sale.lines.first.productName),
      final count => l10n.saleItemCount(count),
    };
