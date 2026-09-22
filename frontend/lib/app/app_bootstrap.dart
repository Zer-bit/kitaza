import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/preferences_store.dart';
import '../data/local/database/local_database.dart';

/// Everything that must exist before the first frame. Opening SQLite and
/// reading preferences once here means the rest of the app can treat both as
/// available synchronously, with no loading spinners on startup.
class AppDependencies {
  const AppDependencies({
    required this.database,
    required this.preferences,
    required this.appVersion,
    required this.platform,
  });

  final LocalDatabase database;
  final PreferencesStore preferences;

  /// For error reports, so a fix can be matched to the build it is in.
  final String appVersion;
  final String platform;
}

Future<AppDependencies> loadAppDependencies() async {
  final results = await Future.wait([
    LocalDatabase.open(),
    SharedPreferences.getInstance(),
    PackageInfo.fromPlatform(),
  ]);
  final package = results[2] as PackageInfo;

  return AppDependencies(
    database: results[0] as LocalDatabase,
    preferences: PreferencesStore(results[1] as SharedPreferences),
    appVersion: '${package.version}+${package.buildNumber}',
    platform: kIsWeb
        ? 'web'
        : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
  );
}
