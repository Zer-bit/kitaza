import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/storage/secure_token_store.dart';
import 'api_endpoints.dart';

/// How an attempt to renew the access token went.
sealed class _Renewal {
  const _Renewal();
}

class _Renewed extends _Renewal {
  const _Renewed(this.accessToken);
  final String accessToken;
}

/// The server said no: this phone was signed out, or its token is dead.
class _Refused extends _Renewal {
  const _Refused();
}

/// The server could not be asked. Nothing is known about the session.
class _Unreachable extends _Renewal {
  const _Unreachable();
}

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
  Future<_Renewal>? _inFlightRefresh;

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
    // A rejected sign-in is a wrong password. Trying to refresh a session
    // there would, at best, waste a request and, at worst, clear the tokens
    // of an owner who is still signed in on this device.
    final anonymous = err.requestOptions.extra['skipAuth'] == true;

    if (!isUnauthorized || alreadyRetried || anonymous) {
      return handler.next(err);
    }

    final renewal = await (_inFlightRefresh ??= _refreshAccessToken());
    _inFlightRefresh = null;

    final String token;
    switch (renewal) {
      case _Renewed(:final accessToken):
        token = accessToken;
      case _Refused():
        await onSessionLost();
        return handler.next(err);
      case _Unreachable():
        // Signal dropped between the request and the renewal. That says
        // nothing about the session, so the phone stays signed in and the
        // request fails as an offline one, to be retried later.
        return handler.next(
          DioException.connectionError(
            requestOptions: err.requestOptions,
            reason: 'could not renew the session',
          ),
        );
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

  Future<_Renewal> _refreshAccessToken() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null) return const _Refused();

    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final body = response.data;
      final access = body?['access_token'];
      if (access is! String) return const _Unreachable();

      await _tokenStore.saveTokens(
        accessToken: access,
        refreshToken: body?['refresh_token'] as String? ?? refreshToken,
      );
      return _Renewed(access);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      return status == 401 || status == 403
          ? const _Refused()
          : const _Unreachable();
    }
  }
}
