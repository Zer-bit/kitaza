import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/l10n.dart';
import '../../guide/guide_progress.dart';

/// Offers the guide once, to someone who has never opened it. Reading it or
/// waving it away settles the question for good - a prompt that comes back
/// every morning is an advert, not help.
class GuidePromptCard extends ConsumerWidget {
  const GuidePromptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(guideOfferProvider)) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.guidePromptTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(l10n.guidePromptBody, style: theme.textTheme.bodyMedium),
              AppSpacing.gapMd,
              // Wrapped, because the two buttons side by side do not fit a
              // small phone at large text in Filipino.
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.tonal(
                    onPressed: () {
                      ref.read(guideOfferProvider.notifier).settle();
                      context.push(RoutePaths.guide);
                    },
                    child: Text(l10n.guidePromptOpen),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(guideOfferProvider.notifier).settle(),
                    child: Text(l10n.guidePromptDismiss),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
