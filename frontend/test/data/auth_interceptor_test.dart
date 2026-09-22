import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/errors/app_failure.dart';
import 'package:kitaza_app/core/storage/secure_token_store.dart';
import 'package:kitaza_app/data/remote/api_client.dart';
import 'package:kitaza_app/data/remote/auth_interceptor.dart';

/// A server whose every data request says the access token has expired, and
/// whose refresh endpoint behaves however the test says.
class _ExpiredTokenServer implements HttpClientAdapter {
  _ExpiredTokenServer(this.refresh);

  /// What the refresh endpoint does: a status code, or null to drop the
  /// connection.
  int? refresh;
  int dataRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/auth/refresh')) {
      final status = refresh;
      if (status == null) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'signal dropped',
        );
      }
      return _json(status, {
        if (status == 200) ...{
          'access_token': 'fresh-access',
          'refresh_token': 'fresh-refresh',
        } else
          'error': {'code': 'unauthorized', 'message': 'please sign in again'},
      });
    }

    dataRequests++;
    final authorised =
        options.headers['Authorization'] == 'Bearer fresh-access';
    return authorised
        ? _json(200, {'ok': true})
        : _json(401, {
            'error': {'code': 'unauthorized', 'message': 'expired'},
          });
  }

  static ResponseBody _json(int status, Map<String, dynamic> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  const tokens = SecureTokenStore(FlutterSecureStorage());
  late _ExpiredTokenServer server;
  late ApiClient client;
  late int sessionsLost;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await tokens.saveTokens(accessToken: 'stale', refreshToken: 'refresh');
    sessionsLost = 0;
    server = _ExpiredTokenServer(200);

    final options = BaseOptions(
      baseUrl: 'http://kitaza.test/api/v1',
      validateStatus: (status) => status != null && status < 400,
    );
    final dio = Dio(options)..httpClientAdapter = server;
    final refreshClient = Dio(options)..httpClientAdapter = server;
    dio.interceptors.add(
      AuthInterceptor(
        tokenStore: tokens,
        refreshClient: refreshClient,
        onSessionLost: () async {
          sessionsLost++;
          await tokens.clear();
        },
      ),
    );
    client = ApiClient(dio);
  });

  Future<Object?> attempt() async {
    try {
      return await client.get('/stores/s/sync/pull');
    } on AppFailure catch (failure) {
      return failure;
    }
  }

  test('an expired token is renewed and the request goes through', () async {
    expect(await attempt(), {'ok': true});
    expect(await tokens.readRefreshToken(), 'fresh-refresh');
    expect(sessionsLost, 0);
  });

  test('a refused renewal means this phone was signed out', () async {
    server.refresh = 401;

    final result = await attempt();

    expect((result! as AppFailure).kind, FailureKind.unauthorized);
    expect(sessionsLost, 1);
    expect(await tokens.readRefreshToken(), isNull);
  });

  test('losing signal while renewing keeps the phone signed in', () async {
    // Before, any failure to renew wiped the tokens, so an owner whose hour
    // was up on a weak signal was signed out for good.
    server.refresh = null;

    final result = await attempt();

    expect((result! as AppFailure).kind, FailureKind.offline);
    expect(sessionsLost, 0);
    expect(await tokens.readRefreshToken(), 'refresh');

    server.refresh = 200;
    expect(await attempt(), {'ok': true}, reason: 'works once back online');
  });

  test('a server error while renewing is not a sign-out either', () async {
    server.refresh = 503;

    final result = await attempt();

    expect((result! as AppFailure).isTransient, isTrue);
    expect(sessionsLost, 0);
  });
}
