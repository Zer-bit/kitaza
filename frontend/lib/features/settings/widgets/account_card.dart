import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/dao/sync_queue_dao.dart';
import '../../../data/models/auth_session.dart';
import '../../../data/repositories/store_scope.dart';
import '../../../data/repositories/sync_coordinator.dart';
import '../../../l10n/l10n.dart';
import '../../authentication/auth_controller.dart';

class AccountCard extends ConsumerWidget {
  const AccountCard({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(session.owner.fullName),
            subtitle: Text(
              session.owner.email ?? context.l10n.accountOfflineProfile,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: Text(context.l10n.accountSignOut),
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }

  /// Signing out clears this device, so the warning depends on what would
  /// actually be lost: everything in local mode, only unsent changes in cloud
  /// mode. A last sync is attempted first so that number is as small as it
  /// can be.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    var unsent = 0;
    if (session.isCloud) {
      await ref.read(syncCoordinatorProvider.notifier).syncNow(force: true);
      unsent =
          await SyncQueueDao(ref.read(databaseProvider)).pendingCount() +
          await SyncQueueDao(ref.read(databaseProvider)).parkedCount();
    }
    if (!context.mounted) return;
    final l10n = context.l10n;
    final message = switch ((session.isCloud, unsent)) {
      (false, _) => l10n.accountSignOutLocal,
      (true, 0) => l10n.accountSignOutClean,
      (true, final count) => l10n.accountSignOutUnsent(count),
    };

    final destructive = !session.isCloud || unsent > 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountSignOutTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor: Theme.of(dialogContext)
                        .colorScheme
                        .onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              destructive ? l10n.accountEraseAndSignOut : l10n.accountSignOut,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
