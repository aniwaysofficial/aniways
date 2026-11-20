import 'package:flutter/foundation.dart';

import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/api_cache.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/providers/anime_lists.dart';
import 'package:flutter/scheduler.dart';

enum SectionStatus { loading, ready, error }

@immutable
class HomeSectionState {
  const HomeSectionState({
    this.status = SectionStatus.loading,
    this.items = const [],
    this.error,
  });

  final SectionStatus status;
  final List<AnimeMedia> items;
  final Object? error;

  bool get isLoading => status == SectionStatus.loading;
  bool get hasError => status == SectionStatus.error;
}

/// Loads everything the home screen shows. Each section loads independently,
/// so one failing request never blanks the whole screen.
///
/// Sections are cached (see `ApiCache`): stored content shows up immediately
/// on launch, and is refreshed in the background when it is out of date.
///
/// Create it in a `State` and call [load] from `initState`.
class HomeProvider extends ChangeNotifier with SafeNotifier {
  /// Top carousel.
  static const carouselType = AnimeListType.trendingAiring;

  /// Horizontal rows, in display order.
  static const rowTypes = [
    AnimeListType.currentSeason,
    AnimeListType.recentlyReleased,
    AnimeListType.trending,
    AnimeListType.popular,
    AnimeListType.upcoming,
  ];

  static const _carouselCount = 15;
  static const _rowCount = 20;

  /// Gap between the start of one section's load and the next.
  static const _stagger = Duration(milliseconds: 150);

  final Map<AnimeListType, ValueNotifier<HomeSectionState>> _sections = {
    for (final type in [carouselType, ...rowTypes])
      type: ValueNotifier(const HomeSectionState()),
  };

  /// What a section's widget listens to, so only that section rebuilds.
  ValueListenable<HomeSectionState> listenableOf(AnimeListType type) =>
      _sections[type]!;

  /// Infinite vertical list at the bottom of the screen.
  final PagedAnime topRated = PagedAnime(AnimeListType.topRated.fetch);

  HomeSectionState stateOf(AnimeListType type) => _sections[type]!.value;

  /// Sets a section's state. Deferred to after the frame if called mid-build.
  void _set(AnimeListType type, HomeSectionState state) {
    if (isDisposed) return;
    final notifier = _sections[type]!;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed) notifier.value = state;
      });
    } else {
      notifier.value = state;
    }
  }

  Future<void> load() {
    final jobs = <Future<void>>[
      // Carousel first, immediately: it's the only thing above the fold.
      _loadSection(carouselType),
      // Rows follow one after another, in display order.
      for (var i = 0; i < rowTypes.length; i++)
        _startAfter(_stagger * (i + 1), () => _loadSection(rowTypes[i])),
      // Top rated is furthest down, so it goes last.
      _startAfter(_stagger * (rowTypes.length + 1), topRated.loadNext),
    ];
    return Future.wait(jobs);
  }

  Future<void> _startAfter(Duration delay, Future<void> Function() job) async {
    await Future<void>.delayed(delay);
    if (isDisposed) return;
    await job();
  }

  /// Pull-to-refresh. Everything cached is treated as out of date, so each
  /// section refetches. Existing content stays on screen until new data
  /// lands, and is kept if the refresh fails.
  Future<void> refresh() {
    ApiCache.instance.invalidate();
    return Future.wait([
      for (final type in _sections.keys) _loadSection(type, silent: true),
      topRated.refresh(),
    ]);
  }

  Future<void> retry(AnimeListType type) => _loadSection(type);

  Future<void> _loadSection(AnimeListType type, {bool silent = false}) async {
    if (!silent) _set(type, const HomeSectionState());

    try {
      final perPage = type == carouselType ? _carouselCount : _rowCount;

      await for (final page in type.watch(1, perPage)) {
        if (isDisposed) return;
        _set(
          type,
          HomeSectionState(
            status: SectionStatus.ready,
            items: page.items.map(AnimeMedia.fromJson).toList(growable: false),
          ),
        );
      }
    } catch (e, st) {
      if (isDisposed) return;
      log.e('Failed to load ${type.title}', error: e, stackTrace: st);
      if (silent && stateOf(type).items.isNotEmpty) return;
      _set(type, HomeSectionState(status: SectionStatus.error, error: e));
    }
  }

  @override
  void dispose() {
    topRated.dispose();
    super.dispose(); // sets isDisposed first
    for (final notifier in _sections.values) {
      notifier.dispose();
    }
  }
}
