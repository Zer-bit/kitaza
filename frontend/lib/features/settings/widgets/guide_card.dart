import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../data/models/guide_lesson.dart';
import '../../../l10n/l10n.dart';
import '../../authentication/auth_controller.dart';
import '../../guide/guide_progress.dart';

/// The way back into the guide once the dashboard has stopped offering it.
class GuideCard extends ConsumerWidget {
  const GuideCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lessons = GuideLesson.forReader(ref.watch(currentAccessProvider));
    final read = ref.watch(guideProgressProvider);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.school_outlined),
        title: Text(l10n.guideTitle),
        subtitle: Text(
          l10n.guideProgress(
            lessons.where(read.contains).length,
            lessons.length,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(RoutePaths.guide),
      ),
    );
  }
}
