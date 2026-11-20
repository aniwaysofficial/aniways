import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/scroll/app_scroll.dart';
import 'package:aniways/core/services/blurred_cover_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/navigation/main_navigation.dart'
    show navBarClearance, pushFullScreen;
import 'package:aniways/screens/search/search_components.dart';
import 'package:aniways/screens/search/search_filter.dart';
import 'package:aniways/screens/search/search_results_screen.dart';
import 'package:aniways/screens/search/season_category.dart';

const double _kBarHeight = 52;
const double _kBarVPad = 8;

/// Dedicated Discover screen shown in the Search tab while idle.
/// Displays a tappable search bar trigger, recent searches, trending titles,
/// browse collections, and seasonal anime categories.
///
/// Tapping the search bar, a browse card, or a season card pushes [SearchResultsScreen]
/// above the shell. Pressing Back smoothly returns to this screen without tab ping-pong.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialFilter,
    this.initialGenre,
    this.initialTargetIndex,
  });

  final AnimeSearchFilter? initialFilter;
  final String? initialGenre;
  final int? initialTargetIndex;

  /// Global notifier to apply filters to Search and open [SearchResultsScreen].
  static final ValueNotifier<AnimeSearchFilter?> filterNotifier =
      ValueNotifier<AnimeSearchFilter?>(null);

  /// Global notifier to scroll to a specific index in Search results.
  static final ValueNotifier<int?> targetIndexNotifier = ValueNotifier<int?>(
    null,
  );

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController _scroll = ScrollController();

  List<String> _recentSearches = [];
  List<_TrendingItem> _trending = const [];
  bool _isLoadingTrending = true;

  Map<String, String> _browseCovers = const {};
  Map<String, String> _seasonCovers = const {};

  late final List<SeasonCategory> _allSeasons;
  late final List<int> _seasonYears;
  int? _selectedSeasonYear;

  @override
  void initState() {
    super.initState();
    _allSeasons = generateSeasonCategories();
    _seasonYears = _allSeasons.map((s) => s.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    _recentSearches = SharedPreferencesService().recentSearches;
    SearchScreen.filterNotifier.addListener(_onExternalFilter);
    SearchScreen.targetIndexNotifier.addListener(_onExternalTargetIndex);

    _loadTrending();
    _loadBrowseCovers();
    _loadSeasonCovers();

    final initialFilter =
        widget.initialFilter ??
        (widget.initialGenre != null
            ? AnimeSearchFilter(genre: widget.initialGenre)
            : null) ??
        SearchScreen.filterNotifier.value;
    final initialTargetIndex =
        widget.initialTargetIndex ?? SearchScreen.targetIndexNotifier.value;

    SearchScreen.filterNotifier.value = null;
    SearchScreen.targetIndexNotifier.value = null;

    if (initialFilter != null ||
        (initialTargetIndex != null && initialTargetIndex > 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToResults(
            filter: initialFilter,
            targetIndex: initialTargetIndex,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    SearchScreen.filterNotifier.removeListener(_onExternalFilter);
    SearchScreen.targetIndexNotifier.removeListener(_onExternalTargetIndex);
    _scroll.dispose();
    super.dispose();
  }

  void _onExternalFilter() {
    final requested = SearchScreen.filterNotifier.value;
    if (requested == null || !mounted) return;
    SearchScreen.filterNotifier.value = null;
    final targetIndex = SearchScreen.targetIndexNotifier.value;
    SearchScreen.targetIndexNotifier.value = null;

    _navigateToResults(filter: requested, targetIndex: targetIndex);
  }

  void _onExternalTargetIndex() {
    final requested = SearchScreen.targetIndexNotifier.value;
    if (requested == null || !mounted) return;
    SearchScreen.targetIndexNotifier.value = null;

    _navigateToResults(targetIndex: requested);
  }

  Future<void> _navigateToResults({
    String? query,
    AnimeSearchFilter? filter,
    int? targetIndex,
    bool autoFocus = false,
    bool openFilters = false,
    bool fade = false,
  }) async {
    await pushFullScreen(
      context,
      SearchResultsScreen(
        initialQuery: query,
        initialFilter: filter,
        initialTargetIndex: targetIndex,
        autoFocus: autoFocus,
        openFilters: openFilters,
      ),
      fade: fade,
    );
    if (mounted) {
      _refreshRecent();
    }
  }

  // ── Data loading ───────────────────────────────────────────────────

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadTrending(),
      _loadBrowseCovers(),
      _loadSeasonCovers(),
    ]);
  }

  Future<void> _loadTrending() async {
    try {
      final page = await anilistService.trending(perPage: 12);
      final seenQueries = <String>{};
      final items = <_TrendingItem>[];
      for (final m in page.items) {
        final item = _trendingItemOf(m);
        if (item != null && seenQueries.add(item.query)) {
          items.add(item);
          if (items.length >= 12) break;
        }
      }
      if (!mounted) return;
      setState(() {
        _trending = items;
        _isLoadingTrending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trending = const [];
        _isLoadingTrending = false;
      });
    }
  }

  _TrendingItem? _trendingItemOf(Map<String, dynamic> media) {
    final t = media['title'];
    if (t is! Map) return null;
    final fullTitle = ((t['english'] ?? t['romaji']) as String?)?.trim();
    if (fullTitle == null || fullTitle.isEmpty) return null;

    String display = fullTitle;
    if (fullTitle.length > 28) {
      final colonIndex = fullTitle.indexOf(':');
      if (colonIndex > 3 && colonIndex <= 28) {
        display = fullTitle.substring(0, colonIndex).trim();
      }
    }

    return _TrendingItem(display: display, query: fullTitle);
  }

  Future<void> _loadBrowseCovers() async {
    try {
      final covers = await anilistService.browseCovers();
      if (!mounted) return;
      setState(() {
        _browseCovers = covers;
      });
      // Pre-warm the disk-cached blurred textures
      for (final url in covers.values) {
        if (url.isNotEmpty) {
          BlurredCoverService.instance.getOrBlur(url);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSeasonCovers() async {
    try {
      final req = _allSeasons
          .map((s) => (season: s.season.value, year: s.year))
          .toList(growable: false);
      final covers = await anilistService.seasonCovers(req);
      if (!mounted) return;
      setState(() {
        _seasonCovers = covers;
      });
      // Pre-warm the disk-cached blurred textures so scrolling season categories is instant
      for (final url in covers.values) {
        if (url.isNotEmpty) {
          BlurredCoverService.instance.getOrBlur(url);
        }
      }
    } catch (_) {}
  }

  // ── Recent Searches ─────────────────────────────────────────────────

  void _refreshRecent() {
    if (!mounted) return;
    setState(() => _recentSearches = SharedPreferencesService().recentSearches);
  }

  Future<void> _removeRecent(String query) async {
    await SharedPreferencesService().removeRecentSearch(query);
    _refreshRecent();
  }

  Future<void> _clearAllRecent() async {
    await SharedPreferencesService().clearRecentSearches();
    _refreshRecent();
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = navBarClearance(context);
    final inset = pageInset(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AppScrollPhysics(),
          scrollCacheExtent: const ScrollCacheExtent.pixels(800),
          slivers: [
            // One UI Header with Pinned Search Bar Trigger
            OneUiSliverHeader(
              title: 'Search',
              showBackButton: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(
                  _kBarHeight + _kBarVPad * 2,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(inset, 0, inset, _kBarVPad * 2),
                  child: _buildSearchBar(context, cs),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Recent Searches
            if (_recentSearches.isNotEmpty) ...[
              _buildRecentSearches(context, inset),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // Trending Now
            _buildTrending(context, inset),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Browse
            _buildBrowseCategories(context, inset),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Seasons
            _buildSeasons(context, inset, bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context, double inset) {
    final cs = Theme.of(context).colorScheme;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _SectionTitle(
              icon: Icons.history_rounded,
              iconColor: cs.onSurfaceVariant,
              title: 'Recent Searches',
              trailing: TextButton(
                onPressed: _clearAllRecent,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: cs.onSurfaceVariant,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Clear all'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in _recentSearches)
                  _SuggestionChip(
                    label: term,
                    icon: Icons.history_rounded,
                    onTap: () => _navigateToResults(query: term),
                    onDelete: () => _removeRecent(term),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrending(BuildContext context, double inset) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: const _SectionTitle(
              icon: Icons.local_fire_department_rounded,
              iconColor: Color(0xFFFF7043),
              title: 'Trending Now',
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (_isLoadingTrending)
          _buildTrendingSkeletons(inset)
        else if (_trending.isNotEmpty)
          _buildTrendingChips(inset)
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: Text(
                'No trending anime available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrendingChips(double inset) {
    final half = (_trending.length / 2).ceil();
    final row1 = _trending.take(half).toList(growable: false);
    final row2 = _trending.skip(half).toList(growable: false);

    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AppScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < row1.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _SuggestionChip(
                    label: row1[i].display,
                    icon: Icons.trending_up_rounded,
                    onTap: () => _navigateToResults(query: row1[i].query),
                  ),
                ],
              ],
            ),
            if (row2.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < row2.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _SuggestionChip(
                      label: row2[i].display,
                      icon: Icons.trending_up_rounded,
                      onTap: () => _navigateToResults(query: row2[i].query),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSkeletons(double inset) {
    const row1Widths = [115.0, 135.0, 95.0, 120.0];
    const row2Widths = [125.0, 90.0, 130.0, 105.0];

    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AppScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < row1Widths.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Skeleton(width: row1Widths[i], height: 32, radius: 16),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < row2Widths.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Skeleton(width: row2Widths[i], height: 32, radius: 16),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseCategories(BuildContext context, double inset) {
    final width = context.contentWidth - inset * 2;
    final categoryColumns = width > 500 ? 4 : 2;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: SliverMainAxisGroup(
        slivers: [
          const SliverToBoxAdapter(
            child: _SectionTitle(
              icon: Icons.explore_rounded,
              iconColor: Color(0xFF26A69A),
              title: 'Browse',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: categoryColumns,
              mainAxisExtent: 112,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildListDelegate([
              _QuickCategoryCard(
                title: 'TV Series',
                subtitle: 'Top episodes',
                icon: Icons.tv_rounded,
                accentColor: const Color(0xFF42A5F5),
                coverUrl: _browseCovers['tv'],
                onTap: () => _navigateToResults(
                  filter: const AnimeSearchFilter(format: AnimeFormat.tv),
                ),
              ),
              _QuickCategoryCard(
                title: 'Movies',
                subtitle: 'Feature films',
                icon: Icons.movie_rounded,
                accentColor: const Color(0xFFAB47BC),
                coverUrl: _browseCovers['movie'],
                onTap: () => _navigateToResults(
                  filter: const AnimeSearchFilter(format: AnimeFormat.movie),
                ),
              ),
              _QuickCategoryCard(
                title: 'Airing Now',
                subtitle: 'This season',
                icon: Icons.sensors_rounded,
                accentColor: const Color(0xFF26A69A),
                coverUrl: _browseCovers['airing'],
                onTap: () => _navigateToResults(
                  filter: const AnimeSearchFilter(
                    status: AnimeStatus.releasing,
                  ),
                ),
              ),
              _QuickCategoryCard(
                title: 'Top Rated',
                subtitle: 'All-time best',
                icon: Icons.star_rounded,
                accentColor: const Color(0xFFFFA726),
                coverUrl: _browseCovers['topRated'],
                onTap: () => _navigateToResults(
                  filter: const AnimeSearchFilter(sort: AnimeSort.score),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasons(BuildContext context, double inset, double bottomInset) {
    final cs = Theme.of(context).colorScheme;
    final width = context.contentWidth - inset * 2;
    final categoryColumns = width > 500 ? 4 : 2;

    final visibleSeasons = _selectedSeasonYear == null
        ? _allSeasons
        : _allSeasons
              .where((s) => s.year == _selectedSeasonYear)
              .toList(growable: false);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: _SectionTitle(
              icon: Icons.calendar_month_rounded,
              iconColor: cs.primary,
              title: 'Seasons',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AppScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: Row(
                children: [
                  _SeasonYearChip(
                    label: 'All',
                    selected: _selectedSeasonYear == null,
                    onTap: () {
                      if (_selectedSeasonYear != null) {
                        setState(() => _selectedSeasonYear = null);
                      }
                    },
                  ),
                  for (final year in _seasonYears) ...[
                    const SizedBox(width: 8),
                    _SeasonYearChip(
                      label: '$year',
                      selected: _selectedSeasonYear == year,
                      onTap: () {
                        setState(() {
                          _selectedSeasonYear = _selectedSeasonYear == year
                              ? null
                              : year;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(inset, 0, inset, bottomInset),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: categoryColumns,
              mainAxisExtent: 112,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = visibleSeasons[index];
              return _QuickCategoryCard(
                key: ValueKey(item.key),
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
                accentColor: item.accentColor,
                coverUrl: _seasonCovers[item.key],
                onTap: () => _navigateToResults(
                  filter: AnimeSearchFilter(
                    season: item.season,
                    year: item.year,
                    sort: AnimeSort.popularity,
                  ),
                ),
              );
            }, childCount: visibleSeasons.length),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme cs) {
    return Hero(
      tag: kSearchBarHeroTag,
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            return SearchBarFlightShuttle(
              animation: animation,
              flightDirection: flightDirection,
              initialQuery: null,
            );
          },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToResults(autoFocus: true, fade: true),
          borderRadius: BorderRadius.circular(_kBarHeight / 2),
          child: Container(
            height: _kBarHeight,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(_kBarHeight / 2),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search anime…',
                    style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Filters',
                  child: IconButton(
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => _navigateToResults(
                      autoFocus: false,
                      openFilters: true,
                      fade: true,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingItem {
  const _TrendingItem({required this.display, required this.query});

  final String display;
  final String query;
}

// ═════════════════════════════════════════════════════════════════════════
// Shared UI Components
// ═════════════════════════════════════════════════════════════════════════

typedef _SectionTitle = SearchSectionTitle;
typedef _SuggestionChip = SearchSuggestionChip;

class _SeasonYearChip extends StatelessWidget {
  const _SeasonYearChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.16)
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? cs.primary : cs.onSurface,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCategoryCard extends StatelessWidget {
  const _QuickCategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.coverUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final activeUrl = coverUrl;

    final baseColor = isDark
        ? const Color(0xFF1C1C20)
        : cs.surfaceContainerHighest;
    final textColor = isDark ? Colors.white : cs.onSurface;
    final chevronColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : cs.onSurface.withValues(alpha: 0.60);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : cs.outlineVariant.withValues(alpha: 0.35);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : cs.onSurfaceVariant;
    final badgeBg = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.75);
    final badgeBorder = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.08);
    final badgeIconColor = isDark ? Colors.white : cs.onSurface;

    final scrimColors = isDark
        ? [
            Colors.black.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.70),
            Colors.black.withValues(alpha: 0.90),
          ]
        : [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.88),
          ];
    const scrimStops = [0.0, 0.40, 0.75, 1.0];

    return RepaintBoundary(
      child: Material(
        color: baseColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Pre-Blurred Cover Background (Disk-Cached, 0 GPU Shaders) ──
              Positioned.fill(
                child: BlurredCardCover(
                  url: activeUrl,
                  fallback: ColoredBox(
                    color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  ),
                ),
              ),

              // ── Scrim Vignette ──
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: scrimStops,
                      colors: scrimColors,
                    ),
                  ),
                ),
              ),

              // ── Content ──
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Subtle Glass Icon Badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: badgeBorder, width: 1),
                      ),
                      child: Icon(icon, size: 17, color: badgeIconColor),
                    ),

                    // Bottom Row: Category Title, Subtitle & Chevron
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: chevronColor,
                        ),
                      ],
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
}
