import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/legal_document.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// How a phone describes itself when it signs in.
typedef DeviceLabel = ({String tag, String name});

class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
    required DeviceLabel device,
  }) {
    return _client.post(
      ApiEndpoints.register,
      authenticated: false,
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'store_name': storeName,
        'device_tag': device.tag,
        'device_name': device.name,
        // The server refuses to make an account without these, so a screen
        // that forgot to ask gets an error rather than silent consent.
        'accepted_privacy_version': LegalDocument.privacyNotice.currentVersion,
        'accepted_terms_version': LegalDocument.terms.currentVersion,
      },
    );
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    required DeviceLabel device,
  }) {
    return _client.post(
      ApiEndpoints.login,
      authenticated: false,
      body: {
        'email': email,
        'password': password,
        'device_tag': device.tag,
        'device_name': device.name,
      },
    );
  }

  /// A staff member's phone joining with the code the owner shared.
  Future<Map<String, dynamic>> join({
    required String code,
    required DeviceLabel device,
  }) {
    return _client.post(
      ApiEndpoints.join,
      authenticated: false,
      body: {
        'code': code,
        'device_tag': device.tag,
        'device_name': device.name,
      },
    );
  }

  /// Who this phone is signed in as now: stores, and what it may do.
  Future<Map<String, dynamic>> account() => _client.get(ApiEndpoints.profile);

  Future<void> signOut(String refreshToken) => _client.post(
    ApiEndpoints.logout,
    authenticated: false,
    body: {'refresh_token': refreshToken},
  );
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);
