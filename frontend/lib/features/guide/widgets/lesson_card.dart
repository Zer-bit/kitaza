import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/guide_lesson.dart';
import '../../../l10n/l10n.dart';

/// One lesson in the list: what it covers, how long it is, and whether it has
/// been opened before.
class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.number,
    required this.isRead,
    required this.onOpen,
  });

  final GuideLesson lesson;
  final int number;
  final bool isRead;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadius.cardAll,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Number(number: number, isRead: isRead),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.guideLessonTitle(lesson),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(lesson.icon, color: theme.colorScheme.primary),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                l10n.guideLessonSummary(lesson),
                style: theme.textTheme.bodyMedium,
              ),
              AppSpacing.gapSm,
              // Wraps rather than sits in a row: at large text in Filipino
              // the two labels together are wider than a small phone.
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.guideLessonProgress(lesson.stepCount),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (isRead)
                    Text(
                      l10n.guideRead,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
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

class _Number extends StatelessWidget {
  const _Number({required this.number, required this.isRead});

  final int number;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isRead ? colors.primary : colors.surfaceContainerHighest;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: isRead
          ? Icon(Icons.check, size: 18, color: colors.onPrimary)
          : Text(
              '$number',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
    );
  }
}
