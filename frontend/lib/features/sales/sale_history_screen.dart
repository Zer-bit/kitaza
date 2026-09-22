import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/formatting/day_formatter.dart';
import '../../core/formatting/peso_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/sale.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/sale_repository.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/money_text.dart';
import '../../shared/widgets/page_body.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/widgets/period_selector.dart';
import 'sale_history_controller.dart';

class SaleHistoryScreen extends ConsumerWidget {
  const SaleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(saleHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.recordSale),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add sale'),
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
                    title: 'No sales in this period',
                    message:
                        'Every sale you record shows up here with its profit.',
                    actionLabel: 'Add a sale',
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
      title: Text(sale.summaryLabel),
      subtitle: Text(
        '${DayFormatter.relative(sale.occurredAt)} · ${sale.paymentMethod.label}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(sale.totalAmount, size: 17),
          Text(
            '${PesoFormatter.plain(sale.profitAmount)} profit',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      onLongPress: () => _confirmVoid(context, ref),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Void this sale?'),
        content: const Text(
          'The amount is removed from your totals and any stock is put back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Void sale'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(saleRepositoryProvider).voidSale(sale.id);
    ref.read(dataRevisionProvider.notifier).localWrite();

    if (context.mounted) {
      FeedbackMessenger.success(context, 'Sale voided.');
    }
  }
}
