import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/widgets/anime_card.dart' show animeImageCache;
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/screens/onboarding/widgets/onboarding_card_scaffold.dart';

/// Step 5: Pick favorite shows and movies for personalized recommendations.
///
/// Provides a diverse catalog of 52 distinct popular anime franchises,
/// with subsequent seasons and sequels automatically filtered out using AniList's relation graph.
class AnimePicksCard extends StatefulWidget {
  const AnimePicksCard({super.key, this.onAnimeSelectionChanged});

  final ValueChanged<List<int>>? onAnimeSelectionChanged;

  @override
  State<AnimePicksCard> createState() => _AnimePicksCardState();
}

class _AnimePicksCardState extends State<AnimePicksCard> {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  late final Set<int> _selectedIds;
  List<CuratedAnime> _animeList = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = _prefs.onboardingFavoriteAnimeIds.toSet();
    _fetchLivePopular();
  }

  Future<void> _fetchLivePopular() async {
    try {
      final distinctAnime = await anilistService.popularFranchises(limit: 52);
      if (distinctAnime.isNotEmpty && mounted) {
        final items = distinctAnime
            .where((m) => (m.coverUrl?.isNotEmpty ?? false))
            .map((m) => CuratedAnime(
                  id: m.id,
                  title: m.title,
                  coverUrl: m.coverUrl!,
                ))
            .toList();

        setState(() {
          _animeList = items;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Handled below
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _save() {
    final list = _selectedIds.toList();
    _prefs.setOnboardingFavoriteAnimeIds(list);
    widget.onAnimeSelectionChanged?.call(list);
  }

  void _toggle(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 150,
      childAspectRatio: 0.68,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    );

    return OnboardingPage(
      title: 'Anime you love',
      subtitle:
          'Tap the shows and movies you have enjoyed. We will find more like them.',
      slivers: [
        SliverToBoxAdapter(
          child: OnboardingSectionHeader(
            title: '${_selectedIds.length} selected',
            trailing: _selectedIds.isEmpty
                ? null
                : OnboardingTextAction(
                    label: 'Clear',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedIds.clear());
                      _save();
                    },
                  ),
          ),
        ),
        if (_isLoading && _animeList.isEmpty)
          SliverGrid.builder(
            itemCount: 18,
            gridDelegate: gridDelegate,
            itemBuilder: (context, index) => const AnimePickCardSkeleton(),
          )
        else if (_animeList.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchLivePopular();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry loading popular anime'),
                ),
              ),
            ),
          )
        else
          SliverGrid.builder(
            itemCount: _animeList.length,
            gridDelegate: gridDelegate,
            itemBuilder: (context, index) {
              final anime = _animeList[index];
              return AnimePickTile(
                key: ValueKey(anime.id),
                anime: anime,
                isSelected: _selectedIds.contains(anime.id),
                onTap: () => _toggle(anime.id),
              );
            },
          ),
      ],
    );
  }
}

class AnimePickTile extends StatelessWidget {
  const AnimePickTile({
    super.key,
    required this.anime,
    required this.isSelected,
    required this.onTap,
  });

  final CuratedAnime anime;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = 16.0;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: anime.coverUrl,
                  cacheManager: animeImageCache,
                  memCacheWidth: 360,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const Skeleton(radius: radius),
                  errorWidget: (_, _, _) => ColoredBox(
                    color: cs.surfaceContainerHighest,
                    child:
                        Icon(Icons.movie_outlined, color: cs.onSurfaceVariant),
                  ),
                ),

                // Title on a gradient
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.90),
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                      child: Text(
                        anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Selected tinted wash
                if (isSelected)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.16),
                      ),
                    ),
                  ),

                // Selection checkmark badge in top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : (isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.70)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? cs.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.28)
                                : Colors.black.withValues(alpha: 0.12)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: cs.onPrimary,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimePickCardSkeleton extends StatelessWidget {
  const AnimePickCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Skeleton(radius: 16),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Skeleton(height: 11, radius: 5),
                  SizedBox(height: 4),
                  Skeleton(width: 55, height: 9, radius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CuratedAnime {
  const CuratedAnime({
    required this.id,
    required this.title,
    required this.coverUrl,
  });

  final int id;
  final String title;
  final String coverUrl;
}
