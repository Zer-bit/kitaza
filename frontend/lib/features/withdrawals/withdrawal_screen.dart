import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/owner_withdrawal.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/withdrawal_repository.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/amount_field.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/money_text.dart';
import '../../shared/widgets/page_body.dart';
import '../../shared/widgets/section_header.dart';
import 'withdrawal_controller.dart';

/// Separating owner withdrawals from expenses is the single change that makes
/// most small-business books honest: taking cash home is not a business cost,
/// and mixing the two hides whether the store actually earns.
class WithdrawalScreen extends ConsumerWidget {
  const WithdrawalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(withdrawalHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.withdrawalTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _RecordWithdrawalSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.withdrawalRecord),
      ),
      body: Column(
        children: [
          const PageBody(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: _ExplainerCard(),
          ),
          Expanded(
            child: AsyncContent<List<OwnerWithdrawal>>(
              value: history,
              onRetry: () => ref.invalidate(withdrawalHistoryProvider),
              builder: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.wallet_rounded,
                    title: context.l10n.withdrawalEmptyTitle,
                    message: context.l10n.withdrawalEmptyMessage,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _WithdrawalRow(withdrawal: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplainerCard extends StatelessWidget {
  const _ExplainerCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.withdrawalExplainer,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawalRow extends ConsumerWidget {
  const _WithdrawalRow({required this.withdrawal});

  final OwnerWithdrawal withdrawal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(withdrawal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await ref.read(withdrawalRepositoryProvider).remove(withdrawal.id);
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
        title: Text(withdrawal.reason ?? context.l10n.withdrawalDefaultReason),
        subtitle: Text(context.l10n.relativeDay(withdrawal.occurredAt)),
        trailing: MoneyText(withdrawal.amount, size: 17),
      ),
    );
  }
}

class _RecordWithdrawalSheet extends ConsumerStatefulWidget {
  const _RecordWithdrawalSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _RecordWithdrawalSheet(),
    );
  }

  @override
  ConsumerState<_RecordWithdrawalSheet> createState() =>
      _RecordWithdrawalSheetState();
}

class _RecordWithdrawalSheetState
    extends ConsumerState<_RecordWithdrawalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    await ref
        .read(withdrawalRepositoryProvider)
        .record(amount: double.parse(_amount.text), reason: _reason.text);
    ref.read(dataRevisionProvider.notifier).localWrite();

    if (!mounted) return;
    Navigator.pop(context);
    FeedbackMessenger.success(context, context.l10n.withdrawalRecorded);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: context.l10n.withdrawalSheetTitle),
            AmountField(controller: _amount, autofocus: true),
            AppSpacing.gapLg,
            TextFormField(
              controller: _reason,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.withdrawalReason,
                hintText: context.l10n.withdrawalReasonHint,
              ),
            ),
            AppSpacing.gapXl,
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(context.l10n.withdrawalSubmit),
            ),
            AppSpacing.gapMd,
          ],
        ),
      ),
    );
  }
}
