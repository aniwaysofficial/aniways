import 'package:dio/dio.dart';
import 'package:aniways/core/constants.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/http_log_interceptor.dart';
import 'package:aniways/core/storage/session_manager.dart';

/// Pre-configured [Dio] instance for all API communication.
///
/// Features:
/// - Base URL from [AppConstants]
/// - Automatic request/response logging in debug mode
/// - Auth token injection via interceptor
/// - Configurable timeouts
///
/// Usage:
/// ```dart
/// final response = await apiClient.get('/anime/popular');
/// ```
final Dio apiClient = _createClient();

Dio _createClient() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: AppConstants.networkTimeout,
      receiveTimeout: AppConstants.networkTimeout,
      sendTimeout: AppConstants.networkTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ── Auth interceptor ────────────────────────────────────────────────
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SessionManager.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        log.e(
          'API Error [${error.response?.statusCode}] ${error.requestOptions.uri}',
          error: error.message,
        );
        handler.next(error);
      },
    ),
  );

  // ── Logging interceptor (debug only) ────────────────────────────────
  assert(() {
    dio.interceptors.add(HttpLogInterceptor());
    return true;
  }());

  return dio;
}
