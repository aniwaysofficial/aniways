import 'package:logger/logger.dart';

/// Clean, compact log printer for Aniways.
///
/// Avoids wrapping every single log line in ASCII box borders, delivering
/// clean single-line logs with timestamps, understated level tags, and tidy error traces.
class AniwaysLogPrinter extends LogPrinter {
  final bool colors;

  AniwaysLogPrinter({this.colors = true});

  static final Map<Level, String> _tags = {
    Level.trace: '[TRACE]',
    Level.debug: '[DEBUG]',
    Level.info: '[INFO]',
    Level.warning: '⚠️ [WARN]',
    Level.error: '❌ [ERROR]',
    Level.fatal: '💥 [FATAL]',
  };

  static final Map<Level, AnsiColor> _colors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: AnsiColor.fg(AnsiColor.grey(0.7)),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  @override
  List<String> log(LogEvent event) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final tag = _tags[event.level] ?? '[LOG]';
    final color = colors
        ? (_colors[event.level] ?? const AnsiColor.none())
        : const AnsiColor.none();

    final messageStr = event.message.toString();
    final msgLines = messageStr.split('\n');
    final lines = <String>[];

    final header = color('[$timeStr] $tag ');
    lines.add('$header${color(msgLines.first)}');
    final indent = ' ' * (timeStr.length + tag.length + 4);
    for (var i = 1; i < msgLines.length; i++) {
      lines.add(color('$indent${msgLines[i]}'));
    }

    if (event.error != null) {
      lines.add(color('   └─ Error: ${event.error}'));
    }
    if (event.stackTrace != null) {
      final stLines = event.stackTrace.toString().trim().split('\n');
      for (final l in stLines.take(6)) {
        lines.add(color('      $l'));
      }
    }

    return lines;
  }
}

/// Global logger instance.
///
/// Usage:
/// ```dart
/// import 'package:aniways/core/logger.dart';
///
/// log.d('debug message');
/// log.i('info message');
/// log.w('warning message');
/// log.e('error message', error: e, stackTrace: st);
/// ```
final log = Logger(
  filter: ProductionFilter(),
  printer: AniwaysLogPrinter(colors: true),
  // In release mode, only show warnings and above.
  level: const bool.fromEnvironment('dart.vm.product')
      ? Level.warning
      : Level.trace,
);
