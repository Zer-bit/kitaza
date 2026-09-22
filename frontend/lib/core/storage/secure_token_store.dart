import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Refresh and access tokens live in the platform keystore, never in
/// preferences. Holding a valid refresh token here is what lets a device skip
/// the sign-in screen on every launch after the first.
class SecureTokenStore {
  const SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'kitaza.access_token';
  static const String _refreshTokenKey = 'kitaza.refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

// The plugin's defaults already use the platform keystore on every target,
// so no per-platform options are needed here.
final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => const SecureTokenStore(FlutterSecureStorage()),
);
