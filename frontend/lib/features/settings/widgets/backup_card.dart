import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_store.dart';
import '../../../data/local/backup/backup_service.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';
import '../../authentication/auth_controller.dart';
import '../../backup/backup_platform.dart';
import '../../backup/restore_flow.dart';

class BackupCard extends ConsumerWidget {
  const BackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isCloud = ref.watch(isCloudModeProvider);
    final lastAuto = DateTime.tryParse(
      ref.watch(preferencesStoreProvider).readLastAutoBackup() ?? '',
    );

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(l10n.backupSection),
            subtitle: Text(
              [
                lastAuto == null
                    ? l10n.backupAutoNone
                    : l10n.backupAutoLast(l10n.relativeDay(lastAuto)),
                if (isCloud) l10n.backupCloudNote,
              ].join(' '),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: Text(l10n.backupExport),
            subtitle: Text(l10n.backupExportHint),
            onTap: () => _export(context, ref),
          ),
          // Restoring replaces this phone's records wholesale. In cloud mode
          // the cloud is the source of truth, so a file must not override it.
          if (!isCloud) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore_rounded),
              title: Text(l10n.backupRestore),
              subtitle: Text(l10n.backupRestoreHint),
              onTap: () => restoreFromBackup(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final store = ref.read(currentSessionProvider)?.store.name ?? l10n.appName;

    try {
      final file = await ref.read(backupServiceProvider).exportCopy();
      await ref
          .read(backupPlatformProvider)
          .shareFile(file.path, message: l10n.backupExportText(store));
    } on Object {
      if (context.mounted) {
        FeedbackMessenger.error(context, l10n.backupExportFailed);
      }
    }
  }
}
