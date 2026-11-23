import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';

import 'api_cache.dart';
import 'api_client.dart';
import 'package:aniways/models/anime_media.dart';
export 'package:aniways/models/anime_media.dart' show AiringSchedule, GenreItem;

/// All AniList GraphQL requests used by the app.
///
/// Built on the shared [apiClient] (timeouts, auth header, logging). Every
/// method returns the decoded JSON (`Map`s / [AnilistPage]); turning that
/// into models is a separate step.
///
/// Responses are cached (memory + disk, see [ApiCache] and [CachePolicy] for
/// the lifetimes). Each list has two flavours:
///
/// - `trending(...)`: a [Future] with the fresh data, or the stored copy if
///   the network fails.
/// - `watchTrending(...)`: a [Stream] that emits the stored copy right away,
///   then the refreshed one if the stored copy was out of date. Use it where
///   showing something instantly matters (the home screen).
///
/// Wrap calls with [NetworkUtils.executeRequest] where you want the
/// offline snackbar / retry-on-reconnect behaviour:
///
/// ```dart
/// final page = await NetworkUtils().executeRequest(
///   context,
///   () => anilistService.trending(),
/// );
/// ```
final AnilistService anilistService = AnilistService();

// ═════════════════════════════════════════════════════════════════════════
// Queries
// ═════════════════════════════════════════════════════════════════════════

/// Fields every anime card/list needs.
const _mediaCardFragment = r'''
fragment MediaCard on Media {
  id
  idMal
  title { romaji english }
  coverImage { medium large color }
  format
  status
  episodes
  averageScore
  popularity
  genres
  isAdult
}
''';

/// One query behind every "list of anime" endpoint (search, trending,
/// top rated, popular, released, upcoming, season, genre). Variables that
/// aren't sent are simply not applied as filters.
const _mediaPageQuery =
    r'''
query (
  $page: Int,
  $perPage: Int,
  $search: String,
  $sort: [MediaSort],
  $status: MediaStatus,
  $genre: String,
  $format: MediaFormat,
  $season: MediaSeason,
  $year: Int,
  $isAdult: Boolean
) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { total currentPage hasNextPage }
    media(
      type: ANIME,
      isAdult: $isAdult,
      search: $search,
      sort: $sort,
      status: $status,
      genre: $genre,
      format: $format,
      season: $season,
      seasonYear: $year
    ) {
      ...MediaCard
      startDate { year month day }
      nextAiringEpisode { episode airingAt }
    }
  }
}
''' +
    _mediaCardFragment;

const _genresQuery = r'''
query {
  genres: GenreCollection
  action: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Action"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  adventure: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Adventure"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  comedy: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Comedy"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  drama: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Drama"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  ecchi: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Ecchi"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  fantasy: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Fantasy"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  hentai: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Hentai"], sort: POPULARITY_DESC) { coverImage { medium } } }
  horror: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Horror"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  mahouShoujo: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Mahou Shoujo"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  mecha: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Mecha"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  music: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Music"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  mystery: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Mystery"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  psychological: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Psychological"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  romance: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Romance"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  sciFi: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Sci-Fi"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  sliceOfLife: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Slice of Life"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  sports: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Sports"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  supernatural: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Supernatural"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
  thriller: Page(page: 1, perPage: 8) { media(type: ANIME, genre_in: ["Thriller"], sort: POPULARITY_DESC, isAdult: false) { coverImage { medium } } }
}
''';

const _browseCoversQuery = r'''
query {
  tv: Page(page: 1, perPage: 1) { media(type: ANIME, format: TV, sort: POPULARITY_DESC, isAdult: false) { coverImage { medium large } } }
  movie: Page(page: 1, perPage: 1) { media(type: ANIME, format: MOVIE, sort: POPULARITY_DESC, isAdult: false) { coverImage { medium large } } }
  airing: Page(page: 1, perPage: 1) { media(type: ANIME, status: RELEASING, sort: POPULARITY_DESC, isAdult: false) { coverImage { medium large } } }
  topRated: Page(page: 1, perPage: 1) { media(type: ANIME, sort: SCORE_DESC, isAdult: false) { coverImage { medium large } } }
}
''';

const _genreAliases = <String, String>{
  'Action': 'action',
  'Adventure': 'adventure',
  'Comedy': 'comedy',
  'Drama': 'drama',
  'Ecchi': 'ecchi',
  'Fantasy': 'fantasy',
  'Hentai': 'hentai',
  'Horror': 'horror',
  'Mahou Shoujo': 'mahouShoujo',
  'Mecha': 'mecha',
  'Music': 'music',
  'Mystery': 'mystery',
  'Psychological': 'psychological',
  'Romance': 'romance',
  'Sci-Fi': 'sciFi',
  'Slice of Life': 'sliceOfLife',
  'Sports': 'sports',
  'Supernatural': 'supernatural',
  'Thriller': 'thriller',
};

const _detailsQuery = r'''
query ($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    idMal
    title { romaji english native }
    synonyms
    description(asHtml: false)
    coverImage { medium large extraLarge color }
    bannerImage
    format
    status
    episodes
    duration
    season
    seasonYear
    startDate { year month day }
    endDate { year month day }
    averageScore
    meanScore
    popularity
    favourites
    genres
    isAdult
    tags { name rank }
    studios(isMain: true) { nodes { id name } }
    trailer { id site thumbnail }
    nextAiringEpisode { episode airingAt timeUntilAiring }
    externalLinks {
      id
      url
      site
      icon
      color
      type
      language
    }
    characters(sort: ROLE, perPage: 25) {
      edges {
        role
        node { id name { full native } image { large } description }
        voiceActors(language: JAPANESE, sort: RELEVANCE) {
          id
          name { full native }
          image { large }
          languageV2
        }
      }
      pageInfo { total hasNextPage }
    }
    relations {
      edges {
        relationType(version: 2)
        node {
          id
          idMal
          type
          format
          status
          title { romaji english native }
          coverImage { medium large extraLarge color }
          startDate { year month day }
          episodes
          averageScore
        }
      }
    }
    recommendations(sort: RATING_DESC, perPage: 15) {
      pageInfo { total hasNextPage }
      nodes {
        rating
        mediaRecommendation {
          id
          idMal
          title { romaji english }
          coverImage { medium large extraLarge color }
          format
          status
          averageScore
          popularity
        }
      }
    }
  }
}
''';

const _mediaRecommendationsQuery = r'''
query ($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    recommendations(sort: RATING_DESC, perPage: 25) {
      nodes {
        rating
        mediaRecommendation {
          id
          idMal
          title { romaji english }
          coverImage { medium large extraLarge color }
          bannerImage
          format
          status
          episodes
          averageScore
          popularity
          genres
          isAdult
        }
      }
    }
  }
}
''';

const _popularFranchisesQuery = r'''
query ($page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { hasNextPage }
    media(type: ANIME, sort: POPULARITY_DESC, isAdult: false) {
      id
      idMal
      title { romaji english }
      coverImage { medium large extraLarge color }
      bannerImage
      format
      status
      episodes
      averageScore
      popularity
      genres
      relations {
        edges {
          relationType(version: 2)
          node {
            id
            type
          }
        }
      }
    }
  }
}
''';

const _scheduleQuery =
    r'''
query ($start: Int, $end: Int, $page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { total currentPage hasNextPage }
    airingSchedules(
      airingAt_greater: $start,
      airingAt_lesser: $end,
      sort: TIME
    ) {
      id
      airingAt
      timeUntilAiring
      episode
      media { ...MediaCard }
    }
  }
}
''' +
    _mediaCardFragment;

// ═════════════════════════════════════════════════════════════════════════
// Cache helpers
// ═════════════════════════════════════════════════════════════════════════

/// Same policy for every response.
CachePolicyResolver _always(CachePolicy policy) =>
    (_) => policy;

/// [policy], but an empty list is not stored: it is more likely a hiccup than
/// the truth, and must not replace a good older entry.
CachePolicyResolver _unlessEmpty(CachePolicy policy) => (data) {
  final media = (data['Page'] as Map?)?['media'];
  return media is List && media.isNotEmpty ? policy : null;
};

/// Details lifetime depends on the show: finished ones never change, airing
/// ones do.
CachePolicy? _detailsPolicy(Map<String, dynamic> data) {
  final media = data['Media'];
  if (media is! Map) return null;
  return switch (media['status']) {
    'FINISHED' || 'CANCELLED' => CachePolicy.detailsFinished,
    'RELEASING' => CachePolicy.detailsAiring,
    'NOT_YET_RELEASED' => CachePolicy.detailsUpcoming,
    _ => CachePolicy.detailsOther,
  };
}

// ═════════════════════════════════════════════════════════════════════════
// Service
// ═════════════════════════════════════════════════════════════════════════

class AnilistService {
  AnilistService({Dio? client, ApiCache? cache})
    : _dio = client ?? apiClient,
      _cache = cache ?? ApiCache.instance;

  final Dio _dio;
  final ApiCache _cache;

  /// Absolute URL, so it works regardless of the client's `baseUrl`.
  static const endpoint = 'https://graphql.anilist.co';

  List<String>? _genreCache;
  List<GenreItem>? _genreItemCache;

  // ── Lists ───────────────────────────────────────────────────────────

  Future<AnilistPage> search(
    String? query, {
    int page = 1,
    int perPage = 20,
    String? sort,
    String? status,
    String? genre,
    String? format,
    String? season,
    int? year,
    bool? isAdult,
  }) {
    final trimmed = query?.trim();
    final hasSearch = trimmed != null && trimmed.isNotEmpty;
    return _watchPage(
      page: page,
      perPage: perPage,
      search: hasSearch ? trimmed : null,
      sort: sort ?? (hasSearch ? 'SEARCH_MATCH' : 'POPULARITY_DESC'),
      status: status,
      genre: genre,
      format: format,
      season: season,
      year: year,
      isAdult: isAdult,
      policy: CachePolicy.search,
    ).last;
  }

  Stream<AnilistPage> watchTopRated({int page = 1, int perPage = 20}) =>
      _watchPage(
        page: page,
        perPage: perPage,
        sort: 'SCORE_DESC',
        policy: CachePolicy.ranking,
      );

  Future<AnilistPage> topRated({int page = 1, int perPage = 20}) =>
      watchTopRated(page: page, perPage: perPage).last;

  Stream<AnilistPage> watchTrending({int page = 1, int perPage = 20}) =>
      _watchPage(
        page: page,
        perPage: perPage,
        sort: 'TRENDING_DESC',
        policy: CachePolicy.trending,
      );

  Future<AnilistPage> trending({int page = 1, int perPage = 20}) =>
      watchTrending(page: page, perPage: perPage).last;

  Stream<AnilistPage> watchPopular({int page = 1, int perPage = 20}) =>
      _watchPage(
        page: page,
        perPage: perPage,
        sort: 'POPULARITY_DESC',
        policy: CachePolicy.ranking,
      );

  Future<AnilistPage> popular({int page = 1, int perPage = 20}) =>
      watchPopular(page: page, perPage: perPage).last;

  /// Fetches distinct, top popular anime franchises by filtering out
  /// sequels and duplicate seasons using AniList's official relations graph.
  Future<List<AnimeMedia>> popularFranchises({int limit = 52}) async {
    final results = <AnimeMedia>[];
    final excludedIds = <int>{};

    try {
      // Fetch 3 pages (150 anime) concurrently for instant loading
      final pagesData = await Future.wait([
        for (int p = 1; p <= 3; p++)
          _query(
            _popularFranchisesQuery,
            variables: {'page': p, 'perPage': 50},
            cache: _always(CachePolicy.ranking),
          ),
      ]);

      for (final data in pagesData) {
        final mediaList = (data['Page']?['media'] as List?) ?? const [];
        for (final m in mediaList) {
          if (m is! Map) continue;
          final id = m['id'] as int?;
          if (id == null || excludedIds.contains(id)) continue;

          final relations = (m['relations']?['edges'] as List?) ?? const [];

          // If AniList marks this as having a PREQUEL anime, it is a sequel -> skip
          final hasPrequel = relations.any((e) {
            final edge = e as Map?;
            final relType = edge?['relationType'] as String?;
            final nodeType = edge?['node']?['type'] as String?;
            return relType == 'PREQUEL' && nodeType == 'ANIME';
          });

          if (hasPrequel) {
            continue;
          }

          // Accept Season 1 / origin show
          results.add(AnimeMedia.fromJson(m.cast<String, dynamic>()));

          // Exclude all related sequels, side-stories, alternative versions, and summaries
          for (final e in relations) {
            final edge = e as Map?;
            final relType = edge?['relationType'] as String?;
            final relatedId = edge?['node']?['id'] as int?;
            final nodeType = edge?['node']?['type'] as String?;
            if (relatedId != null && nodeType == 'ANIME') {
              if (relType == 'SEQUEL' ||
                  relType == 'SIDE_STORY' ||
                  relType == 'ALTERNATIVE' ||
                  relType == 'SPIN_OFF' ||
                  relType == 'SUMMARY') {
                excludedIds.add(relatedId);
              }
            }
          }

          if (results.length >= limit) break;
        }
        if (results.length >= limit) break;
      }
    } catch (e) {
      log.w('Failed to fetch popular franchises: $e');
    }

    return results;
  }

  /// Currently airing shows, newest start date first.
  Stream<AnilistPage> watchRecentlyReleased({int page = 1, int perPage = 20}) =>
      _watchPage(
        page: page,
        perPage: perPage,
        sort: 'START_DATE_DESC',
        status: 'RELEASING',
        policy: CachePolicy.season,
      );

  Future<AnilistPage> recentlyReleased({int page = 1, int perPage = 20}) =>
      watchRecentlyReleased(page: page, perPage: perPage).last;

  Stream<AnilistPage> watchUpcoming({int page = 1, int perPage = 20}) =>
      _watchPage(
        page: page,
        perPage: perPage,
        sort: 'POPULARITY_DESC',
        status: 'NOT_YET_RELEASED',
        policy: CachePolicy.upcoming,
      );

  Future<AnilistPage> upcoming({int page = 1, int perPage = 20}) =>
      watchUpcoming(page: page, perPage: perPage).last;

  /// Anime for a specific genre, sorted by popularity.
  Stream<AnilistPage> watchGenre(
    String genre, {
    int page = 1,
    int perPage = 20,
  }) =>
      _watchPage(
        page: page,
        perPage: perPage,
        genre: genre,
        sort: 'POPULARITY_DESC',
        policy: CachePolicy.ranking,
      );

  Future<AnilistPage> genre(
    String genre, {
    int page = 1,
    int perPage = 20,
  }) =>
      watchGenre(genre, page: page, perPage: perPage).last;

  /// Trending shows that are currently airing.
  Stream<AnilistPage> watchTopTrendingAiring({
    int page = 1,
    int perPage = 20,
  }) => _watchPage(
    page: page,
    perPage: perPage,
    sort: 'TRENDING_DESC',
    status: 'RELEASING',
    policy: CachePolicy.trending,
  );

  Future<AnilistPage> topTrendingAiring({int page = 1, int perPage = 20}) =>
      watchTopTrendingAiring(page: page, perPage: perPage).last;

  /// Anime of the current season (pass [now] to override, e.g. in tests).
  /// The season and year are part of the request, so a new season never
  /// reuses the old season's cached list.
  Stream<AnilistPage> watchCurrentSeason({
    int page = 1,
    int perPage = 50,
    DateTime? now,
  }) {
    final (season, year) = seasonFor(now ?? DateTime.now());
    return _watchPage(
      page: page,
      perPage: perPage,
      sort: 'POPULARITY_DESC',
      season: season,
      year: year,
      policy: CachePolicy.season,
    );
  }

  Future<AnilistPage> currentSeason({
    int page = 1,
    int perPage = 50,
    DateTime? now,
  }) => watchCurrentSeason(page: page, perPage: perPage, now: now).last;

  Future<AnilistPage> byGenre(String genre, {int page = 1, int perPage = 20}) =>
      _watchPage(
        page: page,
        perPage: perPage,
        sort: 'POPULARITY_DESC',
        genre: genre,
        policy: CachePolicy.ranking,
      ).last;

  // ── Genres ──────────────────────────────────────────────────────────

  /// All genres with representative anime cover images. Kept in memory for
  /// the session and on disk for weeks, since the list is static.
  Future<List<GenreItem>> genres({bool forceRefresh = false}) async {
    if (!forceRefresh && _genreItemCache != null) return _genreItemCache!;
    if (forceRefresh) await _cache.remove(ApiCache.keyFor(_genresQuery));
    final data = await _query(_genresQuery, cache: _always(CachePolicy.genres));

    final rawGenres =
        (data['genres'] ?? data['GenreCollection'] as List?) ?? const [];
    final adultEnabled = SharedPreferencesService().enableAdultContent;
    final genreNames = rawGenres
        .whereType<String>()
        .where((g) => adultEnabled || g != 'Hentai')
        .toList();
    _genreCache = genreNames;

    final items = <GenreItem>[];
    final usedUrls = <String>{};

    for (final name in genreNames) {
      final alias = _genreAliases[name] ?? name.toLowerCase();
      final page = data[alias] as Map?;
      final mediaList = (page?['media'] as List?)?.whereType<Map>().toList() ??
          const <Map>[];

      // Find the top media item whose cover image hasn't been assigned yet.
      String? chosenUrl;
      for (final m in mediaList) {
        final cover = m['coverImage'] as Map?;
        final url = cover?['medium'] as String?;
        if (url != null && !usedUrls.contains(url)) {
          chosenUrl = url;
          usedUrls.add(url);
          break;
        }
      }

      // If all candidate covers were already used, fall back to the first available.
      if (chosenUrl == null && mediaList.isNotEmpty) {
        final cover = mediaList.first['coverImage'] as Map?;
        chosenUrl = cover?['medium'] as String?;
      }

      items.add(GenreItem(name: name, coverUrl: chosenUrl));
    }

    return _genreItemCache = items;
  }

  /// All genre names only.
  Future<List<String>> genreNames({bool forceRefresh = false}) async {
    if (!forceRefresh && _genreCache != null) return _genreCache!;
    await genres(forceRefresh: forceRefresh);
    return _genreCache!;
  }

  /// Clears in-memory genre and browse caches (called when 18+ mode is toggled).
  void clearGenreCache() {
    _genreCache = null;
    _genreItemCache = null;
    _browseCoversCache = null;
  }

  Map<String, String>? _browseCoversCache;

  /// Top anime cover images for the 4 Browse categories (TV, Movie, Airing, Top Rated).
  Future<Map<String, String>> browseCovers({bool forceRefresh = false}) async {
    if (!forceRefresh && _browseCoversCache != null) return _browseCoversCache!;
    if (forceRefresh) await _cache.remove(ApiCache.keyFor(_browseCoversQuery));
    try {
      final data = await _query(_browseCoversQuery, cache: _always(CachePolicy.genres));
      final result = <String, String>{};
      for (final key in ['tv', 'movie', 'airing', 'topRated']) {
        final page = data[key] as Map?;
        final mediaList = page?['media'] as List?;
        if (mediaList != null && mediaList.isNotEmpty) {
          final first = mediaList.first as Map?;
          final cover = first?['coverImage'] as Map?;
          final url = (cover?['large'] ?? cover?['medium']) as String?;
          if (url != null) result[key] = url;
        }
      }
      return _browseCoversCache = result;
    } catch (_) {
      return _browseCoversCache ?? const {};
    }
  }

  Map<String, String>? _seasonCoversCache;

  /// Top anime cover images for the requested seasons.
  Future<Map<String, String>> seasonCovers(
    List<({String season, int year})> seasons, {
    bool forceRefresh = false,
  }) async {
    if (seasons.isEmpty) return const {};
    if (!forceRefresh && _seasonCoversCache != null) return _seasonCoversCache!;

    final b = StringBuffer('query {\n');
    for (final s in seasons) {
      final alias = 's_${s.year}_${s.season}';
      b.writeln(
        '  $alias: Page(page: 1, perPage: 1) { media(type: ANIME, season: ${s.season}, seasonYear: ${s.year}, sort: POPULARITY_DESC, isAdult: false) { coverImage { medium large } } }',
      );
    }
    b.writeln('}');
    final query = b.toString();

    if (forceRefresh) await _cache.remove(ApiCache.keyFor(query));
    try {
      final data = await _query(query, cache: _always(CachePolicy.genres));
      final result = <String, String>{};
      for (final s in seasons) {
        final alias = 's_${s.year}_${s.season}';
        final key = '${s.season}_${s.year}';
        final page = data[alias] as Map?;
        final mediaList = page?['media'] as List?;
        if (mediaList != null && mediaList.isNotEmpty) {
          final first = mediaList.first as Map?;
          final cover = first?['coverImage'] as Map?;
          final url = (cover?['large'] ?? cover?['medium']) as String?;
          if (url != null) result[key] = url;
        }
      }
      return _seasonCoversCache = result;
    } catch (_) {
      return _seasonCoversCache ?? const {};
    }
  }

  // ── Details ─────────────────────────────────────────────────────────

  /// Full details for one anime (the raw `Media` object). Cached per anime
  /// for a time that depends on its status.
  Future<Map<String, dynamic>> details(int id) async {
    final data = await _query(
      _detailsQuery,
      variables: {'id': id},
      cache: _detailsPolicy,
    );
    return (data['Media'] as Map).cast<String, dynamic>();
  }

  /// Fetches raw recommendation nodes for a single media ID.
  Future<List<Map<String, dynamic>>> _fetchRecommendationsForMedia(int id) async {
    try {
      final data = await _query(
        _mediaRecommendationsQuery,
        variables: {'id': id},
        cache: _always(const CachePolicy(Duration(hours: 12))),
      );
      final media = data['Media'] as Map?;
      final recNodes =
          ((media?['recommendations'] as Map?)?['nodes'] as List?) ?? const [];
      return recNodes
          .whereType<Map>()
          .map((n) => n.cast<String, dynamic>())
          .toList();
    } catch (e) {
      log.w('Failed to fetch recommendations for anime $id: $e');
      return const [];
    }
  }

  /// Fetches personalized recommendations based on user's seed anime IDs.
  ///
  /// - Excludes [excludedIds] (e.g. completed, currently watching, or dropped anime).
  /// - Excludes seed anime IDs themselves so known shows are never recommended back.
  /// - Queries recommendation nodes from AniList in parallel for up to 8 seed shows.
  /// - Uses a collaborative multi-signal scoring algorithm:
  ///   - AniList community upvotes (`rating`).
  ///   - Average score of the recommended title.
  ///   - Seed priority weighting (recent favorites receive higher influence).
  ///   - Overlap bonus: anime recommended by multiple seeds receive a significant boost (+200 per seed).
  /// - Filters out negative-voted recommendations, music formats, and low-rated shows.
  Future<List<AnimeMedia>> recommendationsForAnime({
    required List<int> animeIds,
    Set<int> excludedIds = const {},
    List<String> genres = const [],
    int limit = 20,
  }) async {
    if (animeIds.isEmpty) return const [];

    final seedSet = animeIds.toSet();
    final allExcluded = <int>{...excludedIds, ...seedSet};

    // Query up to 8 seeds concurrently
    final seedsToQuery = animeIds.take(8).toList();
    final recsPerSeed = await Future.wait(
      seedsToQuery.map((id) => _fetchRecommendationsForMedia(id)),
    );

    final candidateMap = <int, AnimeMedia>{};
    final candidateScores = <int, double>{};
    final seedCount = <int, int>{};

    for (int seedIndex = 0; seedIndex < seedsToQuery.length; seedIndex++) {
      final nodes = recsPerSeed[seedIndex];
      // Seed priority: first seed gets 1.0 weight, tapering down for later seeds
      final seedWeight = 1.0 - (seedIndex * 0.05);

      for (final node in nodes) {
        final recMediaMap = node['mediaRecommendation'] as Map?;
        if (recMediaMap == null) continue;

        final id = recMediaMap['id'] as int?;
        if (id == null || allExcluded.contains(id)) continue;

        final format = recMediaMap['format'] as String?;
        if (format == 'MUSIC') continue;

        final rating = (node['rating'] as num?)?.toInt() ?? 0;
        // Skip negative or zero-voted recommendations
        if (rating <= 0) continue;

        final averageScore = (recMediaMap['averageScore'] as num?)?.toDouble() ?? 0.0;
        // Filter out low quality shows if scored
        if (averageScore > 0 && averageScore < 60) continue;

        if (!candidateMap.containsKey(id)) {
          try {
            candidateMap[id] = AnimeMedia.fromJson(recMediaMap.cast<String, dynamic>());
          } catch (_) {
            continue;
          }
        }

        // Base score:
        // Capped community upvotes plus average score contribution
        final double voteScore = math.min(100.0, rating.toDouble()) * 1.5;
        final double qualityScore = averageScore * 1.2;
        final double weightedScore = (voteScore + qualityScore) * seedWeight;

        candidateScores[id] = (candidateScores[id] ?? 0.0) + weightedScore;
        seedCount[id] = (seedCount[id] ?? 0) + 1;
      }
    }

    if (candidateMap.isEmpty) return const [];

    // Sort by final score with collaborative filtering overlap boost
    final rankedEntries = candidateMap.entries.toList()
      ..sort((a, b) {
        final countA = seedCount[a.key] ?? 1;
        final countB = seedCount[b.key] ?? 1;

        final scoreA = (candidateScores[a.key] ?? 0.0) + ((countA - 1) * 200.0);
        final scoreB = (candidateScores[b.key] ?? 0.0) + ((countB - 1) * 200.0);

        return scoreB.compareTo(scoreA);
      });

    return rankedEntries.take(limit).map((e) => e.value).toList();
  }

  // ── Airing schedule ─────────────────────────────────────────────────

  /// One page of the Monday–Sunday week containing [weekOf]
  /// (defaults to this week, local time).
  Future<AnilistPage> weeklySchedule({
    DateTime? weekOf,
    int page = 1,
    int perPage = 50,
    bool forceRefresh = false,
  }) async {
    final (start, end) = weekRange(weekOf ?? DateTime.now());
    // A week that is over can't change, so it can be kept much longer.
    final isPast = end.isBefore(DateTime.now());
    final vars = {
      // The API filters with strict > and <, so widen by one second.
      'start': start.millisecondsSinceEpoch ~/ 1000 - 1,
      'end': end.millisecondsSinceEpoch ~/ 1000,
      'page': page,
      'perPage': perPage,
    };
    if (forceRefresh) {
      await _cache.remove(ApiCache.keyFor(_scheduleQuery, vars));
    }
    final data = await _query(
      _scheduleQuery,
      variables: vars,
      cache: _always(isPast ? CachePolicy.pastSchedule : CachePolicy.schedule),
    );
    return AnilistPage.fromJson(data['Page'], itemsKey: 'airingSchedules');
  }

  /// Every airing in the week, following pagination (capped at [maxPages]
  /// to stay well inside AniList's rate limit).
  Future<List<Map<String, dynamic>>> weeklyScheduleAll({
    DateTime? weekOf,
    int maxPages = 10,
    bool forceRefresh = false,
  }) async {
    final all = <Map<String, dynamic>>[];
    for (var page = 1; page <= maxPages; page++) {
      final result = await weeklySchedule(
        weekOf: weekOf,
        page: page,
        forceRefresh: forceRefresh,
      );
      all.addAll(result.items);
      if (!result.hasNextPage) break;
    }
    return all;
  }

  /// Every airing in the week parsed into [AiringSchedule] models.
  Future<List<AiringSchedule>> weeklyAiringSchedules({
    DateTime? weekOf,
    int maxPages = 10,
    bool forceRefresh = false,
  }) async {
    final raw = await weeklyScheduleAll(
      weekOf: weekOf,
      maxPages: maxPages,
      forceRefresh: forceRefresh,
    );
    return raw
        .map((json) => AiringSchedule.fromJson(json))
        .toList(growable: false);
  }

  // ── Helpers (public for testing) ────────────────────────────────────

  /// AniList season + year for a date: WINTER Jan–Mar, SPRING Apr–Jun,
  /// SUMMER Jul–Sep, FALL Oct–Dec.
  static (String season, int year) seasonFor(DateTime date) {
    final season = switch (date.month) {
      1 || 2 || 3 => 'WINTER',
      4 || 5 || 6 => 'SPRING',
      7 || 8 || 9 => 'SUMMER',
      _ => 'FALL',
    };
    return (season, date.year);
  }

  /// Local Monday 00:00 (inclusive) to the next Monday 00:00 (exclusive).
  static (DateTime start, DateTime end) weekRange(DateTime date) {
    final start = DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - 1),
    );
    final end = DateTime(start.year, start.month, start.day + 7);
    return (start, end);
  }

  // ── Internals ───────────────────────────────────────────────────────

  Stream<AnilistPage> _watchPage({
    required int page,
    required int perPage,
    required String sort,
    required CachePolicy policy,
    String? search,
    String? status,
    String? genre,
    String? format,
    String? season,
    int? year,
    bool? isAdult,
  }) {
    final prefs = SharedPreferencesService();
    final adultEnabled = prefs.enableAdultContent;
    final bool? effectiveIsAdult;

    if (!adultEnabled) {
      // Zero-leak default: strictly non-adult content
      effectiveIsAdult = false;
    } else if (genre == 'Hentai') {
      // Explicit adult genre query
      effectiveIsAdult = true;
    } else if (isAdult != null) {
      // User specified filter in search
      effectiveIsAdult = isAdult;
    } else if (search != null && search.isNotEmpty) {
      // Unrestricted search when adult content is enabled
      effectiveIsAdult = null;
    } else if (!prefs.includeAdultInHome &&
        (policy == CachePolicy.trending ||
            policy == CachePolicy.season ||
            policy == CachePolicy.upcoming)) {
      // Home screen feed protection
      effectiveIsAdult = false;
    } else {
      effectiveIsAdult = null;
    }

    return _watchQuery(
      _mediaPageQuery,
      variables: {
        'page': page,
        'perPage': perPage,
        'sort': [sort],
        if (search != null && search.isNotEmpty) 'search': search,
        'status': ?status,
        'genre': ?genre,
        'format': ?format,
        'season': ?season,
        'year': ?year,
        'isAdult': ?effectiveIsAdult,
      },
      cache: _unlessEmpty(policy),
    ).map((data) => AnilistPage.fromJson(data['Page'], itemsKey: 'media'));
  }

  /// Cached GraphQL request as a stream (see [ApiCache.watch]). Without a
  /// [cache] policy it is a plain one-shot request.
  Stream<Map<String, dynamic>> _watchQuery(
    String query, {
    Map<String, dynamic>? variables,
    CachePolicyResolver? cache,
  }) {
    if (cache == null) return Stream.fromFuture(_post(query, variables));
    return _cache.watch(
      ApiCache.keyFor(query, variables),
      () => _post(query, variables),
      policy: cache,
    );
  }

  /// Same as [_watchQuery] but resolves to the final value: fresh data, or
  /// the stored copy if the network fails.
  Future<Map<String, dynamic>> _query(
    String query, {
    Map<String, dynamic>? variables,
    CachePolicyResolver? cache,
  }) => _watchQuery(query, variables: variables, cache: cache).last;

  /// POSTs a GraphQL document and returns the `data` object.
  /// Throws [AnilistException] for HTTP, network and GraphQL errors.
  Future<Map<String, dynamic>> _post(
    String query,
    Map<String, dynamic>? variables,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {'query': query, 'variables': ?variables},
      );

      final body = response.data;
      if (body is! Map) {
        throw AnilistException('Unexpected response from AniList');
      }

      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        throw AnilistException(
          _firstErrorMessage(errors),
          statusCode: response.statusCode,
        );
      }

      final data = body['data'];
      if (data is! Map) {
        throw AnilistException('AniList returned no data');
      }
      return data.cast<String, dynamic>();
    } on DioException catch (e) {
      throw AnilistException.fromDio(e);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Result + error types
// ═════════════════════════════════════════════════════════════════════════

/// One page of results plus AniList's paging info.
class AnilistPage {
  const AnilistPage({
    required this.items,
    required this.currentPage,
    required this.hasNextPage,
    this.total,
  });

  /// Raw JSON items (`media` or `airingSchedules`).
  final List<Map<String, dynamic>> items;
  final int currentPage;
  final bool hasNextPage;

  /// Total matches. AniList caps this at 5000 for large result sets.
  final int? total;

  factory AnilistPage.fromJson(Object? page, {required String itemsKey}) {
    final json = (page as Map).cast<String, dynamic>();
    final info = (json['pageInfo'] as Map?)?.cast<String, dynamic>() ?? {};
    final raw = (json[itemsKey] as List?) ?? const [];

    return AnilistPage(
      items: raw.map((e) => (e as Map).cast<String, dynamic>()).toList(),
      currentPage: (info['currentPage'] as int?) ?? 1,
      hasNextPage: (info['hasNextPage'] as bool?) ?? false,
      total: info['total'] as int?,
    );
  }
}

/// Anything that goes wrong talking to AniList.
class AnilistException implements Exception {
  AnilistException(
    this.message, {
    this.statusCode,
    this.retryAfter,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;

  /// Set on HTTP 429 (AniList allows ~90 requests/minute).
  final Duration? retryAfter;

  /// Timeouts / no connection, as opposed to the server rejecting a request.
  final bool isNetworkError;

  bool get isRateLimited => statusCode == 429;

  factory AnilistException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AnilistException(
          'Could not reach AniList. Check your connection.',
          isNetworkError: true,
        );
      default:
        break;
    }

    final status = e.response?.statusCode;
    final body = e.response?.data;

    if (status == 429) {
      final seconds = int.tryParse(
        e.response?.headers.value('retry-after') ?? '',
      );
      log.w('AniList rate limit hit (retry after ${seconds ?? '?'}s)');
      return AnilistException(
        'Too many requests. Please try again in a moment.',
        statusCode: status,
        retryAfter: seconds == null ? null : Duration(seconds: seconds),
      );
    }

    if (body is Map && body['errors'] is List) {
      return AnilistException(
        _firstErrorMessage(body['errors'] as List),
        statusCode: status,
      );
    }

    return AnilistException(
      e.message ?? 'Request to AniList failed',
      statusCode: status,
    );
  }

  @override
  String toString() => 'AnilistException(${statusCode ?? '-'}): $message';
}

String _firstErrorMessage(List errors) {
  final first = errors.first;
  if (first is Map && first['message'] is String) {
    return first['message'] as String;
  }
  return 'AniList returned an error';
}
