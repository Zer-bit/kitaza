import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/formatting/day_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/legal_document.dart';
import '../../data/models/privacy_state.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/page_body.dart';
import '../../shared/widgets/section_header.dart';
import '../authentication/auth_controller.dart';
import 'privacy_controller.dart';
import 'widgets/download_records_tile.dart';

/// Everything about this owner's own data in one place: where it is, what
/// they agreed to, how to take a copy, and how to have it deleted.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isCloud = ref.watch(isCloudModeProvider);
    final state = ref.watch(privacyStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyScreenTitle)),
      body: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(title: l10n.privacyWhereTitle),
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Text(
                      isCloud ? l10n.privacyWhereCloud : l10n.privacyWhereLocal,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                AppSpacing.gapXl,
                SectionHeader(title: l10n.privacyDocumentsTitle),
                for (final document in LegalDocument.values) ...[
                  _DocumentTile(document: document, state: state),
                  AppSpacing.gapSm,
                ],
                AppSpacing.gapLg,
                SectionHeader(title: l10n.privacyDownloadTitle),
                const DownloadRecordsTile(),
                AppSpacing.gapXl,
                // Only a cloud store has an account on a server to close.
                // Heading an offline store's screen with "Close my account"
                // would offer something that does not exist.
                if (isCloud) SectionHeader(title: l10n.privacyCloseTitle),
                _CloseAccountTile(isCloud: isCloud, state: state),
                AppSpacing.gapXl,
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.privacyNpcTitle,
                          style: theme.textTheme.titleSmall,
                        ),
                        AppSpacing.gapSm,
                        Text(
                          l10n.privacyNpcBody,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.state});

  final LegalDocument document;
  final PrivacyState? state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final agreement = state?.agreementFor(document);
    final outstanding = state?.outstanding.contains(document) ?? false;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(l10n.legalTitle(document)),
        subtitle: Text(
          outstanding
              ? l10n.legalNeedsAgreement
              : agreement == null
              ? l10n.legalVersion(document.currentVersion)
              : l10n.legalAgreedOn(DayFormatter.fullDate(agreement.agreedAt)),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(RoutePaths.legalFor(document)),
      ),
    );
  }
}

class _CloseAccountTile extends StatelessWidget {
  const _CloseAccountTile({required this.isCloud, required this.state});

  final bool isCloud;
  final PrivacyState? state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // An offline store has no account on a server to close. Offering to close
    // one would be a button that does nothing.
    if (!isCloud) {
      return Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.privacyLocalOnlyTitle,
                style: theme.textTheme.titleSmall,
              ),
              AppSpacing.gapSm,
              Text(
                l10n.privacyLocalOnlyBody,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final deletion = state?.deletion;
    return Card(
      child: ListTile(
        leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
        title: Text(l10n.privacyCloseTitle),
        subtitle: Text(
          deletion == null
              ? l10n.privacyCloseSubtitle
              : l10n.privacyCloseScheduled(
                  DayFormatter.fullDate(deletion.deletesAt),
                ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(RoutePaths.closeAccount),
      ),
    );
  }
}
