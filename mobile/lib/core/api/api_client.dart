import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          await TokenStorage.clearToken();
          return handler.next(error);
        }

        // Automatic retry once for connection timeouts / transient socket drops (GET only)
        final isTimeoutOrNetworkError = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError;

        final isGetRequest = error.requestOptions.method.toUpperCase() == 'GET';
        final hasAlreadyRetried = error.requestOptions.extra['has_retried'] == true;

        if (isTimeoutOrNetworkError && isGetRequest && !hasAlreadyRetried) {
          try {
            final opts = error.requestOptions;
            opts.extra['has_retried'] = true;
            final response = await dio.fetch(opts);
            return handler.resolve(response);
          } catch (_) {
            // Fall through to standard error handler
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
});
