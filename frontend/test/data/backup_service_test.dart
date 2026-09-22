import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/storage/preferences_store.dart';
import 'package:kitaza_app/data/local/backup/backup_inspection.dart';
import 'package:kitaza_app/data/local/backup/backup_service.dart';
import 'package:kitaza_app/data/local/database/local_database.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _storeId = 'store-under-test';

/// A store database on disk, opened the way the app opens it (WAL mode).
class _Device {
  _Device(this.folder, this.db, this.preferences);

  final Directory folder;
  final Database db;
  final PreferencesStore preferences;

  String get path => p.join(folder.path, 'kitaza.db');

  static Future<_Device> create() async {
    sqfliteFfiInit();
    final folder = await Directory.systemTemp.createTemp('kitaza-device');
    final db = await databaseFactoryFfi.openDatabase(
      p.join(folder.path, 'kitaza.db'),
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onConfigure: (db) => db.rawQuery('PRAGMA journal_mode = WAL'),
        onCreate: (db, _) => LocalDatabase.applySchema(db),
      ),
    );
    await db.insert('stores', {'id': _storeId, 'name': 'Aling Nena Store'});
    await db.insert('owners', {'id': 'owner', 'full_name': 'Nena Reyes'});

    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesStore(await SharedPreferences.getInstance());
    return _Device(folder, db, preferences);
  }

  BackupService backups() => BackupService(
    database: db,
    databasePath: path,
    preferences: preferences,
    documentsDirectory: () async => folder,
    factory: databaseFactoryFfi,
  );

  Future<void> sell(double amount) => SaleRepository(
    db: db,
    storeId: _storeId,
  ).record(cart: [CartLine.quick(amount)]);

  Future<void> dispose() async {
    await db.close();
    await folder.delete(recursive: true);
  }
}

void main() {
  late _Device device;

  setUp(() async => device = await _Device.create());
  tearDown(() => device.dispose());

  group('a backup copy', () {
    test('contains the store and its records', () async {
      await ProductRepository(db: device.db, storeId: _storeId).save(
        name: 'Coke',
        costPrice: 15,
        sellingPrice: 20,
        stockQuantity: 10,
        reorderLevel: 2,
      );
      await device.sell(20);
      await device.sell(45);

      final copy = await device.backups().exportCopy();
      final inside = await device.backups().inspect(copy.path);

      expect(inside.isValid, isTrue);
      expect(inside.storeName, 'Aling Nena Store');
      expect(inside.saleCount, 2);
      expect(inside.productCount, 1);
      expect(inside.lastActivity, isNotNull);
    });

    test(
      'includes the very last sale, even one still in the write-ahead log',
      () async {
        await device.sell(10);
        // Written a moment before the backup, so it sits in the WAL file and
        // not yet in the main database file a naive copy would take.
        await device.sell(99);

        final copy = await device.backups().exportCopy();

        expect((await device.backups().inspect(copy.path)).saleCount, 2);
      },
    );
  });

  group('automatic copies', () {
    test('are made at most once a day', () async {
      final backups = device.backups();
      final day = DateTime(2026, 9, 22, 8);

      expect(await backups.backUpIfDue(now: day), isNotNull);
      expect(
        await backups.backUpIfDue(now: day.add(const Duration(hours: 5))),
        isNull,
      );
      expect(
        await backups.backUpIfDue(now: day.add(const Duration(hours: 21))),
        isNotNull,
      );
    });

    test('keep one week of history', () async {
      final backups = device.backups();
      for (var day = 1; day <= 10; day++) {
        await backups.backUpIfDue(now: DateTime(2026, 9, day, 9));
      }

      final kept = await backups.automaticCopies();
      expect(kept, hasLength(BackupService.automaticCopiesKept));
      expect(p.basename(kept.first.path), 'kitaza-2026-09-10.kitaza');
      expect(p.basename(kept.last.path), 'kitaza-2026-09-04.kitaza');
    });
  });

  group('refusing a bad file', () {
    Future<BackupInspection> inspectFile(
      String name,
      Future<void> Function(String path) write,
    ) async {
      final path = p.join(device.folder.path, name);
      await write(path);
      return device.backups().inspect(path);
    }

    test('a photo or text file is not a backup', () async {
      final result = await inspectFile(
        'receipt.jpg',
        (path) => File(path).writeAsString('not a database'),
      );
      expect(result.problem, BackupProblem.notABackup);
    });

    test('another app\'s database is not a Kitaza backup', () async {
      final result = await inspectFile('other.db', (path) async {
        final other = await databaseFactoryFfi.openDatabase(path);
        await other.execute(
          'CREATE TABLE contacts (id INTEGER PRIMARY KEY, name TEXT)',
        );
        await other.close();
      });
      expect(result.problem, BackupProblem.wrongApp);
    });

    test(
      'a backup from a newer app version is refused, not half-read',
      () async {
        final copy = await device.backups().exportCopy();
        final newer = await databaseFactoryFfi.openDatabase(
          copy.path,
          options: OpenDatabaseOptions(singleInstance: false),
        );
        await newer.execute('PRAGMA user_version = 99');
        await newer.close();

        expect(
          (await device.backups().inspect(copy.path)).problem,
          BackupProblem.tooNew,
        );
      },
    );

    test('a truncated file is refused', () async {
      final copy = await device.backups().exportCopy();
      final bytes = await copy.readAsBytes();
      await copy.writeAsBytes(bytes.sublist(0, bytes.length ~/ 3));

      final result = await device.backups().inspect(copy.path);
      expect(result.isValid, isFalse);
    });

    test('inspecting never modifies the file the owner picked', () async {
      final copy = await device.backups().exportCopy();
      final before = await copy.readAsBytes();

      await device.backups().inspect(copy.path);

      expect(await copy.readAsBytes(), before);
    });
  });

  test('a lost phone is brought back from its backup file', () async {
    await device.sell(120);
    await device.sell(35.5);
    final backup = await device.backups().exportCopy();

    // A brand-new phone: nothing but an empty app folder.
    final newPhone = await Directory.systemTemp.createTemp('kitaza-new-phone');
    addTearDown(() => newPhone.delete(recursive: true));
    final newDatabase = p.join(newPhone.path, 'kitaza.db');
    SharedPreferences.setMockInitialValues({});
    final newPreferences = PreferencesStore(
      await SharedPreferences.getInstance(),
    );

    await installBackup(
      backupPath: backup.path,
      databasePath: newDatabase,
      preferences: newPreferences,
      storeId: _storeId,
    );

    final restored = await databaseFactoryFfi.openDatabase(
      newDatabase,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(restored.close);
    final totals = await restored.rawQuery(
      'SELECT COUNT(*) AS n, SUM(total_amount) AS total FROM sales',
    );

    expect(totals.first['n'], 2);
    expect(totals.first['total'], 12000 + 3550);
    expect(newPreferences.readActiveStoreId(), _storeId);
    expect(newPreferences.readStorageMode(), 'local');
    expect(newPreferences.readOnboarded(), isTrue);
  });
}
