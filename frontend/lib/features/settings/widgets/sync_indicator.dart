import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/storage_mode.dart';
import '../../../data/repositories/sync_coordinator.dart';
import '../../authentication/auth_controller.dart';

/// A small, honest status light. In local mode it says so rather than showing
/// a permanently unhappy cloud icon.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session == null || session.mode == StorageMode.local) {
      return const _Chip(
        icon: Icons.phone_android_rounded,
        tooltip: 'Saved on this phone',
      );
    }

    final status = ref.watch(syncCoordinatorProvider);

    return switch (status.phase) {
      SyncPhase.syncing => const _Chip(
        icon: Icons.sync_rounded,
        tooltip: 'Syncing',
        spinning: true,
      ),
      SyncPhase.offline => _Chip(
        icon: Icons.cloud_off_rounded,
        tooltip: status.hasPendingWork
            ? '${status.pendingCount} waiting to sync'
            : 'Offline',
      ),
      SyncPhase.failed => const _Chip(
        icon: Icons.error_outline_rounded,
        tooltip: 'Sync problem',
      ),
      SyncPhase.idle => _Chip(
        icon: status.hasPendingWork
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined,
        tooltip: status.hasPendingWork
            ? '${status.pendingCount} waiting to sync'
            : 'Backed up',
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
