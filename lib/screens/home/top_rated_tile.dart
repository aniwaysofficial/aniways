import 'package:flutter/material.dart';

import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/core/theme/genre_colors.dart';

const double _posterW = 108;
const double _cardRadius = 22;
const double _pad = 12;

// Rounded height matching poster aspect ratio (108 / 0.7 = 154.28 -> 154)
const double _posterH = 154;

/// Height of one tile (poster + paddings), for use as a grid's row extent.
double topRatedTileExtent() => _posterH + _pad * 2 + 10;

/// One text style for the whole "★ 9.1 · TV · 28 eps" row, so the rating and
/// the info line match in size and height.
const TextStyle _metaStyle = TextStyle(
  fontSize: 13.5,
  fontWeight: FontWeight.w600,
  height: 1.2,
);

/// Medal colours for the podium, a neutral dark tab for everything after.
Color _rankColor(int rank) => switch (rank) {
  1 => const Color(0xFFFFC107),
  2 => const Color(0xFFB0BEC5),
  3 => const Color(0xFFD7915A),
  _ => const Color(0xFF000000),
};

/// One row of the "Top rated" list: an optimized card with a subtle cover-tinted
/// gradient background, poster + rank tab, title, format, coloured genre pills, and score.
class TopRatedTile extends StatelessWidget {
  const TopRatedTile({super.key, required this.anime, required this.rank});

  final AnimeMedia anime;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final score = anime.scoreLabel;
    final format = anime.formatLabel;
    final eps = anime.episodes;
    final epsLabel = eps == null ? null : '$eps ${eps == 1 ? 'ep' : 'eps'}';
    // "TV · 28 eps"
    final info = [?format, ?epsLabel].join(' · ');
    final genres = anime.genres.take(3).toList();

    final Color tint = switch (anime.coverColor) {
      final int v => Color(v),
      _ =>
        anime.genres.isNotEmpty ? genreColor(anime.genres.first) : cs.primary,
    };

    final hsl = HSLColor.fromColor(tint);

    // Multi-stop gradient derived from the anime cover image's dominant color.
    final Gradient cardGradient;
    if (isDark) {
      final glowStart = hsl
          .withLightness((hsl.lightness * 0.5).clamp(0.12, 0.22))
          .withSaturation((hsl.saturation * 0.85).clamp(0.3, 0.7))
          .toColor();
      final glowMid = Color.alphaBlend(
        tint.withValues(alpha: 0.20),
        cs.surfaceContainerHigh,
      );
      final glowEnd = Color.alphaBlend(
        tint.withValues(alpha: 0.06),
        cs.surfaceContainerLow,
      );
      cardGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [glowStart, glowMid, glowEnd],
        stops: const [0.0, 0.5, 1.0],
      );
    } else {
      final lightStart = hsl
          .withLightness((hsl.lightness * 1.25).clamp(0.82, 0.94))
          .withSaturation((hsl.saturation * 0.75).clamp(0.25, 0.65))
          .toColor();
      final lightMid = Color.alphaBlend(
        tint.withValues(alpha: 0.15),
        cs.surfaceContainerLow,
      );
      final lightEnd = cs.surfaceContainerLowest;
      cardGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightStart, lightMid, lightEnd],
        stops: const [0.0, 0.6, 1.0],
      );
    }

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            gradient: cardGradient,
            border: Border.all(
              color: tint.withValues(alpha: isDark ? 0.32 : 0.2),
              width: 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_cardRadius),
              onTap: () => openAnime(
                context,
                anime,
                heroTag: 'top-rated-${anime.id}-$rank',
              ),
              child: Padding(
                padding: const EdgeInsets.all(_pad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Poster(anime: anime, rank: rank),
                    const SizedBox(width: 14),
                    Expanded(
                    child: SizedBox(
                      height: _posterH,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anime.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isDark ? Colors.white : cs.onSurface,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          // "★ 9.1 · TV · 28 eps" on one row, one text size.
                          if (score != null || info.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                if (score != null) _Rating(score),
                                if (score != null && info.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '·',
                                      style: _metaStyle.copyWith(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.5,
                                              )
                                            : cs.onSurfaceVariant.withValues(
                                                alpha: 0.5,
                                              ),
                                      ),
                                    ),
                                  ),
                                if (info.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      info,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _metaStyle.copyWith(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.78,
                                              )
                                            : cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          // Genres pinned to the bottom, full width.
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: genres.isEmpty
                                  ? const SizedBox.shrink()
                                  : Wrap(
                                      spacing: 5,
                                      runSpacing: 5,
                                      children: [
                                        for (final g in genres) _GenrePill(g),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _Poster extends StatelessWidget {
  const _Poster({required this.anime, required this.rank});

  final AnimeMedia anime;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final podium = rank <= 3;
    final tabColor = _rankColor(rank);

    return SizedBox(
      width: _posterW,
      height: _posterH,
      child: Hero(
        tag: 'top-rated-${anime.id}-$rank',
        transitionOnUserGestures: true,
        child: Material(
          type: MaterialType.transparency,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimeImage(
                  anime.coverUrl,
                  tint: anime.coverColor,
                ),
                // Rank tab, flush in the top-left corner.
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
                decoration: BoxDecoration(
                  color: podium ? tabColor : tabColor.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: podium ? Colors.black : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
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

class _GenrePill extends StatelessWidget {
  const _GenrePill(this.genre);

  final String genre;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = genreColor(genre);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isDark ? 0.32 : 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        genre,
        style: TextStyle(
          color: isDark
              ? lightenColor(c)
              : Colors.black.withValues(alpha: 0.80),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating(this.score);

  final String score;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFC107)),
        const SizedBox(width: 3),
        Text(
          score,
          style: _metaStyle.copyWith(
            color: isDark
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder with the same layout as [TopRatedTile].
class TopRatedTileSkeleton extends StatelessWidget {
  const TopRatedTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(_pad),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: _posterW, height: _posterH, radius: 16),
            SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: _posterH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(height: 14, radius: 6),
                    SizedBox(height: 8),
                    Skeleton(width: 90, height: 11, radius: 6),
                    Spacer(),
                    Row(
                      children: [
                        Skeleton(width: 54, height: 18, radius: 8),
                        SizedBox(width: 5),
                        Skeleton(width: 64, height: 18, radius: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
