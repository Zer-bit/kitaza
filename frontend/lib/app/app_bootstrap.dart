import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/preferences_store.dart';
import '../data/local/database/local_database.dart';

/// Everything that must exist before the first frame. Opening SQLite and
/// reading preferences once here means the rest of the app can treat both as
/// available synchronously, with no loading spinners on startup.
class AppDependencies {
  const AppDependencies({required this.database, required this.preferences});

  final LocalDatabase database;
  final PreferencesStore preferences;
}

Future<AppDependencies> loadAppDependencies() async {
  final results = await Future.wait([
    LocalDatabase.open(),
    SharedPreferences.getInstance(),
  ]);

  return AppDependencies(
    database: results[0] as LocalDatabase,
    preferences: PreferencesStore(results[1] as SharedPreferences),
  );
}
