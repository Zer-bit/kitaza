import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/guide_lesson.dart';
import '../../../l10n/l10n.dart';

/// One numbered instruction. Its number is decoration, not information: the
/// step label above it says the same thing in words, for a screen reader.
class GuideStepTile extends StatelessWidget {
  const GuideStepTile({super.key, required this.step, required this.number});

  final GuideStep step;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.guideStepLabel(number),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.gapXs,
            Text(step.title, style: theme.textTheme.titleMedium),
            AppSpacing.gapSm,
            Text(
              step.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
