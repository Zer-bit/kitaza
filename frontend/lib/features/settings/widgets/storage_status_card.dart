import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../data/repositories/sync_coordinator.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';
import '../../authentication/auth_controller.dart';

/// Where this store's records live, and - in cloud mode - whether they have
/// all made it there.
class StorageStatusCard extends ConsumerWidget {
  const StorageStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isCloudModeProvider)) return const _LocalOnly();
    final status = ref.watch(syncCoordinatorProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_done_outlined),
            title: Text(l10n.storageCloudTitle),
            subtitle: Text(
              status.lastSyncedAt == null
                  ? l10n.storageNotSynced
                  : l10n.storageLastSynced(
                      l10n.relativeDay(status.lastSyncedAt!),
                    ),
            ),
          ),
          if (status.hasPendingWork) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.cloud_upload_outlined,
                color: theme.colorScheme.secondary,
              ),
              title: Text(l10n.storagePending(status.pendingCount)),
              subtitle: Text(l10n.storagePendingHint),
            ),
          ],
          if (status.needsAttention) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.report_problem_outlined,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l10n.storageParked(status.parkedCount),
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: Text(l10n.storageParkedHint),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(RoutePaths.syncProblems),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: Text(l10n.storageSyncNow),
            onTap: () async {
              final coordinator = ref.read(syncCoordinatorProvider.notifier);
              await coordinator.syncNow(force: true);
              if (!context.mounted) return;

              final after = ref.read(syncCoordinatorProvider);
              if (after.phase == SyncPhase.idle) {
                FeedbackMessenger.success(context, l10n.storageUpToDate);
              } else {
                FeedbackMessenger.warn(context, l10n.storageUnreachable);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _LocalOnly extends StatelessWidget {
  const _LocalOnly();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.phone_android_rounded),
            title: Text(l10n.storageLocalTitle),
            subtitle: Text(l10n.storageLocalRisk),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text(l10n.storageBackUp),
            subtitle: Text(l10n.storageBackUpHint),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(RoutePaths.cloudUpgrade),
          ),
        ],
      ),
    );
  }
}
