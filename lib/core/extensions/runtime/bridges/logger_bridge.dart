import 'package:aniways/core/logger.dart';

/// Bridges JavaScript `console.log`, `console.warn`, `console.error` to Aniways's [log].
class LoggerBridge {
  const LoggerBridge();

  void logMessage(dynamic args) {
    if (args is List && args.isNotEmpty) {
      final level = args[0]?.toString().toLowerCase() ?? 'info';
      final msg = args.skip(1).map((e) => e?.toString() ?? '').join(' ');

      switch (level) {
        case 'error':
          log.e('[Extension] $msg');
          break;
        case 'warn':
        case 'warning':
          log.w('[Extension] $msg');
          break;
        case 'debug':
          log.d('[Extension] $msg');
          break;
        default:
          log.i('[Extension] $msg');
      }
    } else {
      log.d('[Extension] $args');
    }
  }
}

