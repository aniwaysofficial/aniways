import 'dart:io' show Platform;

// ═══════════════════════════════════════════════════════════════════════
// PLATFORM HELPERS
// ═══════════════════════════════════════════════════════════════════════

/// Whether the app is running on a desktop platform (Windows, Linux, macOS).
bool isDesktop() =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Whether the app is running on Android.
bool isAndroid() => Platform.isAndroid;

/// Whether the app is running on iOS.
bool isIOS() => Platform.isIOS;

/// Whether the app is running on a mobile platform (Android or iOS).
bool isMobile() => Platform.isAndroid || Platform.isIOS;

// ═══════════════════════════════════════════════════════════════════════
// DURATION & TIME FORMATTERS
// ═══════════════════════════════════════════════════════════════════════

/// Formats a [Duration] into `mm:ss` or `h:mm:ss`.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Formats duration in seconds into `mm:ss` or `h:mm:ss`, returning an empty string if null or non-positive.
String formatDurationSeconds(int? seconds) {
  if (seconds == null || seconds <= 0) return '';
  return formatDuration(Duration(seconds: seconds));
}

// ═══════════════════════════════════════════════════════════════════════
// DATE & CALENDAR FORMATTERS
// ═══════════════════════════════════════════════════════════════════════

/// Standard 3-letter month abbreviations.
const List<String> kShortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a date as `D Mon YYYY` (e.g. `15 Nov 2026`).
String formatShortDate(DateTime dt) {
  final m = (dt.month >= 1 && dt.month <= 12) ? kShortMonths[dt.month - 1] : '';
  return '${dt.day} $m ${dt.year}';
}

/// Formats a date and time as `D Mon YYYY, HH:MM` (e.g. `15 Nov 2026, 12:45`).
String formatShortDateTime(DateTime dt) {
  final time =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  return '${formatShortDate(dt)}, $time';
}

// ═════════════════════════════════════════════════════════════════════════
// NUMBER FORMATTERS
// ═════════════════════════════════════════════════════════════════════════

/// Formats a large number into compact notation: `1.2M`, `450K`, etc.
String formatCompactNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 100000 ? 0 : 1)}K';
  return '$n';
}

