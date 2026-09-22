import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../core/config/storage_mode.dart';
import '../../../data/repositories/sync_coordinator.dart';
import '../../../l10n/l10n.dart';
import '../../authentication/auth_controller.dart';

/// A small, honest status light. In local mode it says so rather than showing
/// a permanently unhappy cloud icon.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session == null || session.mode == StorageMode.local) {
      return _Chip(
        icon: Icons.phone_android_rounded,
        tooltip: context.l10n.syncSavedOnPhone,
      );
    }

    final status = ref.watch(syncCoordinatorProvider);

    // Refused entries outrank every other state: they will not fix themselves.
    if (status.needsAttention) {
      return IconButton(
        onPressed: () => context.push(RoutePaths.syncProblems),
        tooltip: context.l10n.storageParked(status.parkedCount),
        icon: Icon(
          Icons.sync_problem_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }

    return switch (status.phase) {
      SyncPhase.syncing => _Chip(
        icon: Icons.sync_rounded,
        tooltip: context.l10n.syncSyncing,
        spinning: true,
      ),
      SyncPhase.offline => _Chip(
        icon: Icons.cloud_off_rounded,
        tooltip: status.hasPendingWork
            ? context.l10n.syncWaiting(status.pendingCount)
            : context.l10n.syncOffline,
      ),
      SyncPhase.failed => _Chip(
        icon: Icons.error_outline_rounded,
        tooltip: context.l10n.syncProblem,
      ),
      SyncPhase.paused => _Chip(
        icon: Icons.pause_circle_outline_rounded,
        tooltip: context.l10n.syncPaused,
      ),
      SyncPhase.idle => _Chip(
        icon: status.hasPendingWork
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined,
        tooltip: status.hasPendingWork
            ? context.l10n.syncWaiting(status.pendingCount)
            : context.l10n.syncBackedUp,
      ),
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.tooltip,
    this.spinning = false,
  });

  final IconData icon;
  final String tooltip;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final child = Icon(
      icon,
      size: 20,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: spinning
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : child,
      ),
    );
  }
}
