import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:better_player/better_player.dart';

import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/extractor_service.dart';

/// Representation of an extracted subtitle cue for sorting & deduplication.
class _AssCue {
  const _AssCue(this.start, this.end, this.text, this.index);
  final String start;
  final String end;
  final String text;
  final int index;
}

/// Sanitizes cue text for WebVTT compliance:
/// - Eliminates blank lines (\n\n) that terminate WebVTT cue blocks.
/// - Escapes `-->` timing tokens and XML/HTML sensitive tokens (`&`, `<`).
String _sanitizeVttText(String text) {
  var sanitized = text.replaceAll(RegExp(r'\n\s*\n+'), '\n');
  sanitized = sanitized.replaceAll('-->', '->');
  sanitized = sanitized.replaceAllMapped(
    RegExp(r'&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[a-fA-F0-9]+);)'),
    (_) => '&amp;',
  );
  sanitized = sanitized.replaceAll('<', '&lt;');
  return sanitized.trim();
}

final _assDrawingRegex = RegExp(r'\{[^}]*\\[pP][1-9]');

/// Converts an ASS/SSA timestamp (`H:MM:SS.cs` or `MM:SS.cs`) to WebVTT (`HH:MM:SS.mmm`).
String _assTimeToVtt(String timeStr) {
  final parts = timeStr.trim().split(':');
  if (parts.length < 2) return '00:00:00.000';

  String h = '00';
  String m = '00';
  String s = '00';
  String ms = '000';

  if (parts.length >= 3) {
    h = parts[0].padLeft(2, '0');
    m = parts[1].padLeft(2, '0');
    final secParts = parts[2].split('.');
    s = secParts[0].padLeft(2, '0');
    if (secParts.length > 1) {
      ms = secParts[1].padRight(3, '0').substring(0, 3);
    }
  } else if (parts.length == 2) {
    m = parts[0].padLeft(2, '0');
    final secParts = parts[1].split('.');
    s = secParts[0].padLeft(2, '0');
    if (secParts.length > 1) {
      ms = secParts[1].padRight(3, '0').substring(0, 3);
    }
  }
  return '$h:$m:$s.$ms';
}

/// Single-pass character cleaner for ASS text:
/// - Strips override tags `{...}` (blur, pos, color, font, etc.)
/// - Converts `\N` and `\n` to standard newlines
/// - Converts `\h` to standard space
String _cleanAssText(String rawText) {
  final sb = StringBuffer();
  var insideBrace = false;

  for (var i = 0; i < rawText.length; i++) {
    final ch = rawText[i];
    if (ch == '{') {
      insideBrace = true;
    } else if (ch == '}') {
      insideBrace = false;
    } else if (!insideBrace) {
      if (ch == '\\' && i + 1 < rawText.length) {
        final next = rawText[i + 1];
        if (next == 'N' || next == 'n') {
          sb.write('\n');
          i++;
          continue;
        } else if (next == 'h') {
          sb.write(' ');
          i++;
          continue;
        }
      }
      sb.write(ch);
    }
  }
  return sb.toString().trim();
}

/// Synchronously converts raw ASS/SSA content to a clean, valid WebVTT string.
///
/// Features:
/// 1. Skips upfront metadata/styles by seeking directly to `[Events]`.
/// 2. Dynamically maps `Format:` column positions.
/// 3. Ignores vector drawing lines (`{\p1}...`).
/// 4. Deduplicates overlapping styled sign layers.
String convertAssToVtt(String content) {
  var text = content;
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }

  // Fast-skip to [Events] section to bypass megabytes of style/font data
  final lower = text.toLowerCase();
  final eventsIdx = lower.indexOf('[events]');
  if (eventsIdx == -1) return 'WEBVTT\n\n';

  final eventsSection = text.substring(eventsIdx);
  final lines = const LineSplitter().convert(eventsSection);

  int startCol = 1;
  int endCol = 2;
  int textCol = 9;

  final cues = <_AssCue>[];

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith(';')) continue;
    if (line.startsWith('[') && line.endsWith(']')) break; // Next section

    if (line.toLowerCase().startsWith('format:')) {
      final cols = line
          .substring(7)
          .split(',')
          .map((c) => c.trim().toLowerCase())
          .toList();
      startCol = cols.indexOf('start');
      endCol = cols.indexOf('end');
      textCol = cols.indexOf('text');
      continue;
    }

    if (line.toLowerCase().startsWith('dialogue:')) {
      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;
      if (startCol < 0 || endCol < 0 || textCol < 0) continue;

      final payload = line.substring(colonIdx + 1).trim();
      final maxCol = [startCol, endCol, textCol].reduce((a, b) => a > b ? a : b);
      final parts = <String>[];
      var cur = 0;
      for (var s = 0; s < maxCol; s++) {
        final nextComma = payload.indexOf(',', cur);
        if (nextComma == -1) break;
        parts.add(payload.substring(cur, nextComma));
        cur = nextComma + 1;
      }
      parts.add(payload.substring(cur));

      if (startCol >= parts.length || endCol >= parts.length || textCol >= parts.length) {
        continue;
      }

      final rawStart = parts[startCol];
      final rawEnd = parts[endCol];
      final rawText = parts[textCol];

      if (rawStart.isEmpty || rawEnd.isEmpty || rawText.isEmpty) continue;

      // Filter out vector drawing tags anywhere inside tag blocks (e.g. {\p1}, {\an8\p1})
      if (_assDrawingRegex.hasMatch(rawText)) {
        continue;
      }

      final clean = _cleanAssText(rawText);
      final sanitized = _sanitizeVttText(clean);
      if (sanitized.isEmpty) continue;

      cues.add(_AssCue(_assTimeToVtt(rawStart), _assTimeToVtt(rawEnd), sanitized, i));
    }
  }

  // Stable sort: by start timestamp with index tiebreaker
  cues.sort((a, b) {
    final cmp = a.start.compareTo(b.start);
    if (cmp != 0) return cmp;
    return a.index.compareTo(b.index);
  });

  // Build WebVTT output with complete signature deduplication
  final out = StringBuffer('WEBVTT\n\n');
  final seenSignatures = <String>{};

  for (final c in cues) {
    final sig = '${c.start}|${c.end}|${c.text}';
    if (!seenSignatures.add(sig)) {
      continue;
    }
    out.write('${c.start} --> ${c.end}\n${c.text}\n\n');
  }

  return out.toString();
}

/// Helper service that fetches subtitle files directly from CDNs, converts ASS
/// or SRT to WebVTT on-device, and caches in memory for instant playback.
class SubtitleLoader {
  SubtitleLoader._();
  static final SubtitleLoader instance = SubtitleLoader._();

  final Map<String, String> _vttCache = {};
  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  /// Clears in-memory converted subtitle cache.
  void clearCache() => _vttCache.clear();

  /// Retrieves converted WebVTT string from memory cache if available.
  String? getCached(String url) => _vttCache[url];

  /// Prepares a [PlayerSubtitlesSource] for BetterPlayer.
  ///
  /// - Downloads raw subtitle with required CDN headers directly on device.
  /// - Converts ASS/SSA to WebVTT on a background isolate if content is large.
  /// - Returns a memory-backed [PlayerSubtitlesSource] that BetterPlayer can
  ///   render without parse errors.
  Future<PlayerSubtitlesSource?> loadTrack(
    SubtitleTrack track, {
    Map<String, String>? extraHeaders,
    bool isSelected = false,
  }) async {
    final url = track.url;
    if (url.isEmpty) return null;

    try {
      // 1. Check in-memory converted cache
      var vttContent = _vttCache[url];
      if (vttContent == null) {
        // 2. Fetch raw subtitle text from CDN directly
        final headers = <String, String>{
          ...?extraHeaders,
          ...track.headers,
        };

        final uri = Uri.parse(url);
        final request = await _httpClient
            .getUrl(uri)
            .timeout(const Duration(seconds: 10));
        headers.forEach((k, v) => request.headers.set(k, v));
        final response =
            await request.close().timeout(const Duration(seconds: 10));

        if (response.statusCode < 200 || response.statusCode >= 300) {
          log.w('Failed to download subtitle from $url: HTTP ${response.statusCode}');
          return null;
        }

        final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
        final rawContent = utf8.decode(bytes, allowMalformed: true);

        // 3. Format detection and conversion
        String parsed;
        if (rawContent.trimLeft().startsWith('WEBVTT')) {
          parsed = rawContent;
        } else if (rawContent.contains('[Events]') ||
            rawContent.contains('[Script Info]') ||
            rawContent.contains('Dialogue:')) {
          // ASS/SSA format: Run on background isolate if payload is large
          if (rawContent.length > 50000) {
            parsed = await compute(convertAssToVtt, rawContent);
          } else {
            parsed = convertAssToVtt(rawContent);
          }
        } else if (RegExp(r'^\d+\r?\n\d{2}:\d{2}:\d{2}[,\.]\d{3}\s*-->', multiLine: true).hasMatch(rawContent)) {
          // Standard SRT: Convert timestamps and prepend WebVTT header
          final normalized = rawContent.replaceAllMapped(
            RegExp(r'(\d{2}:\d{2}:\d{2}),(\d{3})'),
            (m) => '${m[1]}.${m[2]}',
          );
          parsed = 'WEBVTT\n\n$normalized';
        } else {
          parsed = rawContent;
        }

        vttContent = parsed;
        // Cache for subsequent switches/episodes
        _vttCache[url] = parsed;
      }

      return PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.memory,
        name: track.label,
        urls: [url],
        content: vttContent,
        selectedByDefault: isSelected,
      );
    } catch (e) {
      log.w('SubtitleLoader error for ${track.label} ($url): $e');
      return null;
    }
  }
}
