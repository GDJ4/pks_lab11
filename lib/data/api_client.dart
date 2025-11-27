import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final Dio dio;
  ApiClient._(this.dio);

  factory ApiClient({required String baseUrl, String? bearerToken}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: {
          'Content-Type': 'application/json',
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('→ ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (resp, handler) {
          debugPrint(
            '✓ ${resp.statusCode} ${resp.requestOptions.method} ${resp.requestOptions.uri}',
          );
          handler.next(resp);
        },
        onError: (error, handler) {
          debugPrint(
            '⨯ ${error.requestOptions.method} ${error.requestOptions.uri}: ${error.message}',
          );
          handler.next(error);
        },
      ),
    );

    return ApiClient._(dio);
  }

  Future<Response<T>> withRetry<T>(
    Future<Response<T>> Function() call, {
    bool idempotent = true,
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await call();
      } on DioException catch (e) {
        final shouldRetry =
            idempotent && _isRetryable(e) && attempt < maxAttempts;
        if (!shouldRetry) rethrow;
        final delay = Duration(milliseconds: 400 * (1 << (attempt - 1)));
        await Future.delayed(delay);
      }
    }
  }

  bool _isRetryable(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.badResponse && e.response?.statusCode == 503;
  }
}
