import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app_bootstrap.dart';
import 'app/app_restarter.dart';
import 'app/kitaza_app.dart';
import 'core/diagnostics/error_reporter.dart';
import 'core/storage/preferences_store.dart';
import 'data/local/database/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final dependencies = await loadAppDependencies();
  // Month and weekday names for both languages, loaded once up front.
  await initializeDateFormatting();

  final reporter = ErrorReporter(
    appVersion: dependencies.appVersion,
    platform: dependencies.platform,
  )..install();

  runApp(
    AppRestarter(
      initial: dependencies,
      builder: (current) {
        // Re-pointed after a restore, which replaces the database.
        reporter.attach(current.database.db);

        return ProviderScope(
          overrides: [
            localDatabaseProvider.overrideWithValue(current.database),
            preferencesStoreProvider.overrideWithValue(current.preferences),
          ],
          child: const KitazaApp(),
        );
      },
    ),
  );
}
