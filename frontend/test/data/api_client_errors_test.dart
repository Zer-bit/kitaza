import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/errors/app_failure.dart';
import 'package:kitaza_app/data/remote/api_client.dart';
import 'package:kitaza_app/l10n/l10n.dart';

/// Answers every request with one scripted response.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientAnswering(int status, String code, String message) {
  final dio =
      Dio(
          BaseOptions(
            baseUrl: 'http://kitaza.test/api/v1',
            validateStatus: (status) => status != null && status < 400,
          ),
        )
        ..httpClientAdapter = _ScriptedAdapter(status, {
          'error': {'code': code, 'message': message},
        });
  return ApiClient(dio);
}

Future<AppFailure> _failureOf(Future<Object?> request) async {
  try {
    await request;
  } on AppFailure catch (failure) {
    return failure;
  }
  fail('expected the request to fail');
}

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final filipino = lookupAppLocalizations(const Locale('fil'));

  test('a wrong password says so, instead of "your session expired"', () async {
    final client = _clientAnswering(
      401,
      'unauthorized',
      'email or password is incorrect',
    );

    final failure = await _failureOf(
      client.post('/auth/login', body: {}, authenticated: false),
    );

    expect(failure.kind, FailureKind.rejected);
    expect(english.failure(failure), 'Email or password is incorrect.');
    expect(filipino.failure(failure), 'Mali ang email o password.');
  });

  test('a 401 on a signed-in request still means the session ended', () async {
    final client = _clientAnswering(401, 'unauthorized', 'expired');

    final failure = await _failureOf(client.get('/auth/me'));

    expect(failure.kind, FailureKind.unauthorized);
    expect(english.failure(failure), english.errorSessionExpired);
  });

  test('a taken email and too many attempts are explained in the owner\'s language', () async {
    final taken = await _failureOf(
      _clientAnswering(
        409,
        'conflict',
        'x',
      ).post('/auth/register', authenticated: false),
    );
    final throttled = await _failureOf(
      _clientAnswering(
        429,
        'too_many_requests',
        'x',
      ).post('/auth/login', authenticated: false),
    );

    expect(filipino.failure(taken), filipino.errorEmailTaken);
    expect(filipino.failure(throttled), filipino.errorTooManyAttempts);
  });

  test('server trouble is reported as temporary', () async {
    final failure = await _failureOf(
      _clientAnswering(503, 'internal_error', 'x').get('/stores/s/dashboard'),
    );

    expect(failure.isTransient, isTrue);
    expect(english.failure(failure), english.errorServer);
  });
}
