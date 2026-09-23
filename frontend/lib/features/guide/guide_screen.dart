import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/guide_lesson.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/page_body.dart';
import '../authentication/auth_controller.dart';
import 'guide_progress.dart';
import 'widgets/lesson_card.dart';

/// The lessons, in the order someone new should read them. Lessons about
/// things this person is not allowed to do are left out entirely.
class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lessons = GuideLesson.forReader(ref.watch(currentAccessProvider));
    final read = ref.watch(guideProgressProvider);
    final readHere = lessons.where(read.contains).length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.guideTitle)),
      body: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.guideIntro, style: theme.textTheme.bodyMedium),
                AppSpacing.gapSm,
                Text(
                  l10n.guideProgress(readHere, lessons.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                AppSpacing.gapLg,
                for (final (index, lesson) in lessons.indexed) ...[
                  LessonCard(
                    lesson: lesson,
                    number: index + 1,
                    isRead: read.contains(lesson),
                    onOpen: () => context.push(lesson.path),
                  ),
                  AppSpacing.gapMd,
                ],
                AppSpacing.gapLg,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
