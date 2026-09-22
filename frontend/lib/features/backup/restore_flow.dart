import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_restarter.dart';
import '../../data/local/backup/backup_inspection.dart';
import '../../data/local/backup/backup_service.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import 'backup_platform.dart';

/// Pick a file, show what is in it, and only then replace this phone's data.
///
/// Nothing is touched until the owner has seen the store name, the number of
/// sales and the date of the last entry, and confirmed.
Future<void> restoreFromBackup(BuildContext context, WidgetRef ref) async {
  final path = await ref.read(backupPlatformProvider).pickBackupFile();
  if (path == null || !context.mounted) return;

  final inspection = await ref.read(backupServiceProvider).inspect(path);
  if (!context.mounted) return;

  final l10n = context.l10n;
  if (!inspection.isValid) {
    FeedbackMessenger.error(context, switch (inspection.problem!) {
      BackupProblem.tooNew => l10n.backupProblemTooNew,
      BackupProblem.damaged => l10n.backupProblemDamaged,
      BackupProblem.notABackup ||
      BackupProblem.wrongApp => l10n.backupProblemNotABackup,
    });
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.backupConfirmTitle),
      content: Text(
        [
          l10n.backupConfirmSummary(
            inspection.storeName!,
            inspection.saleCount,
            inspection.productCount,
          ),
          if (inspection.lastActivity != null)
            l10n.backupConfirmLastEntry(
              l10n.relativeDay(inspection.lastActivity!),
            ),
          l10n.backupConfirmWarning,
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.backupConfirmAction),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  await AppRestarter.restart(
    context,
    whileClosed: (closing) => installBackup(
      backupPath: path,
      databasePath: closing.database.path,
      preferences: closing.preferences,
      storeId: inspection.storeId!,
    ),
  );
}
