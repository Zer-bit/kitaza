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
  static const String _accessKey = 'kitaza.access';
  static const String _subscriptionKey = 'kitaza.subscription';
  static const String _languageKey = 'kitaza.language';
  static const String _lastAutoBackupKey = 'kitaza.last_auto_backup';
  static const String _printerAddressKey = 'kitaza.printer_address';
  static const String _printerNameKey = 'kitaza.printer_name';
  static const String _printerPaperKey = 'kitaza.printer_paper';

  String? readThemeMode() => _preferences.getString(_themeModeKey);
  Future<void> writeThemeMode(String value) =>
      _preferences.setString(_themeModeKey, value);

  String? readPrinterAddress() => _preferences.getString(_printerAddressKey);
  Future<void> writePrinterAddress(String value) =>
      _preferences.setString(_printerAddressKey, value);

  String? readPrinterName() => _preferences.getString(_printerNameKey);
  Future<void> writePrinterName(String value) =>
      _preferences.setString(_printerNameKey, value);

  String? readPrinterPaper() => _preferences.getString(_printerPaperKey);
  Future<void> writePrinterPaper(String value) =>
      _preferences.setString(_printerPaperKey, value);

  String? readLastAutoBackup() => _preferences.getString(_lastAutoBackupKey);
  Future<void> writeLastAutoBackup(String value) =>
      _preferences.setString(_lastAutoBackupKey, value);

  String? readLanguage() => _preferences.getString(_languageKey);
  Future<void> writeLanguage(String? value) => value == null
      ? _preferences.remove(_languageKey)
      : _preferences.setString(_languageKey, value);

  String? readStorageMode() => _preferences.getString(_storageModeKey);
  Future<void> writeStorageMode(String value) =>
      _preferences.setString(_storageModeKey, value);

  String? readActiveStoreId() => _preferences.getString(_activeStoreKey);
  Future<void> writeActiveStoreId(String value) =>
      _preferences.setString(_activeStoreKey, value);

  bool readOnboarded() => _preferences.getBool(_onboardedKey) ?? false;
  Future<void> writeOnboarded(bool value) =>
      _preferences.setBool(_onboardedKey, value);

  /// Where this phone is up to in one store's changes. Each store has its
  /// own, since an owner switching stores must not skip the other's rows.
  ///
  /// Phones from before stores could be switched kept a single cursor. It
  /// belonged to their only store, which is the store asked for first, so it
  /// is handed to that store the first time any store asks.
  String? readSyncCursor(String storeId) {
    final own = _preferences.getString(_cursorKeyFor(storeId));
    if (own != null) return own;

    final legacy = _preferences.getString(_syncCursorKey);
    if (legacy != null) {
      _preferences.setString(_cursorKeyFor(storeId), legacy);
      _preferences.remove(_syncCursorKey);
    }
    return legacy;
  }

  Future<void> writeSyncCursor(String storeId, String value) =>
      _preferences.setString(_cursorKeyFor(storeId), value);

  /// The next sync downloads that store in full.
  Future<void> clearSyncCursor(String storeId) =>
      _preferences.remove(_cursorKeyFor(storeId));

  Future<void> clearAllSyncCursors() async {
    await _preferences.remove(_syncCursorKey);
    for (final key in _preferences.getKeys().toList()) {
      if (key.startsWith('$_syncCursorKey.')) await _preferences.remove(key);
    }
  }

  static String _cursorKeyFor(String storeId) => '$_syncCursorKey.$storeId';

  /// Who is signed in and what they may do, as the server last described it.
  String? readAccess() => _preferences.getString(_accessKey);
  Future<void> writeAccess(String value) =>
      _preferences.setString(_accessKey, value);
  Future<void> clearAccess() => _preferences.remove(_accessKey);

  /// The owner's plan as last described, so a paused account says so even
  /// when opened without signal.
  String? readSubscription() => _preferences.getString(_subscriptionKey);
  Future<void> writeSubscription(String value) =>
      _preferences.setString(_subscriptionKey, value);

  Future<void> clearSession() async {
    await _preferences.remove(_activeStoreKey);
    await _preferences.remove(_onboardedKey);
    await _preferences.remove(_accessKey);
    await _preferences.remove(_subscriptionKey);
    await clearAllSyncCursors();
  }
}

/// Overridden during bootstrap with the loaded instance.
final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => throw UnimplementedError('PreferencesStore is provided at startup'),
);
