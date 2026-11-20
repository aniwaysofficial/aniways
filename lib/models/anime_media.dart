import 'package:aniways/core/helpers.dart';

/// An anime as shown in lists and cards (parsed from the AniList `MediaCard`
/// fragment). Pure Dart so it stays easy to test.
class AnimeMedia {
  const AnimeMedia({
    required this.id,
    required this.romajiTitle,
    this.idMal,
    this.englishTitle,
    this.coverUrl,
    this.bannerUrl,
    this.coverColor,
    this.format,
    this.status,
    this.episodes,
    this.averageScore,
    this.popularity,
    this.genres = const [],
    this.startDate,
    this.nextAiring,
    this.isAdult = false,
  });

  final int id;
  final int? idMal;
  final String romajiTitle;
  final String? englishTitle;
  final String? coverUrl;
  final String? bannerUrl;

  /// Dominant cover colour as an ARGB int (`Color(value)`), if AniList has it.
  final int? coverColor;

  final String? format;
  final String? status;
  final int? episodes;

  /// 0–100.
  final int? averageScore;
  final int? popularity;
  final List<String> genres;
  final AnimeDate? startDate;
  final NextAiring? nextAiring;
  final bool isAdult;

  factory AnimeMedia.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as Map?) ?? const {};
    final cover = (json['coverImage'] as Map?) ?? const {};
    final english = title['english'] as String?;
    final romaji = title['romaji'] as String?;

    return AnimeMedia(
      id: json['id'] as int,
      idMal: json['idMal'] as int?,
      romajiTitle: romaji ?? english ?? 'Unknown title',
      englishTitle: english,
      coverUrl: (cover['extraLarge'] as String?) ??
          (cover['large'] as String?) ??
          (cover['medium'] as String?),
      bannerUrl: json['bannerImage'] as String?,
      coverColor: _parseHexColor(cover['color'] as String?),
      format: json['format'] as String?,
      status: json['status'] as String?,
      episodes: json['episodes'] as int?,
      averageScore: json['averageScore'] as int?,
      popularity: json['popularity'] as int?,
      genres: ((json['genres'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      startDate: AnimeDate.fromJson(json['startDate']),
      nextAiring: NextAiring.fromJson(json['nextAiringEpisode']),
      isAdult: (json['isAdult'] as bool?) ?? false,
    );
  }

  // ── Display helpers ─────────────────────────────────────────────────

  /// Preferred display title (swap the order for romaji-first).
  String get title => englishTitle ?? romajiTitle;

  /// "8.4", or null when there's no score yet.
  String? get scoreLabel {
    final score = averageScore;
    if (score == null || score == 0) return null;
    return (score / 10).toStringAsFixed(1);
  }

  String? get formatLabel => switch (format) {
    'TV' => 'TV',
    'TV_SHORT' => 'TV Short',
    'MOVIE' => 'Movie',
    'SPECIAL' => 'Special',
    'OVA' => 'OVA',
    'ONA' => 'ONA',
    'MUSIC' => 'Music',
    null => null,
    _ => format,
  };

  String? get statusLabel => switch (status) {
    'FINISHED' => 'Completed',
    'RELEASING' => 'Airing',
    'NOT_YET_RELEASED' => 'Upcoming',
    'CANCELLED' => 'Cancelled',
    'HIATUS' => 'Hiatus',
    null => null,
    _ => status,
  };

  bool get isUpcoming => status == 'NOT_YET_RELEASED';
  bool get isAiring => status == 'RELEASING';
  bool get isCompleted => status == 'FINISHED';

  String? get _episodesLabel {
    final count = episodes;
    if (count == null) return null;
    return count == 1 ? '1 ep' : '$count eps';
  }

  /// One short line under a poster: "TV · 12 eps" (or the start date for
  /// anime that haven't aired yet).
  String get cardSubtitle {
    if (isUpcoming) return startDate?.label ?? 'TBA';
    final format = formatLabel;
    final eps = _episodesLabel;
    final parts = <String>[?format, ?eps];
    if (parts.isEmpty) return statusLabel ?? '';
    return parts.join(' · ');
  }

  /// "TV · 12 eps · Finished" for list rows.
  String get tileSubtitle {
    final format = formatLabel;
    final eps = _episodesLabel;
    final state = statusLabel;
    return <String>[?format, ?eps, ?state].join(' · ');
  }
}

/// AniList "fuzzy" date: any part may be missing.
class AnimeDate {
  const AnimeDate({this.year, this.month, this.day});

  final int? year;
  final int? month;
  final int? day;

  static AnimeDate? fromJson(Object? json) {
    if (json is! Map) return null;
    final date = AnimeDate(
      year: json['year'] as int?,
      month: json['month'] as int?,
      day: json['day'] as int?,
    );
    return date.year == null && date.month == null && date.day == null
        ? null
        : date;
  }

  /// "Jan 5, 2027", "Jan 2027", "2027" or "TBA".
  String get label {
    final y = year;
    if (y == null) return 'TBA';
    final m = month;
    if (m == null || m < 1 || m > 12) return '$y';
    final name = kShortMonths[m - 1];
    return day == null ? '$name $y' : '$name $day, $y';
  }
}

/// The next episode that will air.
class NextAiring {
  const NextAiring({required this.episode, required this.airingAt});

  final int episode;

  /// Unix seconds.
  final int airingAt;

  static NextAiring? fromJson(Object? json) {
    if (json is! Map) return null;
    final episode = json['episode'] as int?;
    final airingAt = json['airingAt'] as int?;
    if (episode == null || airingAt == null) return null;
    return NextAiring(episode: episode, airingAt: airingAt);
  }

  Duration get timeUntil =>
      DateTime.fromMillisecondsSinceEpoch(airingAt * 1000)
          .difference(DateTime.now());

  /// "Ep 5 · in 2d 3h".
  String get label {
    final left = timeUntil;
    if (left.isNegative) return 'Ep $episode';
    final String when;
    if (left.inDays > 0) {
      when = '${left.inDays}d ${left.inHours.remainder(24)}h';
    } else if (left.inHours > 0) {
      when = '${left.inHours}h ${left.inMinutes.remainder(60)}m';
    } else {
      when = '${left.inMinutes.clamp(1, 59)}m';
    }
    return 'Ep $episode · in $when';
  }
}

int? _parseHexColor(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  return value == null ? null : 0xFF000000 | value;
}

/// A genre with its display name and a representative anime cover image URL.
class GenreItem {
  const GenreItem({required this.name, this.coverUrl});

  final String name;
  final String? coverUrl;

  @override
  String toString() => 'GenreItem(name: $name, coverUrl: $coverUrl)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenreItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          coverUrl == other.coverUrl;

  @override
  int get hashCode => name.hashCode ^ coverUrl.hashCode;
}

/// An airing schedule entry (one scheduled episode of an anime).
class AiringSchedule {
  const AiringSchedule({
    required this.id,
    required this.airingAt,
    required this.episode,
    required this.media,
    this.timeUntilAiring,
  });

  final int id;
  final DateTime airingAt;
  final int episode;
  final AnimeMedia media;
  final int? timeUntilAiring;

  factory AiringSchedule.fromJson(Map<String, dynamic> json) {
    return AiringSchedule(
      id: json['id'] as int,
      airingAt: DateTime.fromMillisecondsSinceEpoch(
        (json['airingAt'] as int) * 1000,
      ),
      episode: json['episode'] as int,
      media: AnimeMedia.fromJson(
        (json['media'] as Map).cast<String, dynamic>(),
      ),
      timeUntilAiring: json['timeUntilAiring'] as int?,
    );
  }

  bool get hasAired => airingAt.isBefore(DateTime.now());

  /// Formatted time e.g. "6:30 PM"
  String get timeLabel {
    final h = airingAt.hour;
    final m = airingAt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  /// Relative airing description e.g. "Aired", "in 2h 15m", "Airing now"
  String get relativeLabel {
    final diff = airingAt.difference(DateTime.now());
    if (diff.isNegative) {
      if (diff.inHours.abs() < 1) return 'Aired recently';
      return 'Aired';
    }
    if (diff.inDays > 0) {
      return 'in ${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours > 0) {
      return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes > 0) {
      return 'in ${diff.inMinutes}m';
    }
    return 'Airing now';
  }
}


