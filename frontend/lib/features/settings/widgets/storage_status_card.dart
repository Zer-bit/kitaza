import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../core/formatting/day_formatter.dart';
import '../../../data/repositories/sync_coordinator.dart';
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

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_done_outlined),
            title: const Text('Backed up to the cloud'),
            subtitle: Text(
              status.lastSyncedAt == null
                  ? 'Not synced yet'
                  : 'Last synced ${DayFormatter.relative(status.lastSyncedAt!)}',
            ),
          ),
          if (status.hasPendingWork) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.cloud_upload_outlined,
                color: theme.colorScheme.secondary,
              ),
              title: Text('${status.pendingCount} waiting to upload'),
              subtitle: const Text('These go up as soon as you have signal.'),
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
                '${status.parkedCount} could not be saved',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: const Text('Tap to see why and decide what to do'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(RoutePaths.syncProblems),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: const Text('Sync now'),
            onTap: () async {
              final coordinator = ref.read(syncCoordinatorProvider.notifier);
              await coordinator.syncNow(force: true);
              if (!context.mounted) return;

              final after = ref.read(syncCoordinatorProvider);
              if (after.phase == SyncPhase.idle) {
                FeedbackMessenger.success(context, 'Everything is up to date.');
              } else {
                FeedbackMessenger.warn(
                  context,
                  after.lastError ??
                      'Could not reach the cloud. Will try again.',
                );
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
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.phone_android_rounded),
            title: Text('Saved on this phone only'),
            subtitle: Text(
              'If this phone is lost or broken, your records go with it.',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Back up to the cloud'),
            subtitle: const Text('Keeps everything you have recorded so far'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(RoutePaths.cloudUpgrade),
          ),
        ],
      ),
    );
  }
}
