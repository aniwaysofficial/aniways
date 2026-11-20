import 'package:aniways/models/anime_media.dart';

/// Everything the details screen needs, parsed from the raw `Media` map
/// returned by `anilistService.details(id)`. Pure Dart.
class AnimeDetails {
  const AnimeDetails({
    required this.media,
    this.nativeTitle,
    this.synonyms = const [],
    this.description,
    this.duration,
    this.season,
    this.seasonYear,
    this.endDate,
    this.favourites,
    this.tags = const [],
    this.studios = const [],
    this.trailer,
    this.characters = const [],
    this.relations = const [],
    this.recommendations = const [],
    this.externalLinks = const [],
  });

  /// The same card-level data the lists use (title, cover, banner, genres,
  /// score, next airing...). Lets the screen reuse all [AnimeMedia] labels.
  final AnimeMedia media;
  final String? nativeTitle;
  final List<String> synonyms;

  /// Plain text (HTML tags stripped).
  final String? description;

  /// Minutes per episode.
  final int? duration;
  final String? season;
  final int? seasonYear;
  final AnimeDate? endDate;
  final int? favourites;
  final List<AnimeTag> tags;
  final List<String> studios;
  final AnimeTrailer? trailer;
  final List<AnimeCharacter> characters;
  final List<AnimeRelation> relations;
  final List<AnimeRecommendation> recommendations;
  final List<AnimeExternalLink> externalLinks;

  List<AnimeExternalLink> get streamingLinks =>
      externalLinks.where((l) => l.isStreaming).toList(growable: false);

  factory AnimeDetails.fromJson(Map<String, dynamic> json) {
    final title = _asMap(json['title']);

    final tags = <AnimeTag>[
      for (final t in (json['tags'] as List?) ?? const [])
        if (t is Map && t['name'] is String)
          AnimeTag(name: t['name'] as String, rank: (t['rank'] as int?) ?? 0),
    ]..sort((a, b) => b.rank.compareTo(a.rank));

    final studios = <String>[
      for (final s
          in (_asMap(json['studios'])?['nodes'] as List?) ?? const [])
        if (s is Map && s['name'] is String) s['name'] as String,
    ];

    final characters = <AnimeCharacter>[];
    final charEdges =
        (_asMap(json['characters'])?['edges'] as List?) ?? const [];
    for (final e in charEdges) {
      final edge = _asMap(e);
      final node = _asMap(edge?['node']);
      if (edge == null || node == null) continue;
      final name = _asMap(node['name']);
      final vas = (edge['voiceActors'] as List?) ?? const [];
      final va = vas.isEmpty ? null : _asMap(vas.first);
      characters.add(
        AnimeCharacter(
          id: node['id'] as int? ?? 0,
          name: (name?['full'] as String?) ?? 'Unknown',
          imageUrl: _asMap(node['image'])?['large'] as String?,
          role: edge['role'] as String?,
          voiceActor: _asMap(va?['name'])?['full'] as String?,
        ),
      );
    }

    // Only anime can be opened in this screen, so manga/novel relations
    // are left out.
    final relations = <AnimeRelation>[];
    for (final e in (_asMap(json['relations'])?['edges'] as List?) ?? const []) {
      final edge = _asMap(e);
      final node = _asMap(edge?['node']);
      if (edge == null || node == null || node['type'] != 'ANIME') continue;
      relations.add(
        AnimeRelation(
          label: _prettyEnum((edge['relationType'] as String?) ?? 'Related'),
          media: AnimeMedia.fromJson(node),
        ),
      );
    }

    final recs = <AnimeRecommendation>[];
    for (final n
        in (_asMap(json['recommendations'])?['nodes'] as List?) ?? const []) {
      final node = _asMap(n);
      final rec = _asMap(node?['mediaRecommendation']);
      if (node == null || rec == null) continue;
      recs.add(
        AnimeRecommendation(
          media: AnimeMedia.fromJson(rec),
          rating: node['rating'] as int?,
        ),
      );
    }

    final externalLinks = <AnimeExternalLink>[
      for (final l in (json['externalLinks'] as List?) ?? const [])
        if (l is Map)
          AnimeExternalLink.fromJson(_asMap(l) ?? const {}),
    ];

    return AnimeDetails(
      media: AnimeMedia.fromJson(json),
      nativeTitle: title?['native'] as String?,
      synonyms: ((json['synonyms'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      description: _cleanDescription(json['description'] as String?),
      duration: json['duration'] as int?,
      season: json['season'] as String?,
      seasonYear: json['seasonYear'] as int?,
      endDate: AnimeDate.fromJson(json['endDate']),
      favourites: json['favourites'] as int?,
      tags: tags,
      studios: studios,
      trailer: AnimeTrailer.fromJson(json['trailer']),
      characters: characters,
      relations: relations,
      recommendations: recs,
      externalLinks: externalLinks,
    );
  }

  /// "Winter 2026", or null when AniList has no season.
  String? get seasonLabel {
    final s = season;
    if (s == null) return null;
    return '${_prettyEnum(s)}${seasonYear == null ? '' : ' $seasonYear'}';
  }

  /// "Jan 5, 2026 – Mar 30, 2026", "Jan 5, 2026 – Present", or a single date.
  String? get airedLabel {
    final start = media.startDate;
    if (start == null) return null;
    final end = endDate;
    if (end == null) {
      return media.status == 'RELEASING' ? '${start.label} – Present' : start.label;
    }
    if (end.label == start.label) return start.label;
    return '${start.label} – ${end.label}';
  }
}

class AnimeTag {
  const AnimeTag({required this.name, required this.rank});
  final String name;

  /// 0–100 relevance.
  final int rank;
}

class AnimeTrailer {
  const AnimeTrailer({required this.id, required this.site, this.thumbnail});

  final String id;
  final String site;
  final String? thumbnail;

  static AnimeTrailer? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'] as String?;
    final site = json['site'] as String?;
    if (id == null || site == null) return null;
    return AnimeTrailer(
      id: id,
      site: site,
      thumbnail: json['thumbnail'] as String?,
    );
  }

  String? get url => switch (site.toLowerCase()) {
    'youtube' => 'https://www.youtube.com/watch?v=$id',
    'dailymotion' => 'https://www.dailymotion.com/video/$id',
    _ => null,
  };
}

class AnimeCharacter {
  const AnimeCharacter({
    required this.id,
    required this.name,
    this.imageUrl,
    this.role,
    this.voiceActor,
  });

  final int id;
  final String name;
  final String? imageUrl;

  /// MAIN, SUPPORTING or BACKGROUND.
  final String? role;
  final String? voiceActor;

  bool get isMain => role == 'MAIN';
  String? get roleLabel => role == null ? null : _prettyEnum(role!);
}

class AnimeRelation {
  const AnimeRelation({required this.label, required this.media});

  /// "Sequel", "Prequel", "Side Story"...
  final String label;
  final AnimeMedia media;
}

class AnimeRecommendation {
  const AnimeRecommendation({required this.media, this.rating});
  final AnimeMedia media;
  final int? rating;
}

/// Official streaming platform or information link from AniList.
class AnimeExternalLink {
  const AnimeExternalLink({
    required this.id,
    required this.url,
    required this.site,
    this.icon,
    this.color,
    this.type,
    this.language,
  });

  final int id;
  final String url;
  final String site;
  final String? icon;
  final String? color;
  final String? type;
  final String? language;

  bool get isStreaming => type?.toUpperCase() == 'STREAMING';

  factory AnimeExternalLink.fromJson(Map<String, dynamic> json) {
    return AnimeExternalLink(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
      site: json['site'] as String? ?? '',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      type: json['type'] as String?,
      language: json['language'] as String?,
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────

Map<String, dynamic>? _asMap(Object? o) =>
    o is Map ? o.cast<String, dynamic>() : null;

/// "SIDE_STORY" -> "Side Story".
String _prettyEnum(String raw) => raw
    .split('_')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
    .join(' ');

/// AniList descriptions still contain `<br>`, `<i>`, `<b>` and entities.
String? _cleanDescription(String? raw) {
  if (raw == null) return null;
  final text = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return text.isEmpty ? null : text;
}
