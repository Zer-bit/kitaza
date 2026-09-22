import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_endpoints.dart';

class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
    required String deviceTag,
  }) {
    return _client.post(
      ApiEndpoints.register,
      authenticated: false,
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'store_name': storeName,
        'device_tag': deviceTag,
      },
    );
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    required String deviceTag,
  }) {
    return _client.post(
      ApiEndpoints.login,
      authenticated: false,
      body: {'email': email, 'password': password, 'device_tag': deviceTag},
    );
  }

  Future<Map<String, dynamic>> profile() => _client.get(ApiEndpoints.profile);

  Future<void> signOut(String refreshToken) => _client.post(
    ApiEndpoints.logout,
    authenticated: false,
    body: {'refresh_token': refreshToken},
  );
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);
