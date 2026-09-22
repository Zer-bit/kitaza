import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config/storage_mode.dart';
import '../../core/storage/preferences_store.dart';
import '../local/database/local_database.dart';

/// The store every DAO call is scoped to.
///
/// Held as state rather than read from preferences on demand: a plain read
/// was cached for the life of the app, so signing out and back in as someone
/// else kept writing to the previous owner's store. The auth controller sets
/// this on every session change and everything scoped to it rebuilds.
class ActiveStore extends Notifier<String> {
  @override
  String build() =>
      ref.read(preferencesStoreProvider).readActiveStoreId() ?? '';

  void select(String storeId) => state = storeId;

  void clear() => state = '';
}

final activeStoreIdProvider = NotifierProvider<ActiveStore, String>(
  ActiveStore.new,
);

/// Whether this device syncs, kept alongside the store for the same reason.
class ActiveStorageMode extends Notifier<StorageMode> {
  @override
  StorageMode build() =>
      StorageMode.parse(ref.read(preferencesStoreProvider).readStorageMode());

  void select(StorageMode mode) => state = mode;
}

final storageModeProvider = NotifierProvider<ActiveStorageMode, StorageMode>(
  ActiveStorageMode.new,
);

final databaseProvider = Provider<Database>(
  (ref) => ref.watch(localDatabaseProvider).db,
);

/// Network reachability changes. A provider rather than a direct plugin call
/// so tests can drive the sync coordinator without a platform channel.
final connectivityChangesProvider = Provider<Stream<bool>>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((result) => result != ConnectivityResult.none),
  );
});
