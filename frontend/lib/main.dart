import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_bootstrap.dart';
import 'app/kitaza_app.dart';
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

  runApp(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(dependencies.database),
        preferencesStoreProvider.overrideWithValue(dependencies.preferences),
      ],
      child: const KitazaApp(),
    ),
  );
}
