import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_controller.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/page_body.dart';
import '../../shared/widgets/section_header.dart';
import '../authentication/auth_controller.dart';
import 'widgets/account_card.dart';
import 'widgets/backup_card.dart';
import 'widgets/language_selector.dart';
import 'widgets/printer_card.dart';
import 'widgets/problem_reports_tile.dart';
import 'widgets/storage_status_card.dart';
import 'widgets/stores_card.dart';
import 'widgets/team_card.dart';
import 'widgets/theme_mode_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final isOwner = session?.access.isOwner ?? true;
    final isCloud = session?.isCloud ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonSettings)),
      body: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(title: l10n.settingsAppearance),
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsAppearanceHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        AppSpacing.gapMd,
                        SizedBox(
                          width: double.infinity,
                          child: ThemeModeSelector(
                            selected: ref.watch(themeControllerProvider),
                            onChanged: (mode) => ref
                                .read(themeControllerProvider.notifier)
                                .select(mode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapXl,
                SectionHeader(title: l10n.settingsLanguage),
                const Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: SizedBox(
                      width: double.infinity,
                      child: LanguageSelector(),
                    ),
                  ),
                ),
                AppSpacing.gapXl,
                if (isOwner) ...[
                  SectionHeader(title: l10n.settingsTeam),
                  if (isCloud) ...[
                    const StoresCard(),
                    AppSpacing.gapMd,
                    const TeamCard(),
                  ] else
                    const TeamNeedsCloudCard(),
                  AppSpacing.gapXl,
                ],
                SectionHeader(title: l10n.settingsYourData),
                const StorageStatusCard(),
                AppSpacing.gapMd,
                // A staff phone holds a working copy of someone else's
                // store: exporting or replacing it is the owner's call.
                if (isOwner) ...[const BackupCard(), AppSpacing.gapMd],
                const ProblemReportsTile(),
                AppSpacing.gapXl,
                SectionHeader(title: l10n.printerSection),
                const PrinterCard(),
                AppSpacing.gapXl,
                SectionHeader(title: l10n.settingsAccount),
                if (session != null) AccountCard(session: session),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
