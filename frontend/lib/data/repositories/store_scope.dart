import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/storage/preferences_store.dart';
import '../local/database/local_database.dart';

/// The store every DAO call is scoped to. Reading it from one place means no
/// screen has to thread a store id through its constructor.
final activeStoreIdProvider = Provider<String>((ref) {
  return ref.watch(preferencesStoreProvider).readActiveStoreId() ?? '';
});

final databaseProvider = Provider<Database>(
  (ref) => ref.watch(localDatabaseProvider).db,
);
