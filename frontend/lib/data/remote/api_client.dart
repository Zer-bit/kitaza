import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/storage/secure_token_store.dart';
import 'auth_interceptor.dart';

/// The single HTTP entry point. Nothing else in the app constructs a Dio.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Dio get raw => _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return response.data ?? const {};
    });
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(extra: {'skipAuth': !authenticated}),
      );
      return response.data ?? const {};
    });
  }

  /// Turns transport failures into messages an owner can act on. The raw
  /// exception is kept as `cause` for logs.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  AppFailure _translate(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const AppFailure.offline(),
      _ => switch (error.response?.statusCode) {
        401 => const AppFailure.unauthorized(),
        final int status when status >= 500 => AppFailure(
          'The Kitaza server is having trouble. Your data is safe on this device.',
          cause: error,
        ),
        _ => AppFailure(_messageFrom(error), cause: error, isRetryable: false),
      },
    };
  }

  String _messageFrom(DioException error) {
    final body = error.response?.data;
    if (body is Map && body['error'] is Map) {
      final message = (body['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Something went wrong. Please try again.';
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final options = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.requestTimeout,
    receiveTimeout: AppConfig.requestTimeout,
    sendTimeout: AppConfig.requestTimeout,
    contentType: 'application/json',
    // Errors are classified by the client, not thrown by status code alone.
    validateStatus: (status) => status != null && status < 400,
  );

  final dio = Dio(options);
  final refreshClient = Dio(options);

  dio.interceptors.add(
    AuthInterceptor(
      tokenStore: ref.read(secureTokenStoreProvider),
      refreshClient: refreshClient,
      onSessionLost: () => ref.read(secureTokenStoreProvider).clear(),
    ),
  );

  return ApiClient(dio);
});
