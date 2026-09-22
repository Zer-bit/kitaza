import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/peso_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/local/dao/sync_queue_dao.dart';
import '../../data/repositories/store_scope.dart';
import '../../data/repositories/sync_coordinator.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/queued_change_description.dart';

final _problemsProvider = FutureProvider.autoDispose<List<QueuedChange>>((ref) {
  ref.watch(syncCoordinatorProvider.select((status) => status.parkedCount));
  return SyncQueueDao(ref.watch(databaseProvider)).problems();
});

/// Entries the cloud refused, with the server's reason in plain words.
///
/// Nothing here is ever deleted from the owner's own records: discarding only
/// stops trying to upload that entry. It stays on this phone.
class SyncProblemsScreen extends ConsumerWidget {
  const SyncProblemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problems = ref.watch(_problemsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.problemsTitle)),
      body: AsyncContent<List<QueuedChange>>(
        value: problems,
        onRetry: () => ref.invalidate(_problemsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.cloud_done_rounded,
              title: context.l10n.problemsEmptyTitle,
              message: context.l10n.problemsEmptyMessage,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _ProblemTile(change: items[index]),
          );
        },
      ),
    );
  }
}

class _ProblemTile extends ConsumerWidget {
  const _ProblemTile({required this.change});

  final QueuedChange change;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final description = QueuedChangeDescription.of(change, l10n);
    final parked = change.attempts >= SyncQueueDao.maxAttempts;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                description.icon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  description.title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (description.amount != null)
                Text(
                  PesoFormatter.format(description.amount!),
                  style: theme.textTheme.titleMedium,
                ),
            ],
          ),
          AppSpacing.gapXs,
          Text(
            change.lastError ?? l10n.problemsRefused,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          Text(
            parked
                ? l10n.problemsStopped(change.attempts)
                : l10n.problemsWillRetry(change.attempts),
            style: theme.textTheme.bodySmall,
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              TextButton.icon(
                onPressed: () => ref
                    .read(syncCoordinatorProvider.notifier)
                    .retryParked(change.rowId),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.commonTryAgain),
              ),
              TextButton.icon(
                onPressed: () => _confirmDiscard(context, ref),
                icon: const Icon(Icons.cloud_off_rounded),
                label: Text(l10n.problemsKeepLocal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.problemsDiscardTitle),
        content: Text(context.l10n.problemsDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.problemsKeepLocal),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(syncCoordinatorProvider.notifier)
          .discardParked(change.rowId);
    }
  }
}
