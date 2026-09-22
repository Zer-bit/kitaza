import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/dao/sync_queue_dao.dart';
import '../../../data/models/auth_session.dart';
import '../../../data/repositories/store_scope.dart';
import '../../../data/repositories/sync_coordinator.dart';
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
            subtitle: Text(session.owner.email ?? 'Offline profile'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
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

    final message = switch ((session.isCloud, unsent)) {
      (false, _) => 'Your records are only on this phone. Signing out erases them for good.',
      (true, 0) => 'Everything is backed up. Sign back in on any phone to pick up where you left off.',
      (true, final count) =>
        '$count change${count == 1 ? " has" : "s have"} not reached the cloud '
            'yet, and will be lost if you sign out now. Try again when you '
            'have signal.',
    };

    final destructive = !session.isCloud || unsent > 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
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
            child: Text(destructive ? 'Erase and sign out' : 'Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
