import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/preferences_store.dart';
import '../database/local_database.dart';
import 'backup_inspection.dart';

/// Copies of the on-device database: made automatically each day, exported by
/// the owner, and restored onto a new phone.
///
/// For a store that keeps records only on this phone, a backup file is the
/// only protection against a lost or broken device.
class BackupService {
  BackupService({
    required this.database,
    required this.databasePath,
    required this.preferences,
    Future<Directory> Function()? documentsDirectory,
    DatabaseFactory? factory,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _factory = factory ?? databaseFactory;

  final Database database;
  final String databasePath;
  final PreferencesStore preferences;
  final Future<Directory> Function() _documentsDirectory;
  final DatabaseFactory _factory;

  static const String fileExtension = 'kitaza';
  static const int automaticCopiesKept = 7;
  static const Duration automaticInterval = Duration(hours: 20);

  static const List<String> _requiredTables = [
    'owners',
    'stores',
    'products',
    'sales',
    'sale_items',
    'expenses',
  ];

  /// A consistent copy of the database at [destination].
  ///
  /// `VACUUM INTO` would be simpler but needs SQLite 3.27, and Android 10 and
  /// older - still common on budget phones - ship 3.22. Instead the
  /// write-ahead log is folded into the main file, the file is copied, and
  /// the copy is checked before it is trusted.
  Future<File> snapshot(String destination) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      await database.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
      final copy = await File(databasePath).copy(destination);

      if ((await inspect(copy.path)).isValid) return copy;
      // A write landed between the checkpoint and the copy; try once more.
    }
    throw const FileSystemException('backup copy failed its integrity check');
  }

  /// Makes a dated copy if the last one is old enough, keeping a week of
  /// them. Cheap enough to call on every launch.
  Future<File?> backUpIfDue({DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final last = DateTime.tryParse(preferences.readLastAutoBackup() ?? '');
    if (last != null && clock.difference(last) < automaticInterval) return null;

    final folder = await _automaticFolder();
    final stamp = clock.toIso8601String().substring(0, 10);
    final file = await snapshot(
      p.join(folder.path, 'kitaza-$stamp.$fileExtension'),
    );
    await preferences.writeLastAutoBackup(clock.toIso8601String());
    await _pruneAutomatic(folder);
    return file;
  }

  /// A copy with a friendly name, for the owner to send to themselves.
  Future<File> exportCopy({DateTime? now}) async {
    final stamp = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
    final folder = await Directory.systemTemp.createTemp('kitaza-export');
    return snapshot(p.join(folder.path, 'kitaza-backup-$stamp.$fileExtension'));
  }

  Future<List<File>> automaticCopies() async {
    final folder = await _automaticFolder();
    final files =
        folder
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.$fileExtension'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Reads a candidate backup without changing anything on the phone.
  Future<BackupInspection> inspect(String path) async {
    if (!File(path).existsSync()) {
      return const BackupInspection.invalid(BackupProblem.notABackup);
    }

    // Opened from a scratch copy, read-only: a damaged or hostile file must
    // not be able to alter the original the owner picked.
    final scratch = await File(path).copy(
      p.join(
        (await Directory.systemTemp.createTemp('kitaza-inspect')).path,
        'candidate.db',
      ),
    );

    Database? candidate;
    try {
      candidate = await _factory.openDatabase(
        scratch.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );

      final tables = (await candidate.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      )).map((row) => row['name']).toSet();
      if (!_requiredTables.every(tables.contains)) {
        return const BackupInspection.invalid(BackupProblem.wrongApp);
      }

      final version =
          (await candidate.rawQuery('PRAGMA user_version')).first.values.first
              as int;
      if (version > AppConfig.databaseVersion) {
        return const BackupInspection.invalid(BackupProblem.tooNew);
      }

      final integrity = (await candidate.rawQuery('PRAGMA integrity_check'))
          .first
          .values
          .first;
      if (integrity != 'ok') {
        return const BackupInspection.invalid(BackupProblem.damaged);
      }

      final stores = await candidate.query('stores', limit: 1);
      if (stores.isEmpty) {
        return const BackupInspection.invalid(BackupProblem.wrongApp);
      }

      Future<int> count(String sql) async =>
          (await candidate!.rawQuery(sql)).first.values.first as int? ?? 0;

      final latest =
          (await candidate.rawQuery('''
        SELECT MAX(occurred_at) AS latest FROM (
          SELECT occurred_at FROM sales WHERE deleted_at IS NULL
          UNION ALL
          SELECT occurred_at FROM expenses WHERE deleted_at IS NULL
        )
        ''')).first['latest']
              as String?;

      return BackupInspection.valid(
        storeId: stores.first['id'] as String,
        storeName: stores.first['name'] as String,
        saleCount: await count(
          'SELECT COUNT(*) FROM sales WHERE deleted_at IS NULL',
        ),
        productCount: await count(
          'SELECT COUNT(*) FROM products WHERE deleted_at IS NULL',
        ),
        lastActivity: latest == null ? null : DateTime.tryParse(latest),
      );
    } on Object {
      return const BackupInspection.invalid(BackupProblem.notABackup);
    } finally {
      await candidate?.close();
      await scratch.parent.delete(recursive: true);
    }
  }

  Future<Directory> _automaticFolder() async {
    final folder = Directory(
      p.join((await _documentsDirectory()).path, 'backups'),
    );
    if (!folder.existsSync()) await folder.create(recursive: true);
    return folder;
  }

  Future<void> _pruneAutomatic(Directory folder) async {
    final copies = await automaticCopies();
    for (final old in copies.skip(automaticCopiesKept)) {
      await old.delete();
    }
  }
}

/// Puts a backup in place of the database before the app opens it.
///
/// Runs with the database closed - on first launch, or during an app restart -
/// because swapping the file under an open connection would corrupt it.
Future<void> installBackup({
  required String backupPath,
  required String databasePath,
  required PreferencesStore preferences,
  required String storeId,
}) async {
  for (final suffix in ['', '-wal', '-shm']) {
    final existing = File('$databasePath$suffix');
    if (existing.existsSync()) await existing.delete();
  }
  await File(backupPath).copy(databasePath);

  // A restored store is an offline store until the owner chooses otherwise:
  // its records came from a file, not from an account, and whoever restores
  // it owns that copy.
  await preferences.writeStorageMode('local');
  await preferences.writeActiveStoreId(storeId);
  await preferences.writeOnboarded(true);
  await preferences.clearAllSyncCursors();
  await preferences.clearAccess();
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final local = ref.watch(localDatabaseProvider);
  return BackupService(
    database: local.db,
    databasePath: local.path,
    preferences: ref.watch(preferencesStoreProvider),
  );
});
