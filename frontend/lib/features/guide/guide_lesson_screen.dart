import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/guide_lesson.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/page_body.dart';
import '../authentication/auth_controller.dart';
import 'guide_progress.dart';
import 'widgets/guide_step_tile.dart';

/// One lesson, as numbered steps, ending in the screen it is teaching and the
/// lesson after it.
class GuideLessonScreen extends ConsumerStatefulWidget {
  const GuideLessonScreen({super.key, required this.lesson});

  final GuideLesson lesson;

  @override
  ConsumerState<GuideLessonScreen> createState() => _GuideLessonScreenState();
}

class _GuideLessonScreenState extends ConsumerState<GuideLessonScreen> {
  @override
  void initState() {
    super.initState();
    // Opening it is reading it. Asking someone to confirm they have read
    // something is a hoop, not a feature.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guideProgressProvider.notifier).markRead(widget.lesson);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lesson = widget.lesson;
    final session = ref.watch(currentSessionProvider);
    final steps = l10n.guideSteps(lesson);
    final next = lesson.nextFor(ref.watch(currentAccessProvider));

    // The screen a lesson teaches is only offered when this person could
    // actually open it: a local store has no staff screen to show.
    final opens = lesson.opens;
    final canOpen = opens != null && session != null && mayOpen(session, opens);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.guideLessonTitle(lesson))),
      body: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.guideLessonSummary(lesson),
                  style: theme.textTheme.bodyLarge,
                ),
                AppSpacing.gapLg,
                for (final (index, step) in steps.indexed) ...[
                  GuideStepTile(step: step, number: index + 1),
                  AppSpacing.gapMd,
                ],
                AppSpacing.gapSm,
                if (canOpen)
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(opens),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.guideOpenScreen),
                  ),
                AppSpacing.gapMd,
                if (next != null)
                  FilledButton(
                    onPressed: () => context.pushReplacement(next.path),
                    child: Text(
                      l10n.guideNextLesson(l10n.guideLessonTitle(next)),
                    ),
                  )
                else ...[
                  Text(l10n.guideAllDone, style: theme.textTheme.titleMedium),
                  AppSpacing.gapSm,
                  Text(
                    l10n.guideAllDoneBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                  AppSpacing.gapMd,
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: Text(l10n.guideBackToLessons),
                  ),
                ],
                AppSpacing.gapXl,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
