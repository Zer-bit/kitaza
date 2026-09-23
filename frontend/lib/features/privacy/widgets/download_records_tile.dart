import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/local/backup/backup_service.dart';
import '../../../data/remote/privacy_api.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';
import '../../authentication/auth_controller.dart';
import '../../backup/backup_platform.dart';

/// The right to a copy of your own records, as one button.
///
/// An offline store already holds everything, so it shares the ordinary
/// backup. A cloud store asks the server for everything it holds, which is a
/// different thing and has to be answered separately.
class DownloadRecordsTile extends ConsumerStatefulWidget {
  const DownloadRecordsTile({super.key});

  @override
  ConsumerState<DownloadRecordsTile> createState() =>
      _DownloadRecordsTileState();
}

class _DownloadRecordsTileState extends ConsumerState<DownloadRecordsTile> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCloud = ref.watch(isCloudModeProvider);

    return Card(
      child: ListTile(
        leading: _working
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
        title: Text(l10n.privacyDownloadTitle),
        subtitle: Text(
          _working
              ? l10n.privacyDownloadWorking
              : isCloud
              ? l10n.privacyDownloadCloud
              : l10n.privacyDownloadLocal,
        ),
        onTap: _working ? null : () => _download(isCloud),
      ),
    );
  }

  Future<void> _download(bool isCloud) async {
    final l10n = context.l10n;
    final store = ref.read(currentSessionProvider)?.store.name ?? l10n.appName;
    setState(() => _working = true);

    try {
      final path = isCloud ? await _serverCopy() : await _phoneCopy();
      await ref
          .read(backupPlatformProvider)
          .shareFile(path, message: l10n.backupExportText(store));
    } on Object {
      if (mounted) {
        FeedbackMessenger.error(context, l10n.privacyDownloadFailed);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String> _phoneCopy() async =>
      (await ref.read(backupServiceProvider).exportCopy()).path;

  /// Plain JSON rather than the database file: a copy is only useful if the
  /// person can open it without Kitaza.
  Future<String> _serverCopy() async {
    final export = await ref.read(privacyApiProvider).export();
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File('${directory.path}/kitaza-records-$stamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(export),
    );
    return file.path;
  }
}
