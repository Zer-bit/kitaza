import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/legal_document.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/page_body.dart';

/// The privacy notice or the terms, as plain text on the phone.
///
/// Held in the app rather than fetched, so someone with no signal can still
/// read what they agreed to - which is the whole point of a notice.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = l10n.legalSections(document);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.legalTitle(document))),
      body: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.legalVersion(document.currentVersion),
                  style: theme.textTheme.bodySmall,
                ),
                AppSpacing.gapLg,
                for (final section in sections) ...[
                  Text(section.heading, style: theme.textTheme.titleMedium),
                  AppSpacing.gapSm,
                  for (final paragraph in section.paragraphs) ...[
                    Text(
                      paragraph,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                    AppSpacing.gapSm,
                  ],
                  AppSpacing.gapLg,
                ],
                Text(l10n.legalContact, style: theme.textTheme.bodySmall),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
