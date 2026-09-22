import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/activity_event.dart';
import '../../data/models/signed_in_device.dart';
import '../../data/models/staff_member.dart';
import '../../data/remote/team_api.dart';
import '../../data/repositories/store_scope.dart';

/// The open store's staff, straight from the server.
final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) {
  final storeId = ref.watch(activeStoreIdProvider);
  return ref.watch(teamApiProvider).staff(storeId);
});

final signedInDevicesProvider =
    FutureProvider.autoDispose<List<SignedInDevice>>(
      (ref) => ref.watch(teamApiProvider).devices(),
    );

/// The activity log as far as it has been read, newest first.
class ActivityFeed {
  const ActivityFeed({
    required this.events,
    required this.onlyRemovals,
    this.nextBefore,
    this.loadingMore = false,
  });

  final List<ActivityEvent> events;
  final bool onlyRemovals;
  final int? nextBefore;
  final bool loadingMore;

  bool get hasMore => nextBefore != null;
}

class ActivityController extends AsyncNotifier<ActivityFeed> {
  bool _onlyRemovals = false;

  @override
  Future<ActivityFeed> build() async {
    final storeId = ref.watch(activeStoreIdProvider);
    final page = await ref
        .read(teamApiProvider)
        .activity(storeId, onlyRemovals: _onlyRemovals);
    return ActivityFeed(
      events: page.events,
      onlyRemovals: _onlyRemovals,
      nextBefore: page.nextBefore,
    );
  }

  void showOnlyRemovals(bool only) {
    if (only == _onlyRemovals) return;
    _onlyRemovals = only;
    ref.invalidateSelf();
  }

  /// Appends the next older page. A failure leaves what is shown untouched.
  Future<void> loadOlder() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(
      ActivityFeed(
        events: current.events,
        onlyRemovals: current.onlyRemovals,
        nextBefore: current.nextBefore,
        loadingMore: true,
      ),
    );

    try {
      final page = await ref
          .read(teamApiProvider)
          .activity(
            ref.read(activeStoreIdProvider),
            before: current.nextBefore,
            onlyRemovals: current.onlyRemovals,
          );
      if (!ref.mounted) return;
      state = AsyncData(
        ActivityFeed(
          events: [...current.events, ...page.events],
          onlyRemovals: current.onlyRemovals,
          nextBefore: page.nextBefore,
        ),
      );
    } on Object {
      if (!ref.mounted) return;
      state = AsyncData(current);
      rethrow;
    }
  }
}

final activityProvider =
    AsyncNotifierProvider.autoDispose<ActivityController, ActivityFeed>(
      ActivityController.new,
    );
