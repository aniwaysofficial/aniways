import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/scroll/app_scroll.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/providers/anime_lists.dart';
import 'package:aniways/screens/search/search_components.dart';
import 'package:aniways/screens/search/search_filter.dart';
import 'package:aniways/screens/search/search_filter_sheet.dart';

const double _kBarHeight = 52;
const double _kBarVPad = 8;
const double _kChipsExtent = 48;
const double _crossSpacing = 14.0;
const String kSearchBarHeroTag = 'discover_search_bar_hero';

/// Dedicated Active Search & Results screen.
/// Pushed on top of the discover view when user taps the search bar, a browse card,
/// a season card, or a search term.
///
/// Pressing Back (←) smoothly pops this screen and returns to the discover view.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    this.initialQuery,
    this.initialFilter,
    this.initialTargetIndex,
    this.autoFocus = false,
    this.openFilters = false,
  });

  final String? initialQuery;
  final AnimeSearchFilter? initialFilter;
  final int? initialTargetIndex;
  final bool autoFocus;
  final bool openFilters;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scroll = ScrollController();

  late AnimeSearchFilter _filter;
  PagedAnime? _paged;
  Timer? _debounceTimer;
  String? _activeKey;
  int? _targetScrollIndex;

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _targetScrollIndex = widget.initialTargetIndex;
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _filter = widget.initialFilter ?? AnimeSearchFilter.empty;
    _recentSearches = SharedPreferencesService().recentSearches;

    _searchController.addListener(_onSearchInputChanged);

    if (_searchController.text.isNotEmpty || !_filter.isDefault) {
      final query = _searchController.text.trim();
      final filter = _filter;
      _activeKey = '$query|${filter.hashCode}';
      final paged = PagedAnime(
        (page, perPage) => anilistService.search(
          query.isNotEmpty ? query : null,
          page: page,
          perPage: perPage,
          sort: filter.sort?.value,
          format: filter.format?.value,
          status: filter.status?.value,
          genre: filter.genre,
          season: filter.season?.value,
          year: filter.year,
          isAdult: filter.adultFilter?.isAdult,
        ),
        perPage: 24,
      );
      paged.addListener(_onPagedUpdated);
      _paged = paged;
      paged.loadNext();
    }

    if (widget.openFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFilterSheet();
      });
    }
  }

  @override
  void dispose() {
    _paged?.removeListener(_onPagedUpdated);
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scroll.dispose();
    _paged?.dispose();
    super.dispose();
  }

  // ── Recent Searches ──────────────────────────────────────────────────

  void _refreshRecent() {
    if (!mounted) return;
    setState(() => _recentSearches = SharedPreferencesService().recentSearches);
  }

  Future<void> _addRecent(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await SharedPreferencesService().addRecentSearch(trimmed);
    _refreshRecent();
  }

  Future<void> _removeRecent(String query) async {
    await SharedPreferencesService().removeRecentSearch(query);
    _refreshRecent();
  }

  Future<void> _clearAllRecent() async {
    await SharedPreferencesService().clearRecentSearches();
    _refreshRecent();
  }

  // ── Search Flow ──────────────────────────────────────────────────────

  void _onSearchInputChanged() {
    _debounceTimer?.cancel();
    final text = _searchController.text.trim();

    if (text.isEmpty && _filter.isDefault) {
      setState(() {
        _activeKey = null;
        _paged?.dispose();
        _paged = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 380), () {
      if (mounted) _executeSearch();
    });
  }

  void _onSearchSubmitted(String value) {
    _debounceTimer?.cancel();
    final text = value.trim();
    if (text.isNotEmpty) _addRecent(text);
    _searchFocusNode.unfocus();
    _executeSearch();
  }

  void _executeSearch() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty && _filter.isDefault) {
      setState(() {
        _activeKey = null;
        _paged?.dispose();
        _paged = null;
      });
      return;
    }

    final key = '$query|${_filter.hashCode}';
    if (key == _activeKey && _paged != null) {
      if (_targetScrollIndex != null &&
          _paged!.items.isNotEmpty &&
          !_paged!.isInitialLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToTargetIndex();
        });
      }
      return;
    }
    _activeKey = key;

    final filter = _filter;
    final old = _paged;
    if (old != null) {
      old.removeListener(_onPagedUpdated);
    }

    final paged = PagedAnime(
      (page, perPage) => anilistService.search(
        query.isNotEmpty ? query : null,
        page: page,
        perPage: perPage,
        sort: filter.sort?.value,
        format: filter.format?.value,
        status: filter.status?.value,
        genre: filter.genre,
        season: filter.season?.value,
        year: filter.year,
        isAdult: filter.adultFilter?.isAdult,
      ),
      perPage: 24,
    );
    paged.addListener(_onPagedUpdated);

    setState(() {
      _paged = paged;
    });

    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }

    if (_scroll.hasClients) _scroll.jumpTo(0);
    paged.loadNext();
  }

  void _onPagedUpdated() {
    if (!mounted || _targetScrollIndex == null) return;
    final paged = _paged;
    if (paged == null) return;

    if (paged.hasError || (!paged.isLoading && paged.items.isEmpty)) {
      _targetScrollIndex = null;
      return;
    }

    if (!paged.isInitialLoading && paged.items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTargetIndex();
      });
    }
  }

  void _scrollToTargetIndex() {
    final target = _targetScrollIndex;
    _targetScrollIndex = null;
    if (target == null || target <= 0 || !mounted || !_scroll.hasClients) return;

    final paged = _paged;
    if (paged == null || paged.items.isEmpty) return;

    final clampedTarget = target.clamp(0, paged.items.length - 1);
    if (clampedTarget <= 0) return;

    final inset = pageInset(context);
    final gridWidth = context.contentWidth - inset * 2;
    final columns = context.layoutSize.isCompact
        ? 2
        : gridColumns(
            gridWidth,
            minTileWidth: 170,
            maxColumns: 7,
            spacing: _crossSpacing,
          );
    final cardWidth = (gridWidth - _crossSpacing * (columns - 1)) / columns;
    final cellHeight = cardWidth / kPosterAspect + animeCardTextHeight(context);
    const mainSpacing = 20.0;
    final rowStride = cellHeight + mainSpacing;
    final targetRow = clampedTarget ~/ columns;

    final targetOffset = targetRow * rowStride;
    if (targetOffset <= 0) return;

    _scroll.animateTo(
      targetOffset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _setFilter(AnimeSearchFilter newFilter) {
    setState(() => _filter = newFilter);
    _executeSearch();
  }

  Future<void> _openFilterSheet() async {
    _searchFocusNode.unfocus();
    final result = await showSearchFilterSheet(context, initialFilter: _filter);
    if (result != null && result != _filter) _setFilter(result);
  }

  void _selectSearchTerm(String term) {
    _debounceTimer?.cancel();
    _searchController.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    _addRecent(term);
    _searchFocusNode.unfocus();
    _executeSearch();
  }

  void _clearSearchText() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.extentAfter < 700) {
      _paged?.loadNext();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mq = MediaQuery.of(context);
    final bottomInset = mq.padding.bottom + 24;
    final inset = pageInset(context);

    final showRecentOnly = _paged == null &&
        _searchController.text.trim().isEmpty &&
        _filter.isDefault;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(_kBarHeight + _kBarVPad * 2),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                inset,
                _kBarVPad,
                inset,
                _kBarVPad,
              ),
              child: Hero(
                tag: kSearchBarHeroTag,
                flightShuttleBuilder: (
                  flightContext,
                  animation,
                  flightDirection,
                  fromHeroContext,
                  toHeroContext,
                ) {
                  return SearchBarFlightShuttle(
                    animation: animation,
                    flightDirection: flightDirection,
                    initialQuery: widget.initialQuery,
                  );
                },
                child: _ResultsSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: widget.autoFocus,
                  activeFilterCount: _filter.activeFilterCount,
                  onSubmitted: _onSearchSubmitted,
                  onClear: _clearSearchText,
                  onOpenFilters: _openFilterSheet,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: RefreshIndicator(
          onRefresh: () async => _paged?.refresh(),
          notificationPredicate: (n) => !showRecentOnly && n.depth == 0,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AppScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // Pinned Filter Chips bar
                if (!showRecentOnly)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _FilterChipsDelegate(
                      inset: inset,
                      cs: cs,
                      filter: _filter,
                      onOpenFilters: _openFilterSheet,
                      onChanged: _setFilter,
                    ),
                  ),

                // Content
                if (showRecentOnly)
                  _buildRecentSearches(context, inset, bottomInset)
                else
                  _buildResultsGrid(context, inset, bottomInset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Recent Searches (when query is empty) ───────────────────────────

  Widget _buildRecentSearches(
    BuildContext context,
    double inset,
    double bottomInset,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (_recentSearches.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(inset, 60, inset, bottomInset),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 54,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 14),
                Text(
                  'Type a query or apply a filter to search',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(inset, 12, inset, bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in _recentSearches)
                  _SuggestionChip(
                    label: term,
                    icon: Icons.history_rounded,
                    onTap: () => _selectSearchTerm(term),
                    onDelete: () => _removeRecent(term),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Results Grid ─────────────────────────────────────────────────────

  Widget _buildResultsGrid(
    BuildContext context,
    double inset,
    double bottomInset,
  ) {
    final paged = _paged;
    if (paged == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final gridWidth = context.contentWidth - inset * 2;
    final columns = context.layoutSize.isCompact
        ? 2
        : gridColumns(
            gridWidth,
            minTileWidth: 170,
            maxColumns: 7,
            spacing: _crossSpacing,
          );
    final cardWidth = (gridWidth - _crossSpacing * (columns - 1)) / columns;
    final cellHeight = cardWidth / kPosterAspect + animeCardTextHeight(context);

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisExtent: cellHeight,
      crossAxisSpacing: _crossSpacing,
      mainAxisSpacing: 20,
    );

    return ListenableBuilder(
      listenable: paged,
      builder: (context, _) {
        final items = paged.items;
        final isInitial = paged.isInitialLoading;
        final hasError = paged.hasError;

        if (isInitial && items.isEmpty && !hasError) {
          return SliverPadding(
            padding: EdgeInsets.fromLTRB(inset, 12, inset, bottomInset),
            sliver: SliverGrid.builder(
              gridDelegate: gridDelegate,
              itemCount: 12,
              itemBuilder: (_, _) => const AnimeCardSkeleton(),
            ),
          );
        }

        if (hasError && items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(inset, 28, inset, bottomInset),
              child: ErrorCard(
                message: describeError(paged.error),
                onRetry: paged.retry,
              ),
            ),
          );
        }

        if (!isInitial && items.isEmpty && !hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(inset, 40, inset, bottomInset),
              child: _buildEmptyState(context),
            ),
          );
        }

        final cs = Theme.of(context).colorScheme;
        final query = _searchController.text.trim();

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(inset, 4, inset, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        query.isNotEmpty
                            ? 'Results for "$query"'
                            : 'Filtered results',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${items.length} shows',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              sliver: SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemCount: items.length,
                itemBuilder: (_, i) => Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) {
                    if (_searchFocusNode.hasFocus) {
                      _searchFocusNode.unfocus();
                    }
                  },
                  child: AnimeCard(
                    anime: items[i],
                    heroPrefix: 'search-results',
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: PagedFooter(paged: paged)),
            SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final query = _searchController.text.trim();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 36,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No results found',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? 'Nothing matches "$query". Check the spelling or try removing some filters.'
                  : 'No anime matches all the selected filters. Try broadening them.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!_filter.isDefault)
                  FilledButton.tonal(
                    onPressed: () => _setFilter(AnimeSearchFilter.empty),
                    child: const Text('Reset filters'),
                  ),
                if (query.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: _clearSearchText,
                    child: const Text('Clear search'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// App Bar: Active Search Bar with Back Button
// ═════════════════════════════════════════════════════════════════════════

class _ResultsSearchBar extends StatelessWidget {
  const _ResultsSearchBar({
    required this.controller,
    required this.focusNode,
    required this.activeFilterCount,
    required this.onSubmitted,
    required this.onClear,
    required this.onOpenFilters,
    required this.onBack,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int activeFilterCount;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onOpenFilters;
  final VoidCallback onBack;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _kBarHeight,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(_kBarHeight / 2),
            border: Border.all(
              color: focused
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                color: cs.onSurface,
                onPressed: onBack,
                tooltip: 'Back to discover',
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search anime…',
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: cs.onSurfaceVariant,
                  onPressed: onClear,
                  tooltip: 'Clear query',
                  visualDensity: VisualDensity.compact,
                ),
              Tooltip(
                message: 'Filters',
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      color: activeFilterCount > 0
                          ? cs.primary
                          : cs.onSurfaceVariant,
                      onPressed: onOpenFilters,
                      visualDensity: VisualDensity.compact,
                    ),
                    if (activeFilterCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$activeFilterCount',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        );
      },
    );
  }
}

/// Flight shuttle widget for animating the search bar between Discover and Results.
class SearchBarFlightShuttle extends StatelessWidget {
  const SearchBarFlightShuttle({
    super.key,
    required this.animation,
    required this.flightDirection,
    this.initialQuery,
  });

  final Animation<double> animation;
  final HeroFlightDirection flightDirection;
  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final isPush = flightDirection == HeroFlightDirection.push;
          final progress = isPush ? t : 1.0 - t;

          return Container(
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
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: (1.0 - progress * 2.0).clamp(0.0, 1.0),
                        child: Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Opacity(
                        opacity: ((progress - 0.5) * 2.0).clamp(0.0, 1.0),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (initialQuery != null && initialQuery!.isNotEmpty)
                        ? initialQuery!
                        : 'Search anime…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: (initialQuery != null && initialQuery!.isNotEmpty)
                          ? cs.onSurface
                          : cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Pinned Header: Filter Pills
// ═════════════════════════════════════════════════════════════════════════

class _FilterChipsDelegate extends SliverPersistentHeaderDelegate {
  _FilterChipsDelegate({
    required this.inset,
    required this.cs,
    required this.filter,
    required this.onOpenFilters,
    required this.onChanged,
  });

  final double inset;
  final ColorScheme cs;
  final AnimeSearchFilter filter;
  final VoidCallback onOpenFilters;
  final ValueChanged<AnimeSearchFilter> onChanged;

  @override
  double get minExtent => _kChipsExtent;

  @override
  double get maxExtent => _kChipsExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: ColoredBox(
        color: cs.surface,
        child: Center(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: inset),
              children: [
                _FilterPill(
                  label: 'Filter',
                  icon: Icons.tune_rounded,
                  active: filter.activeFilterCount > 0,
                  onTap: onOpenFilters,
                ),
                _FilterPill(
                  label: filter.format?.label ?? 'Format',
                  icon: Icons.movie_outlined,
                  active: filter.format != null,
                  onTap: onOpenFilters,
                  onClear: () => onChanged(filter.copyWith(format: () => null)),
                ),
                _FilterPill(
                  label: filter.status?.label ?? 'Status',
                  icon: Icons.play_circle_outline_rounded,
                  active: filter.status != null,
                  onTap: onOpenFilters,
                  onClear: () => onChanged(filter.copyWith(status: () => null)),
                ),
                _FilterPill(
                  label: filter.genre ?? 'Genre',
                  icon: Icons.category_outlined,
                  active: filter.genre != null,
                  onTap: onOpenFilters,
                  onClear: () => onChanged(filter.copyWith(genre: () => null)),
                ),
                _FilterPill(
                  label: filter.season?.label ?? 'Season',
                  icon: Icons.calendar_today_rounded,
                  active: filter.season != null,
                  onTap: onOpenFilters,
                  onClear: () => onChanged(filter.copyWith(season: () => null)),
                ),
                _FilterPill(
                  label: filter.year != null ? '${filter.year}' : 'Year',
                  icon: Icons.date_range_rounded,
                  active: filter.year != null,
                  onTap: onOpenFilters,
                  onClear: () => onChanged(filter.copyWith(year: () => null)),
                ),
                if (!filter.isDefault)
                  _FilterPill(
                    label: 'Clear all',
                    icon: Icons.refresh_rounded,
                    active: false,
                    onTap: () => onChanged(AnimeSearchFilter.empty),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterChipsDelegate old) =>
      old.filter != filter || old.inset != inset || old.cs != cs;
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = active ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 6, onClear != null && active ? 6 : 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (onClear != null && active) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClear,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.close_rounded, size: 14, color: fg),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Shared UI Components
// ═════════════════════════════════════════════════════════════════════════

typedef _SectionTitle = SearchSectionTitle;
typedef _SuggestionChip = SearchSuggestionChip;
