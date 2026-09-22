import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/local/dao/error_report_dao.dart';
import '../../../data/repositories/data_revision.dart';
import '../../../data/repositories/store_scope.dart';
import '../../../l10n/l10n.dart';
import '../../authentication/auth_controller.dart';

final _reportCountProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(dataRevisionProvider);
  return ErrorReportDao(ref.watch(databaseProvider)).count();
});

/// Shown only when this phone has recorded errors. A cloud store sends them
/// with each sync; an offline store has no connection to us, so the owner
/// can pass them on by message instead.
class ProblemReportsTile extends ConsumerWidget {
  const ProblemReportsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_reportCountProvider).value ?? 0;
    if (count == 0) return const SizedBox.shrink();

    final l10n = context.l10n;
    final isCloud = ref.watch(isCloudModeProvider);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: Text(l10n.reportsTitle(count)),
        subtitle: Text(isCloud ? l10n.reportsCloudHint : l10n.reportsLocalHint),
        onTap: isCloud ? null : () => _share(context, ref),
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final reports = await ErrorReportDao(ref.read(databaseProvider)).pending();
    if (!context.mounted) return;

    final text = [
      context.l10n.reportsShareIntro,
      ...reports.map((report) => report.toSupportText()),
    ].join('\n\n---\n\n');

    await SharePlus.instance.share(ShareParams(text: text, subject: 'Kitaza'));
  }
}
