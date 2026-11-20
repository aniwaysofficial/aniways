import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/database/repositories/collection_repository.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/navigation/main_navigation.dart' show pushFullScreen;
import 'package:aniways/screens/home/home_section.dart' show SectionHeader;
import 'package:aniways/screens/settings/favorite_anime_picks_screen.dart';

/// A personalized horizontal carousel on the home screen showing anime
/// recommended based on the user's in-app favorites, watching list, and onboarding picks.
///
/// Automatically excludes shows the user has already marked completed, watching, or dropped,
/// and live-reacts if a recommended show is marked completed elsewhere in the app.
class RecommendedSection extends StatefulWidget {
  const RecommendedSection({super.key});

  @override
  State<RecommendedSection> createState() => RecommendedSectionState();
}

class RecommendedSectionState extends State<RecommendedSection> {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final AnilistService _api = AnilistService();

  List<AnimeMedia> _items = const [];
  bool _isLoading = true;
  bool _hasError = false;
  bool? _hasSeeds;

  StreamSubscription<Set<int>>? _completedSubscription;

  @override
  void initState() {
    super.initState();
    SharedPreferencesService.recommendationsChangedNotifier.addListener(
      _onRecommendationsSettingChanged,
    );
    if (_prefs.onboardingFavoriteAnimeIds.isNotEmpty) {
      _hasSeeds = true;
    }
    _loadRecommendations();
    _listenToCompletedChanges();
  }

  @override
  void dispose() {
    SharedPreferencesService.recommendationsChangedNotifier.removeListener(
      _onRecommendationsSettingChanged,
    );
    _completedSubscription?.cancel();
    super.dispose();
  }

  void _onRecommendationsSettingChanged() {
    if (!mounted) return;
    setState(() {});
    if (_prefs.showHomeRecommendations && _items.isEmpty) {
      _loadRecommendations();
    }
  }

  void _listenToCompletedChanges() {
    _completedSubscription = CollectionRepository.instance
        .watchCollectionAnimeIds('completed')
        .listen((completedIds) {
          if (!mounted || _items.isEmpty || completedIds.isEmpty) return;
          final filtered = _items
              .where((anime) => !completedIds.contains(anime.id))
              .toList();
          if (filtered.length != _items.length) {
            setState(() {
              _items = filtered;
            });
          }
        });
  }

  /// Reloads recommendations (called on pull-to-refresh).
  Future<void> reload() => _loadRecommendations();

  Future<void> _loadRecommendations() async {
    List<int> favorites = const [];
    List<int> watching = const [];
    Set<int> excludedIds = const {};

    try {
      final repo = CollectionRepository.instance;
      final results = await Future.wait([
        repo.getCollectionAnimeIds(CollectionRepository.favoritesId),
        repo.getCollectionAnimeIds('watching'),
        repo.getExcludedRecommendationIds(),
      ]);
      favorites = results[0] as List<int>;
      watching = results[1] as List<int>;
      excludedIds = results[2] as Set<int>;
    } catch (_) {}

    final onboardingSeeds = _prefs.onboardingFavoriteAnimeIds;

    // Ordered, deduplicated seeds: favorites (highest signal) -> watching -> onboarding picks
    final seedIds = <int>[];
    final seen = <int>{};
    for (final id in [...favorites, ...watching, ...onboardingSeeds]) {
      if (seen.add(id)) {
        seedIds.add(id);
      }
    }

    if (seedIds.isEmpty) {
      if (mounted) {
        setState(() {
          _items = const [];
          _isLoading = false;
          _hasSeeds = false;
          _hasError = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _hasSeeds = true;
        _isLoading = true;
      });
    }

    try {
      final results = await _api.recommendationsForAnime(
        animeIds: seedIds,
        excludedIds: excludedIds,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _items = results;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  double _cardWidthFor(BuildContext context) => switch (context.layoutSize) {
    WindowSize.compact => 128,
    WindowSize.medium => 148,
    WindowSize.expanded => 160,
    WindowSize.large => 172,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final cardWidth = _cardWidthFor(context);
    final inset = pageInset(context);

    // If user disabled recommendations on home in settings, hide completely
    if (!_prefs.showHomeRecommendations) {
      return const SizedBox.shrink();
    }

    // Show an inviting banner card if user skipped onboarding / has no seeds
    if (_hasSeeds == false || (!_isLoading && _items.isEmpty && !_hasError)) {
      if (_prefs.dismissedAnimePicksBanner) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(inset, 4, inset, 28),
        child: Material(
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anime You Love',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await _prefs.setDismissedAnimePicksBanner(true);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Pick your favorites to personalize your feed.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await pushFullScreen(
                      context,
                      const FavoriteAnimePicksScreen(),
                    );
                    _loadRecommendations();
                  },
                  icon: const Icon(Icons.favorite_rounded, size: 16),
                  label: const Text('Pick shows'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Hide while initial seed discovery is happening
    if (_hasSeeds == null && _items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recommended For You',
            icon: Icons.auto_awesome_rounded,
            color: cs.primary,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: cardWidth / kPosterAspect + animeCardTextHeight(context),
            child: _isLoading && _items.isEmpty
                ? ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, _) => AnimeCardSkeleton(width: cardWidth),
                  )
                : _hasError && _items.isEmpty
                ? Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadRecommendations();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry Recommendations'),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final anime = _items[i];
                      return AnimeCard(
                        anime: anime,
                        width: cardWidth,
                        heroPrefix: 'recommended',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
