import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_store.dart';
import '../../data/models/guide_lesson.dart';

/// Which lessons this phone has opened.
///
/// Remembered only so the list can show where someone got to, and so the
/// dashboard stops offering a guide that has been read. Nothing is ever
/// locked: every lesson can be opened in any order, at any time.
class GuideProgress extends Notifier<Set<GuideLesson>> {
  @override
  Set<GuideLesson> build() {
    final stored = ref.read(preferencesStoreProvider).readGuideRead();
    return {
      for (final lesson in GuideLesson.values)
        if (stored.contains(lesson.name)) lesson,
    };
  }

  Future<void> markRead(GuideLesson lesson) async {
    if (state.contains(lesson)) return;
    state = {...state, lesson};
    await ref.read(preferencesStoreProvider).writeGuideRead([
      for (final read in state) read.name,
    ]);
  }
}

final guideProgressProvider = NotifierProvider<GuideProgress, Set<GuideLesson>>(
  GuideProgress.new,
);

/// Whether the dashboard should still offer the guide. It stops offering once
/// the owner has opened it or waved it away.
class GuideOffer extends Notifier<bool> {
  @override
  bool build() => !ref.read(preferencesStoreProvider).readGuideOffered();

  Future<void> settle() async {
    if (!state) return;
    state = false;
    await ref.read(preferencesStoreProvider).writeGuideOffered(true);
  }
}

final guideOfferProvider = NotifierProvider<GuideOffer, bool>(GuideOffer.new);
