import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/storage/secure_token_store.dart';
import 'api_endpoints.dart';

/// Attaches the access token and, when it has expired, silently exchanges the
/// refresh token for a new one and replays the request. This is what keeps a
/// signed-in device from ever seeing the login screen again.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokenStore,
    required this._refreshClient,
    required this.onSessionLost,
  });

  final SecureTokenStore _tokenStore;
  final Dio _refreshClient;
  final Future<void> Function() onSessionLost;

  /// Concurrent 401s share one refresh instead of each starting their own.
  Future<String?>? _inFlightRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await _tokenStore.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isUnauthorized || alreadyRetried) {
      return handler.next(err);
    }

    final token = await (_inFlightRefresh ??= _refreshAccessToken());
    _inFlightRefresh = null;

    if (token == null) {
      await onSessionLost();
      return handler.next(err);
    }

    final options = err.requestOptions
      ..extra['retried'] = true
      ..headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _refreshClient.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final body = response.data;
      if (body == null) return null;

      final access = body['access_token'] as String;
      await _tokenStore.saveTokens(
        accessToken: access,
        refreshToken: body['refresh_token'] as String? ?? refreshToken,
      );
      return access;
    } on DioException {
      return null;
    }
  }
}
