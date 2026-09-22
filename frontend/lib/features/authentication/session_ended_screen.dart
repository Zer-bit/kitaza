import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/local/dao/sync_queue_dao.dart';
import '../../data/repositories/store_scope.dart';
import '../../l10n/l10n.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// How many entries on this phone never reached the cloud.
final unsentEntriesProvider = FutureProvider.autoDispose<int>((ref) async {
  final queue = SyncQueueDao(ref.watch(databaseProvider));
  return await queue.pendingCount() + await queue.parkedCount();
});

/// Shown when the server has signed this phone out. The records stay put:
/// the likeliest reason is an owner tidying their device list, and a cashier
/// who signs back in should find their unsent sales still waiting to go.
class SessionEndedScreen extends ConsumerWidget {
  const SessionEndedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final unsent = ref.watch(unsentEntriesProvider).value;
    final isStaff = session?.access.isStaff ?? false;

    return AuthScaffold(
      title: l10n.sessionEndedTitle,
      subtitle: l10n.sessionEndedMessage(session?.store.name ?? ''),
      children: [
        if (unsent != null)
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  Icon(
                    unsent == 0
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(l10n.sessionEndedUnsent(unsent))),
                ],
              ),
            ),
          ),
        AppSpacing.gapXl,
        FilledButton(
          onPressed: () =>
              context.push(isStaff ? RoutePaths.joinStore : RoutePaths.signIn),
          child: Text(
            isStaff ? l10n.sessionEndedJoin : l10n.sessionEndedSignIn,
          ),
        ),
        AppSpacing.gapMd,
        TextButton(
          onPressed: () => _clear(context, ref, unsent ?? 0),
          child: Text(l10n.sessionEndedClear),
        ),
      ],
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref, int unsent) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sessionEndedClearTitle),
        content: Text(l10n.sessionEndedClearMessage(unsent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: unsent > 0
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor: Theme.of(dialogContext)
                        .colorScheme
                        .onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.sessionEndedClearConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
