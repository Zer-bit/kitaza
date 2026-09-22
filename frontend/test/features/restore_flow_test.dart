import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/local/backup/backup_service.dart';
import 'package:kitaza_app/data/local/database/local_database.dart';
import 'package:kitaza_app/features/authentication/welcome_screen.dart';
import 'package:kitaza_app/features/backup/backup_platform.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_harness.dart';

/// The owner "picks" whatever file the test hands over.
class _PicksFile extends BackupPlatform {
  const _PicksFile(this.path);
  final String? path;

  @override
  Future<String?> pickBackupFile() async => path;
}

/// A genuine backup file made from a store with a few sales.
Future<String> _backupWithSales(Directory folder, int sales) async {
  final path = p.join(folder.path, 'nena.kitaza');
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) => LocalDatabase.applySchema(db),
    ),
  );
  await db.insert('stores', {'id': 'nena', 'name': 'Aling Nena Store'});
  for (var i = 0; i < sales; i++) {
    await db.insert('sales', {
      'id': 'sale-$i',
      'store_id': 'nena',
      'total_amount': 1000,
      'occurred_at': DateTime.utc(2026, 9, 20, 9).toIso8601String(),
      'updated_at': DateTime.utc(2026, 9, 20, 9).toIso8601String(),
    });
  }
  await db.close();
  return path;
}

void main() {
  late Directory folder;

  setUp(() async {
    sqfliteFfiInit();
    folder = await Directory.systemTemp.createTemp('kitaza-restore');
  });
  tearDown(() => folder.delete(recursive: true));

  Future<TestPhone> openWelcome(WidgetTester tester, String? picked) {
    return TestPhone.open(
      tester,
      screens: {RoutePaths.welcome: (_) => const WelcomeScreen()},
      overrides: (db, preferences) => [
        backupPlatformProvider.overrideWithValue(_PicksFile(picked)),
        backupServiceProvider.overrideWithValue(
          BackupService(
            database: db,
            databasePath: p.join(folder.path, 'unused.db'),
            preferences: preferences,
            factory: databaseFactoryFfiNoIsolate,
          ),
        ),
      ],
    );
  }

  /// File work happens on the real clock, but each step's continuation runs
  /// on the test's simulated one, so the two are advanced in turns until the
  /// chain of copies and queries has finished.
  Future<void> letFilesSettle(WidgetTester tester) async {
    for (var round = 0; round < 40; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('a backup shows what it holds before anything is replaced', (
    tester,
  ) async {
    final backup = await tester.runAsync(() => _backupWithSales(folder, 3));
    final phone = await openWelcome(tester, backup);
    await phone.goTo(tester, RoutePaths.welcome);

    await tester.ensureVisible(find.text('Restore from a backup file'));
    await tester.tap(find.text('Restore from a backup file'));
    await letFilesSettle(tester);

    expect(find.text('Restore this backup?'), findsOneWidget);
    expect(
      find.textContaining('Aling Nena Store: 3 sales and 0 products.'),
      findsOneWidget,
    );
    expect(find.textContaining('will be replaced'), findsOneWidget);

    // Backing out leaves the phone exactly as it was.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Restore this backup?'), findsNothing);
    expect(await phone.db.query('sales'), isEmpty);
  });

  testWidgets(
    'a file that is not a backup is refused with a plain explanation',
    (tester) async {
      final photo = p.join(folder.path, 'photo.jpg');
      await tester.runAsync(
        () => File(photo).writeAsString('definitely not a database'),
      );
      final phone = await openWelcome(tester, photo);
      await phone.goTo(tester, RoutePaths.welcome);

      await tester.ensureVisible(find.text('Restore from a backup file'));
      await tester.tap(find.text('Restore from a backup file'));
      await letFilesSettle(tester);

      expect(find.text('That file is not a Kitaza backup.'), findsOneWidget);
      expect(find.text('Restore this backup?'), findsNothing);
    },
  );

  testWidgets('cancelling the file picker does nothing', (tester) async {
    final phone = await openWelcome(tester, null);
    await phone.goTo(tester, RoutePaths.welcome);

    await tester.ensureVisible(find.text('Restore from a backup file'));
    await tester.tap(find.text('Restore from a backup file'));
    await letFilesSettle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
}
