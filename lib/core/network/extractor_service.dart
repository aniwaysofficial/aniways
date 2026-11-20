import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/logger.dart';

// ═════════════════════════════════════════════════════════════════════════
// Enums
// ═════════════════════════════════════════════════════════════════════════

enum StreamAudio { sub, dub }

enum StreamType { hls, mp4, dash, embed }

// ═════════════════════════════════════════════════════════════════════════
// Models
// ═════════════════════════════════════════════════════════════════════════

class ProviderInfo {
  const ProviderInfo({
    required this.id,
    required this.audio,
    this.status = 'online',
    this.latencyMs,
    this.name,
    this.iconUrl,
  });

  final String id;
  final List<StreamAudio> audio;
  final String status;
  final int? latencyMs;
  final String? name;
  final String? iconUrl;

  bool get isOnline => status == 'online';
  bool supports(StreamAudio a) => audio.contains(a);

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    return switch (id.toLowerCase()) {
      'aniwaves' => 'Aniwaves',
      'gogoanime' => 'Gogoanime',
      'animeonsen' => 'AnimeOnsen',
      'anikoto' => 'Anikoto',
      'anizone' => 'AniZone',
      'anipm' => 'AniPM',
      'animegg' => 'AnimeGG',
      _ => id.isEmpty ? id : id[0].toUpperCase() + id.substring(1),
    };
  }

  factory ProviderInfo.fromJson(Map<String, dynamic> json) => ProviderInfo(
    id: (json['id'] as String?) ?? '',
    name: json['name'] as String?,
    iconUrl: json['iconUrl'] as String? ?? json['icon'] as String?,
    audio: ((json['audio'] as List?) ?? [])
        .map(
          (a) => a.toString().toLowerCase() == 'dub'
              ? StreamAudio.dub
              : StreamAudio.sub,
        )
        .toList(),
    status: (json['status'] as String?) ?? 'online',
    latencyMs: (json['latencyMs'] as num?)?.toInt(),
  );
}

class EpisodeItem {
  const EpisodeItem({
    required this.id,
    required this.number,
    required this.title,
    required this.audio,
    this.filler = false,
    this.recap = false,
    this.duration,
    this.airDate,
    this.image,
    this.description,
  });

  /// Full watch path, e.g. `"watch/aniwaves/151807/sub/1"`.
  /// Used directly as `GET /$id` on the extractor.
  final String id;
  final int number;
  final String title;
  final StreamAudio audio;
  final bool filler;
  final bool recap;

  /// Duration in seconds.
  final int? duration;
  final String? airDate;
  final String? image;
  final String? description;

  factory EpisodeItem.fromJson(Map<String, dynamic> json, StreamAudio audio) {
    final numVal = (json['number'] as num?)?.toInt() ?? 0;
    return EpisodeItem(
      id: (json['id'] as String?) ?? '',
      number: numVal,
      title: (json['title'] as String?) ?? 'Episode $numVal',
      audio: audio,
      filler: (json['filler'] as bool?) ?? false,
      recap: (json['recap'] as bool?) ?? false,
      duration: (json['duration'] as num?)?.toInt(),
      airDate: json['airDate'] as String?,
      image: json['image'] as String?,
      description: json['description'] as String?,
    );
  }
}

class ProviderEpisodes {
  const ProviderEpisodes({
    required this.providerId,
    required this.providerTitle,
    required this.matchScore,
    required this.sub,
    required this.dub,
  });

  final String providerId;
  final String providerTitle;
  final double matchScore;
  final List<EpisodeItem> sub;
  final List<EpisodeItem> dub;

  bool get hasDub => dub.isNotEmpty;
  bool get hasSub => sub.isNotEmpty;

  List<EpisodeItem> forAudio(StreamAudio audio) =>
      audio == StreamAudio.sub ? sub : dub;
}

class SubtitleTrack {
  const SubtitleTrack({
    required this.url,
    required this.label,
    required this.srclang,
    this.isDefault = false,
    this.headers = const {},
  });

  final String url;
  final String label;
  final String srclang;
  final bool isDefault;
  final Map<String, String> headers;

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) => SubtitleTrack(
    url: json['url'] as String,
    label: (json['label'] as String?) ?? 'Unknown',
    srclang: (json['srclang'] as String?) ?? 'en',
    isDefault: (json['default'] as bool?) ?? false,
    headers: _parseHeaders(json['headers']),
  );
}

class TimeRange {
  const TimeRange({required this.start, required this.end});

  /// Seconds from the start of the video.
  final int start;
  final int end;

  static TimeRange? fromJson(Object? json) {
    if (json is! Map) return null;
    final s = json['start'];
    final e = json['end'];
    if (s is! num || e is! num) return null;
    final start = s.toInt();
    final end = e.toInt();
    if (start < 0 || end <= start) return null;
    return TimeRange(start: start, end: end);
  }
}

class StreamSource {
  const StreamSource({
    required this.url,
    required this.type,
    required this.server,
    this.quality,
    this.headers = const {},
    this.subtitles = const [],
    this.isActive = false,
  });

  final String url;
  final StreamType type;
  final String server;
  final String? quality;
  final Map<String, String> headers;
  final List<SubtitleTrack> subtitles;
  final bool isActive;

  /// media_kit can play hls / mp4 / dash but not embed (iframe).
  bool get isPlayable => type != StreamType.embed;

  /// Label shown in the source picker.
  String get label {
    final q = quality;
    final hasQ = q != null && q.isNotEmpty && q != 'default';
    return hasQ ? '$server · $q' : '$server · ${type.name.toUpperCase()}';
  }

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String? ?? 'hls').toLowerCase();
    final type = switch (typeStr) {
      'mp4' => StreamType.mp4,
      'dash' => StreamType.dash,
      'embed' => StreamType.embed,
      _ => StreamType.hls,
    };

    final headers = _parseHeaders(json['headers']);
    final referer = json['referer'] as String?;
    if (referer != null && !headers.containsKey('Referer')) {
      headers['Referer'] = referer;
    }

    final subtitles = <SubtitleTrack>[];
    final rawSubs = json['subtitles'];
    if (rawSubs is List) {
      for (final s in rawSubs) {
        if (s is Map) {
          subtitles.add(SubtitleTrack.fromJson(s.cast<String, dynamic>()));
        }
      }
    }

    return StreamSource(
      url: json['url'] as String,
      type: type,
      server: (json['server'] as String?) ?? 'Unknown',
      quality: json['quality'] as String?,
      headers: headers,
      subtitles: subtitles,
      isActive: (json['isActive'] as bool?) ?? false,
    );
  }
}

class WatchResult {
  const WatchResult({
    required this.anilistId,
    required this.episode,
    required this.audio,
    required this.provider,
    required this.streams,
    this.intro,
    this.outro,
  });

  final int anilistId;
  final int episode;
  final StreamAudio audio;
  final String provider;
  final TimeRange? intro;
  final TimeRange? outro;

  /// All streams returned by the API (best first).
  final List<StreamSource> streams;

  /// Only streams that media_kit can play (no embed).
  List<StreamSource> get playableStreams =>
      streams.where((s) => s.isPlayable).toList();

  /// Default stream (first active stream or first stream in list).
  StreamSource? get defaultStream =>
      streams.isNotEmpty ? (streams.where((s) => s.isActive).firstOrNull ?? streams.first) : null;
}

// ═════════════════════════════════════════════════════════════════════════
// Helpers
// ═════════════════════════════════════════════════════════════════════════

Map<String, String> _parseHeaders(Object? raw) {
  final out = <String, String>{};
  if (raw is! Map) return out;
  for (final e in raw.entries) {
    if (e.key is String && e.value is String) {
      out[e.key as String] = e.value as String;
    }
  }
  return out;
}

// ═════════════════════════════════════════════════════════════════════════
// Service
// ═════════════════════════════════════════════════════════════════════════

/// Shared singleton - use [extractorService] everywhere.
final ExtractorService extractorService = ExtractorService._();

/// Core client for streaming anime episodes and video sources.
///
/// Fully powered by decentralized client-side extensions via [ExtensionManager].
class ExtractorService {
  ExtractorService._();

  // ── Providers ────────────────────────────────────────────────────────

  /// All active streaming providers registered in local extensions.
  Future<List<ProviderInfo>> providers() async {
    try {
      return await extensionManager.getAvailableProviders();
    } catch (e) {
      log.w('ExtractorService: getAvailableProviders failed: $e');
      return const [];
    }
  }

  // ── Episodes ─────────────────────────────────────────────────────────

  /// Episodes for [anilistId] from [providerId] via local client extension.
  Future<ProviderEpisodes?> episodes(int anilistId, String providerId) async {
    try {
      return await extensionManager.getEpisodes(anilistId, providerId);
    } catch (e) {
      log.w('ExtractorService: extensionManager.getEpisodes [$providerId] failed: $e');
      return null;
    }
  }

  // ── Streams / Watch ──────────────────────────────────────────────────

  /// Video stream sources for [ep].
  ///
  /// Dispatches directly to the local extension runtime via [ExtensionManager].
  Future<WatchResult> watch(EpisodeItem ep) async {
    return await extensionManager.watch('', 0, ep);
  }

  /// Convenience helper to resolve the default or requested [server] stream.
  Future<StreamSource> source(EpisodeItem ep, {String? server}) async {
    final res = await watch(ep);
    if (res.streams.isEmpty) {
      throw StateError('No streams returned for ${ep.id}');
    }
    if (server != null) {
      final match = res.streams.firstWhere(
        (s) => s.server.toLowerCase() == server.toLowerCase(),
        orElse: () => res.streams.first,
      );
      return match;
    }
    return res.defaultStream ?? res.streams.first;
  }
}
