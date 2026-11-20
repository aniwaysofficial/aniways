import 'package:dio/dio.dart';
import 'package:aniways/core/constants.dart';
import 'package:aniways/core/logger.dart';

/// Bridges HTTP requests from the JavaScript runtime to Dart's [Dio].
///
/// Features:
/// - Full bypass of browser CORS restrictions.
/// - Custom User-Agent and arbitrary headers (Referer, Origin, Cookie, etc.).
/// - Automatic redirect following with final URL tracking.
/// - Response body returned as UTF-8 string.
class HttpBridge {
  HttpBridge({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  final Dio _dio;

  static const String defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  static Dio _createDefaultDio() {
    return Dio(
      BaseOptions(
        connectTimeout: AppConstants.networkTimeout,
        receiveTimeout: AppConstants.networkTimeout,
        sendTimeout: AppConstants.networkTimeout,
        responseType: ResponseType.plain,
        validateStatus: (status) => true, // Don't throw on 4xx/5xx; let JS handle it
        headers: {
          'User-Agent': defaultUserAgent,
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ),
    );
  }

  /// Handles incoming HTTP request arguments from the JS engine.
  ///
  /// Expected JSON shape:
  /// ```json
  /// {
  ///   "id": "req_123",
  ///   "method": "GET",
  ///   "url": "https://example.com",
  ///   "headers": { "Referer": "https://..." },
  ///   "body": "...",
  ///   "params": { "page": "1" },
  ///   "timeoutMs": 15000
  /// }
  /// ```
  Future<Map<String, dynamic>> execute(Map<String, dynamic> request) async {
    final String url = (request['url'] as String?) ?? '';
    final String method = (request['method'] as String?)?.toUpperCase() ?? 'GET';
    final rawHeaders = request['headers'] as Map?;
    final Map<String, dynamic>? params = (request['params'] as Map?)?.cast<String, dynamic>();
    final dynamic body = request['body'];
    final int? timeoutMs = (request['timeoutMs'] as num?)?.toInt();

    final Map<String, dynamic> headers = {};
    if (rawHeaders != null) {
      for (final entry in rawHeaders.entries) {
        headers[entry.key.toString()] = entry.value.toString();
      }
    }

    // Default User-Agent if not provided
    if (!headers.keys.any((k) => k.toLowerCase() == 'user-agent')) {
      headers['User-Agent'] = defaultUserAgent;
    }

    final options = Options(
      method: method,
      headers: headers,
      responseType: ResponseType.plain,
      sendTimeout: timeoutMs != null ? Duration(milliseconds: timeoutMs) : null,
      receiveTimeout: timeoutMs != null ? Duration(milliseconds: timeoutMs) : null,
    );

    try {
      final response = await _dio.request<String>(
        url,
        data: body,
        queryParameters: params,
        options: options,
      );

      final respHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        respHeaders[name] = values.join(', ');
      });

      return {
        'status': response.statusCode ?? 200,
        'statusText': response.statusMessage ?? 'OK',
        'headers': respHeaders,
        'data': response.data ?? '',
        'url': response.realUri.toString(),
      };
    } catch (e) {
      log.w('HttpBridge error for $method $url: $e');
      return {
        'error': e.toString(),
        'status': 0,
        'statusText': 'Error',
        'headers': <String, String>{},
        'data': '',
        'url': url,
      };
    }
  }
}
