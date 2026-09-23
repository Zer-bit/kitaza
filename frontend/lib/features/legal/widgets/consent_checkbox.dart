import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/legal_document.dart';
import '../../../l10n/l10n.dart';

/// Agreeing to the privacy notice and the terms, before an account exists.
///
/// Unticked to begin with: consent that arrives already ticked is not
/// consent. Each document gets its own full-width row rather than a link
/// inside the sentence, because a word-sized tap target is one an older owner
/// with less steady hands cannot reliably hit.
class ConsentCheckbox extends StatelessWidget {
  const ConsentCheckbox({
    super.key,
    required this.agreed,
    required this.onChanged,
    this.showError = false,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;

  /// Set after a failed submit, so the reason sits next to the box rather
  /// than in a message that has already gone.
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final document in LegalDocument.values)
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget,
            ),
            child: TextButton.icon(
              onPressed: () => context.push(RoutePaths.legalFor(document)),
              icon: const Icon(Icons.description_outlined),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(l10n.legalReadLabel(document)),
              ),
              style: TextButton.styleFrom(
                alignment: AlignmentDirectional.centerStart,
                minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
              ),
            ),
          ),
        AppSpacing.gapSm,
        CheckboxListTile(
          value: agreed,
          onChanged: (value) => onChanged(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.legalAgree(l10n.legalReadPrivacy, l10n.legalReadTerms),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (showError && !agreed)
          Text(
            l10n.legalAgreeRequired,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}
