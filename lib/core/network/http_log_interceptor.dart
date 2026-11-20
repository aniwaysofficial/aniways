import 'package:dio/dio.dart';
import 'package:aniways/core/logger.dart';

/// Clean, unified HTTP logging interceptor for Dio.
///
/// Logs each network request and response as a single, readable line
class HttpLogInterceptor extends Interceptor {
  HttpLogInterceptor({this.logBody = false});

  /// Whether to print request/response payload previews.
  final bool logBody;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_reqStartMs'] = DateTime.now().millisecondsSinceEpoch;
    final method = options.method.toUpperCase();
    final uri = options.uri;

    // Detect GraphQL operation name for instant visibility in logs
    String opName = '';
    if (options.data is Map && options.data['query'] is String) {
      final query = options.data['query'] as String;
      final match = RegExp(r'(query|mutation)\s+([A-Za-z0-9_]+)')
          .firstMatch(query);
      if (match != null) {
        opName = ' [${match.group(2)}]';
      }
    }

    log.d('HTTP --> $method $uri$opName');

    if (logBody && options.data != null) {
      final dataStr = options.data.toString();
      final preview = dataStr.length > 300
          ? '${dataStr.substring(0, 300)}...'
          : dataStr;
      log.d('   └─ Body: $preview');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = response.requestOptions.extra['_reqStartMs'] as int?;
    final duration = start != null
        ? '${DateTime.now().millisecondsSinceEpoch - start}ms'
        : '';
    final code = response.statusCode ?? 200;
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri;
    final durStr = duration.isNotEmpty ? ' ($duration)' : '';

    log.d('HTTP <-- $code $method $uri$durStr');

    if (logBody && response.data != null) {
      final dataStr = response.data.toString();
      final preview = dataStr.length > 300
          ? '${dataStr.substring(0, 300)}...'
          : dataStr;
      log.d('   └─ Response: $preview');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final start = err.requestOptions.extra['_reqStartMs'] as int?;
    final duration = start != null
        ? '${DateTime.now().millisecondsSinceEpoch - start}ms'
        : '';
    final code = err.response?.statusCode ?? 'ERR';
    final method = err.requestOptions.method.toUpperCase();
    final uri = err.requestOptions.uri;
    final durStr = duration.isNotEmpty ? ' ($duration)' : '';

    log.w('HTTP <-- $code $method $uri$durStr · ${err.message ?? err.error}');
    handler.next(err);
  }
}
