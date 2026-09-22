import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/expense_repository.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/money_text.dart';
import '../../shared/widgets/page_body.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/widgets/period_selector.dart';
import 'expense_controller.dart';

class ExpenseHistoryScreen extends ConsumerWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navExpenses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.recordExpense),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.expenseTitle),
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
            child: AsyncContent<List<Expense>>(
              value: expenses,
              onRetry: () => ref.invalidate(expenseHistoryProvider),
              builder: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: context.l10n.expenseHistoryEmptyTitle,
                    message: context.l10n.expenseHistoryEmptyMessage,
                    actionLabel: context.l10n.expenseHistoryEmptyAction,
                    onAction: () => context.push(RoutePaths.recordExpense),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _ExpenseRow(expense: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends ConsumerWidget {
  const _ExpenseRow({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await ref.read(expenseRepositoryProvider).remove(expense.id);
        ref.read(dataRevisionProvider.notifier).localWrite();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            expense.category.icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          expense.description ?? context.l10n.expenseCategory(expense.category),
        ),
        subtitle: Text(
          context.l10n.commonSeparator(
            context.l10n.expenseCategory(expense.category),
            context.l10n.relativeDay(expense.occurredAt),
          ),
        ),
        trailing: MoneyText(expense.amount, size: 17),
      ),
    );
  }
}
