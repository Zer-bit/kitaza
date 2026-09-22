import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaza_app/core/storage/preferences_store.dart';
import 'package:kitaza_app/core/theme/app_theme.dart';
import 'package:kitaza_app/data/remote/sync_api.dart';
import 'package:kitaza_app/data/repositories/store_scope.dart';
import 'package:kitaza_app/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'in_memory_database.dart';
import 'localized.dart';

/// A phone for widget tests: a signed-in offline store with a real SQLite
/// database, real providers and real navigation.
class TestPhone {
  TestPhone._(this.db, this.router, this.tester);

  final Database db;
  final GoRouter router;
  final WidgetTester tester;

  /// The live providers, for tests that need to read or seed app state.
  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  /// Where a screen lands when it pops itself.
  static const String home = '/test-home';

  /// Small, common Android phone. Layout problems show up here first.
  static const Size smallPhone = Size(360, 640);

  static Future<TestPhone> open(
    WidgetTester tester, {
    required Map<String, WidgetBuilder> screens,
    Locale locale = const Locale('en'),
    Size size = smallPhone,
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
    List<Override> Function(Database db, PreferencesStore preferences)?
    overrides,
  }) async {
    final db = await openTestDatabase(sameIsolate: true);
    await db.insert('owners', {'id': 'owner', 'full_name': 'Nena Reyes'});

    SharedPreferences.setMockInitialValues({
      'kitaza.storage_mode': 'local',
      'kitaza.active_store_id': testStoreId,
      'kitaza.onboarded': true,
    });
    final preferences = PreferencesStore(await SharedPreferences.getInstance());

    final router = GoRouter(
      initialLocation: home,
      routes: [
        GoRoute(
          path: home,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        for (final entry in screens.entries)
          GoRoute(
            path: entry.key,
            builder: (context, _) => entry.value(context),
          ),
      ],
    );

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          preferencesStoreProvider.overrideWithValue(preferences),
          connectivityChangesProvider.overrideWithValue(const Stream.empty()),
          syncApiProvider.overrideWith(
            (ref) => throw StateError('an offline phone must not sync'),
          ),
          ...?overrides?.call(db, preferences),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: localizationDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    addTearDown(db.close);
    return TestPhone._(db, router, tester);
  }

  Future<void> goTo(WidgetTester tester, String path) async {
    router.push(path);
    await settle(tester);
  }

  /// Scrolls [target] fully into view, then taps it, the way an owner would
  /// reach something below the fold.
  Future<void> tapAfterScrolling(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// Lets database reads and animations finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// Whether the home placeholder is the screen on top. Checked by what is
  /// visible rather than by router state: go_router reports a pushed screen
  /// under the location it was pushed from.
  bool get isHome => find.text('home').evaluate().isNotEmpty;
}
