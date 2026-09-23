import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/build_info.dart';
import '../../../l10n/l10n.dart';

/// Which build this phone is running.
///
/// An owner reporting a problem is asked which version they have, and this is
/// where they read it from. Tapping it copies the line, so it can be pasted
/// into a message without being typed out.
class AboutCard extends ConsumerWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final build = ref.watch(buildInfoProvider);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutVersion(build.version)),
            subtitle: Text(build.platform),
            trailing: const Icon(Icons.copy_outlined),
            onTap: () => _copy(context, l10n.aboutCopied, build),
          ),
          // A build nobody pointed at a server. Worth saying out loud: from
          // the outside it is indistinguishable from a store with no signal.
          if (AppConfig.pointsAtDeveloperMachine)
            ListTile(
              leading: Icon(
                Icons.warning_amber_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l10n.aboutUnreleasedBuild),
            ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String said, BuildInfo build) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: 'Kitaza ${build.version} on ${build.platform}'),
    );
    messenger.showSnackBar(SnackBar(content: Text(said)));
  }
}
