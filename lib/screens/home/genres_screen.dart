import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/services/blurred_cover_service.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/navigation/main_navigation.dart' show MainNavigation;
import 'package:aniways/providers/anime_lists.dart' show describeError;
import 'package:aniways/core/theme/genre_colors.dart';

/// Screen displaying all anime genres in a responsive grid.
/// Each card features a blurred, optimized representative cover image,
/// a tinted accent gradient, and an icon.
class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  static const _crossSpacing = 12.0;
  static const _mainSpacing = 12.0;

  bool _isLoading = true;
  Object? _error;
  List<GenreItem> _genres = const [];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await anilistService.genres(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _genres = items;
        _isLoading = false;
      });
      // Pre-warm the disk-cached blurred textures so scrolling the grid has 0 GPU work
      for (final item in items) {
        final url = item.coverUrl;
        if (url != null && url.isNotEmpty) {
          BlurredCoverService.instance.getOrBlur(url);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = pageInset(context);
    final gridWidth = context.contentWidth - inset * 2;
    final columns = context.layoutSize.isCompact
        ? 2
        : gridColumns(
            gridWidth,
            minTileWidth: 160,
            maxColumns: 4,
            spacing: _crossSpacing,
          );

    final bottomInset = MediaQuery.paddingOf(context).bottom + 28;

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisExtent: 112,
      crossAxisSpacing: _crossSpacing,
      mainAxisSpacing: _mainSpacing,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadGenres(forceRefresh: true),
        child: CustomScrollView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(800),
          slivers: [
            const OneUiSliverHeader(title: 'Genres'),

            if (_isLoading)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 8, inset, 0),
                sliver: SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemCount: 16,
                  itemBuilder: (context, index) => const _GenreCardSkeleton(),
                ),
              )
            else if (_error != null && _genres.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: inset,
                    vertical: 24,
                  ),
                  child: ErrorCard(
                    message: describeError(_error),
                    onRetry: () => _loadGenres(forceRefresh: true),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 8, inset, 0),
                sliver: SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemCount: _genres.length,
                  itemBuilder: (context, index) => GenreCard(
                    key: ValueKey(_genres[index].name),
                    genre: _genres[index],
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
          ],
        ),
      ),
    );
  }
}

/// A genre card with an optimized blurred background cover,
/// genre-tinted gradient, icon, and title.
class GenreCard extends StatelessWidget {
  const GenreCard({super.key, required this.genre});

  final GenreItem genre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final icon = genreIcon(genre.name);
    final coverUrl = genre.coverUrl;

    // Theme-adaptive colors
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
          onTap: () {
            MainNavigation.switchToSearch(context, genre: genre.name);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Pre-Blurred Cover Background (Disk-Cached, 0 GPU Shaders) ──
              Positioned.fill(
                child: BlurredCardCover(
                  url: coverUrl,
                  fallback: ColoredBox(
                    color: genreColor(genre.name).withValues(
                      alpha: isDark ? 0.12 : 0.08,
                    ),
                  ),
                ),
              ),

              // ── Clean Theme-Adaptive Scrim Vignette ──
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

                    // Bottom Row: Genre Title & Chevron
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            genre.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 19,
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

/// Loading skeleton for a genre card.
class _GenreCardSkeleton extends StatelessWidget {
  const _GenreCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(13),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Skeleton(width: 32, height: 32, radius: 10),
          Skeleton(width: 76, height: 14, radius: 6),
        ],
      ),
    );
  }
}
