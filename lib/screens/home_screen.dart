import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:aniways/core/network/anilist_service.dart' show AnilistService;
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/navigation/main_navigation.dart'
    show MainNavigation, navBarClearance, pushFullScreen;
import 'package:aniways/providers/anime_lists.dart';
import 'package:aniways/providers/home_provider.dart';
import 'package:aniways/screens/home/browse_shortcuts.dart';
import 'package:aniways/screens/home/continue_watching_section.dart';
import 'package:aniways/screens/home/featured_carousel.dart';
import 'package:aniways/screens/home/genres_screen.dart';
import 'package:aniways/screens/home/home_section.dart';
import 'package:aniways/screens/home/recommended_section.dart';
import 'package:aniways/screens/home/schedule_screen.dart';
import 'package:aniways/screens/home/top_rated_tile.dart';
import 'package:aniways/screens/search/search_filter.dart';

/// Home screen: trending carousel, horizontal rows (each with "View all"),
/// then an infinitely scrolling top-rated list.
///
/// The scroll view is built once. Every section listens to its own state, so
/// when one section's data lands only that section rebuilds.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeProvider _home = HomeProvider();
  final GlobalKey<RecommendedSectionState> _recommendedKey =
      GlobalKey<RecommendedSectionState>();

  @override
  void initState() {
    super.initState();
    _home.load();
  }

  @override
  void dispose() {
    _home.dispose();
    super.dispose();
  }

  /// Load the next top-rated page when the user nears the bottom.
  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 &&
        n.metrics.axis == Axis.vertical &&
        n.metrics.extentAfter < 500 &&
        !_home.topRated.isLoading &&
        _home.topRated.hasMore) {
      _home.topRated.loadNext();
    }
    return false;
  }

  AnimeSearchFilter _filterFor(AnimeListType type) {
    switch (type) {
      case AnimeListType.trendingAiring:
        return const AnimeSearchFilter(
          sort: AnimeSort.trending,
          status: AnimeStatus.releasing,
        );
      case AnimeListType.currentSeason:
        final (seasonStr, year) = AnilistService.seasonFor(DateTime.now());
        final season =
            AnimeSeason.values.where((s) => s.value == seasonStr).firstOrNull;
        return AnimeSearchFilter(
          sort: AnimeSort.popularity,
          season: season,
          year: year,
        );
      case AnimeListType.recentlyReleased:
        return const AnimeSearchFilter(
          sort: AnimeSort.startDate,
          status: AnimeStatus.releasing,
        );
      case AnimeListType.trending:
        return const AnimeSearchFilter(
          sort: AnimeSort.trending,
        );
      case AnimeListType.popular:
        return const AnimeSearchFilter(
          sort: AnimeSort.popularity,
        );
      case AnimeListType.upcoming:
        return const AnimeSearchFilter(
          sort: AnimeSort.popularity,
          status: AnimeStatus.notYetReleased,
        );
      case AnimeListType.topRated:
        return const AnimeSearchFilter(
          sort: AnimeSort.score,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = context.hasSideNav;
    final railOffset = isWide ? 84.0 : 0.0;

    // Top rated: a grid of fixed-height tiles; 1 column on phones, more as
    // the page area gets wider. Content is centred up to kMaxContentWidth.
    final inset = pageInset(context);
    final columns = gridColumns(
      context.contentWidth - inset * 2,
      minTileWidth: 320,
      maxColumns: 3,
    );
    final tileGrid = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisExtent: topRatedTileExtent(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 0,
    );

    final rowColors = {
      AnimeListType.currentSeason: cs.primary,
      AnimeListType.recentlyReleased: cs.tertiary,
      AnimeListType.trending: cs.secondary,
      AnimeListType.popular: cs.primary,
      AnimeListType.upcoming: cs.tertiary,
    };

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _home.refresh(),
            if (_recommendedKey.currentState != null)
              _recommendedKey.currentState!.reload(),
          ]);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            scrollCacheExtent: const ScrollCacheExtent.pixels(500),
            slivers: [
              // ── Carousel (full-bleed, starts under the status bar) ─────
              SliverToBoxAdapter(
                child: ValueListenableBuilder<HomeSectionState>(
                  valueListenable: _home.listenableOf(
                    HomeProvider.carouselType,
                  ),
                  builder: (context, state, _) => FeaturedCarousel(
                    state: state,
                    onRetry: () => _home.retry(HomeProvider.carouselType),
                  ),
                ),
              ),

              // ── Content below carousel (indented for side rail on wide layouts) ──
              SliverPadding(
                padding: EdgeInsets.only(left: railOffset),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 28),
                        child: BrowseShortcuts(
                          onGenres: () =>
                              pushFullScreen(context, const GenresScreen()),
                          onSchedule: () =>
                              pushFullScreen(context, const ScheduleScreen()),
                        ),
                      ),
                    ),

                    // ── Continue Watching ───────────────────────────────
                    const SliverToBoxAdapter(
                      child: ContinueWatchingSection(),
                    ),

                    // ── Personalized Recommendations ──
                    SliverToBoxAdapter(
                      child: RecommendedSection(key: _recommendedKey),
                    ),

                    // ── Horizontal rows ─────────────────────────────────
                    for (final type in HomeProvider.rowTypes)
                      SliverToBoxAdapter(
                        child: ValueListenableBuilder<HomeSectionState>(
                          valueListenable: _home.listenableOf(type),
                          builder: (context, state, _) => HomeSection(
                            type: type,
                            state: state,
                            color: rowColors[type]!,
                            onRetry: () => _home.retry(type),
                            onViewAll: (index) => MainNavigation.switchToSearch(
                              context,
                              filter: _filterFor(type),
                              targetIndex: index,
                            ),
                          ),
                        ),
                      ),

                    // ── Top rated (vertical, infinite) ──────────────────
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: AnimeListType.topRated.title,
                        icon: AnimeListType.topRated.icon,
                        color: cs.secondary,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    ListenableBuilder(
                      listenable: _home.topRated,
                      builder: (context, _) =>
                          _topRatedSliver(_home.topRated, inset, columns, tileGrid),
                    ),

                    SliverToBoxAdapter(
                      child: ListenableBuilder(
                        listenable: _home.topRated,
                        builder: (context, _) => PagedFooter(
                          paged: _home.topRated,
                          showLoading: false,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: navBarClearance(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topRatedSliver(
    PagedAnime top,
    double inset,
    int columns,
    SliverGridDelegate tileGrid,
  ) {
    final items = top.items;

    if (items.isEmpty && !top.hasError) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        sliver: SliverGrid.builder(
          gridDelegate: tileGrid,
          itemCount: columns * 4,
          itemBuilder: (context, index) => const TopRatedTileSkeleton(),
        ),
      );
    }

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: ErrorCard(
            message: describeError(top.error),
            onRetry: top.retry,
          ),
        ),
      );
    }

    final extraCount = top.isLoading ? columns * 2 : 0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: SliverGrid.builder(
        gridDelegate: tileGrid,
        itemCount: items.length + extraCount,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, index) {
          if (index < items.length) {
            return TopRatedTile(
              key: ValueKey(items[index].id),
              anime: items[index],
              rank: index + 1,
            );
          }
          return const TopRatedTileSkeleton();
        },
      ),
    );
  }
}
