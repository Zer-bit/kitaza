import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_token_store.dart';
import '../../core/utils/debouncer.dart';
import '../remote/realtime_channel.dart';
import 'store_scope.dart';
import 'sync_coordinator.dart';

/// Keeps this device listening to its store's live events while signed in to
/// the cloud, so a sale rung up on the counter tablet shows on the owner's
/// phone within seconds.
///
/// An event is only a nudge: it triggers a normal sync, and the pull brings
/// the actual data. That keeps a single path for changes to arrive by, and a
/// missed event costs nothing but a slightly later refresh.
final realtimeConnectionProvider = Provider<void>((ref) {
  final storeId = ref.watch(activeStoreIdProvider);
  final mode = ref.watch(storageModeProvider);
  if (!mode.isCloud || storeId.isEmpty) return;

  final tokens = ref.read(secureTokenStoreProvider);
  final channel = RealtimeChannel(
    storeId: storeId,
    readAccessToken: tokens.readAccessToken,
  );

  // A push of fifty queued sales produces fifty events; they become one sync.
  final debouncer = Debouncer(delay: const Duration(seconds: 1));
  final subscription = channel.events.listen((_) {
    debouncer.run(() => ref.read(syncCoordinatorProvider.notifier).syncNow());
  });

  unawaited(channel.connect());

  ref.onDispose(() {
    debouncer.dispose();
    subscription.cancel();
    channel.dispose();
  });
});
