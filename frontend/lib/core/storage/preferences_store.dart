import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-secret device settings. Loaded once at startup so every read is
/// synchronous and never blocks a frame.
class PreferencesStore {
  PreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _themeModeKey = 'kitaza.theme_mode';
  static const String _storageModeKey = 'kitaza.storage_mode';
  static const String _activeStoreKey = 'kitaza.active_store_id';
  static const String _onboardedKey = 'kitaza.onboarded';
  static const String _syncCursorKey = 'kitaza.sync_cursor';

  String? readThemeMode() => _preferences.getString(_themeModeKey);
  Future<void> writeThemeMode(String value) =>
      _preferences.setString(_themeModeKey, value);

  String? readStorageMode() => _preferences.getString(_storageModeKey);
  Future<void> writeStorageMode(String value) =>
      _preferences.setString(_storageModeKey, value);

  String? readActiveStoreId() => _preferences.getString(_activeStoreKey);
  Future<void> writeActiveStoreId(String value) =>
      _preferences.setString(_activeStoreKey, value);

  bool readOnboarded() => _preferences.getBool(_onboardedKey) ?? false;
  Future<void> writeOnboarded(bool value) =>
      _preferences.setBool(_onboardedKey, value);

  String? readSyncCursor() => _preferences.getString(_syncCursorKey);
  Future<void> writeSyncCursor(String value) =>
      _preferences.setString(_syncCursorKey, value);

  Future<void> clearSyncCursor() => _preferences.remove(_syncCursorKey);

  Future<void> clearSession() async {
    await _preferences.remove(_activeStoreKey);
    await _preferences.remove(_syncCursorKey);
    await _preferences.remove(_onboardedKey);
  }
}

/// Overridden during bootstrap with the loaded instance.
final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => throw UnimplementedError('PreferencesStore is provided at startup'),
);
