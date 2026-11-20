import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:flutter/scheduler.dart';

import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/network/api_cache.dart';
import 'package:aniways/models/anime_media.dart';

/// Every list the app can show, with its title/icon and how to fetch a page.
/// The home sections and the common "View all" screen both run off this.
enum AnimeListType {
  trendingAiring(
    title: 'Trending airing',
    icon: Icons.local_fire_department_rounded,
  ),
  currentSeason(title: 'Current season', icon: Icons.calendar_month_rounded),
  recentlyReleased(
    title: 'Recently released',
    icon: Icons.new_releases_rounded,
  ),
  trending(title: 'Trending', icon: Icons.trending_up_rounded),
  popular(title: 'Most popular', icon: Icons.favorite_rounded),
  upcoming(title: 'Upcoming', icon: Icons.schedule_rounded),
  topRated(title: 'Top rated', icon: Icons.star_rounded);

  const AnimeListType({required this.title, required this.icon});

  final String title;
  final IconData icon;

  /// Cached-then-fresh: emits the stored page right away if there is one,
  /// then the refreshed page when the stored one was out of date. A failed
  /// refresh is ignored when something was already emitted.
  Stream<AnilistPage> watch(int page, int perPage) => switch (this) {
    AnimeListType.trendingAiring => anilistService.watchTopTrendingAiring(
      page: page,
      perPage: perPage,
    ),
    AnimeListType.currentSeason => anilistService.watchCurrentSeason(
      page: page,
      perPage: perPage,
    ),
    AnimeListType.recentlyReleased => anilistService.watchRecentlyReleased(
      page: page,
      perPage: perPage,
    ),
    AnimeListType.trending => anilistService.watchTrending(
      page: page,
      perPage: perPage,
    ),
    AnimeListType.popular => anilistService.watchPopular(
      page: page,
      perPage: perPage,
    ),
    AnimeListType.upcoming => anilistService.watchUpcoming(
      page: page,
      perPage: perPage,
    ),
    AnimeListType.topRated => anilistService.watchTopRated(
      page: page,
      perPage: perPage,
    ),
  };

  /// One-shot version: the fresh page, or the stored one if the network
  /// fails.
  Future<AnilistPage> fetch(int page, int perPage) => watch(page, perPage).last;
}

/// Short, user-facing text for a failed request.
String describeError(Object? error) {
  if (error is AnilistException) {
    if (error.isNetworkError) return 'No connection. Check your internet.';
    if (error.isRateLimited) return 'Too many requests. Try again shortly.';
    return error.message;
  }
  return 'Something went wrong.';
}

/// `notifyListeners` that is safe to call while the framework is building
/// (e.g. a scroll listener asking for the next page mid-layout).
mixin SafeNotifier on ChangeNotifier {
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void safeNotify() {
    if (_isDisposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Page-by-page loader for an infinite list.
///
/// Call [loadNext] whenever the user nears the end; it ignores the call while
/// a request is running, when everything is loaded, or after a failure (until
/// [retry]). Duplicate ids (AniList results shift between requests) are
/// dropped.
class PagedAnime extends ChangeNotifier with SafeNotifier {
  PagedAnime(this._fetch, {this.perPage = 20});

  final Future<AnilistPage> Function(int page, int perPage) _fetch;
  final int perPage;

  final List<AnimeMedia> items = [];
  final Set<int> _ids = {};

  int _nextPage = 1;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  /// Bumped by [refresh] so responses from older requests are ignored.
  int _generation = 0;

  bool get hasMore => _hasMore;
  bool get isLoading => _loading;
  bool get hasError => _error != null;
  Object? get error => _error;
  bool get isInitialLoading => _loading && items.isEmpty;

  Future<void> loadNext() async {
    if (_loading || !_hasMore || _error != null) return;

    _loading = true;
    safeNotify();

    final generation = _generation;
    try {
      final page = await _fetch(_nextPage, perPage);
      if (_isStale(generation)) return;
      _append(page);
      _nextPage++;
    } catch (e, st) {
      if (_isStale(generation)) return;
      log.e('Failed to load page $_nextPage', error: e, stackTrace: st);
      _error = e;
    }

    _loading = false;
    safeNotify();
  }

  /// Clears the error and tries again.
  Future<void> retry() {
    _error = null;
    return loadNext();
  }

  /// Reloads from page 1. The current items stay visible until the new first
  /// page arrives.
  Future<void> refresh() async {
    // Otherwise a still-fresh cached page 1 would be returned as is.
    ApiCache.instance.invalidate();

    final generation = ++_generation;
    _loading = true;
    _error = null;
    safeNotify();

    try {
      final page = await _fetch(1, perPage);
      if (_isStale(generation)) return;
      items.clear();
      _ids.clear();
      _append(page);
      _nextPage = 2;
    } catch (e, st) {
      if (_isStale(generation)) return;
      log.e('Failed to refresh list', error: e, stackTrace: st);
      _error = e;
    }

    _loading = false;
    safeNotify();
  }

  void _append(AnilistPage page) {
    for (final json in page.items) {
      final anime = AnimeMedia.fromJson(json);
      if (_ids.add(anime.id)) items.add(anime);
    }
    _hasMore = page.hasNextPage;
  }

  bool _isStale(int generation) => generation != _generation || isDisposed;
}
