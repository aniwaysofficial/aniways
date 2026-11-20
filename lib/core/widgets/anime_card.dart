import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;

import 'package:aniways/core/database/repositories/collection_repository.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/cover_palette.dart';
import 'package:aniways/core/widgets/contextual_anime_preview.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/core/theme/genre_colors.dart';

import 'package:aniways/navigation/main_navigation.dart' show pushFullScreen;
import 'package:aniways/screens/details/anime_details_screen.dart';

/// AniList covers are roughly 230×326.
const double kPosterAspect = 0.7;
const double kPosterRadius = 18;

const Color _starColor = Color(0xFFFFB300);

const double _titleFont = 13.5;
const double _subtitleFont = 12;
const double _lineHeight = 1.25;

/// Same corner language as the settings list: big on a group's outer
/// corners, small where rows meet.
const Radius _bigRadius = Radius.circular(20);
const Radius _smallRadius = Radius.circular(6);

BorderRadius groupedTileRadius({required bool isFirst, required bool isLast}) {
  return BorderRadius.vertical(
    top: isFirst ? _bigRadius : _smallRadius,
    bottom: isLast ? _bigRadius : _smallRadius,
  );
}

/// Height of the title + subtitle block under a poster, including the gap
/// above it. Scales with the user's font size so fixed-height rows and grids
/// never overflow.
double animeCardTextHeight(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  return 8 +
      scaler.scale(_titleFont) * _lineHeight * 2 +
      3 +
      scaler.scale(_subtitleFont) * _lineHeight +
      2;
}

void openAnime(BuildContext context, AnimeMedia anime, {String? heroTag}) {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  final tag = heroTag ?? 'anime-poster-${anime.id}';
  pushFullScreen(context, AnimeDetailsScreen(anime: anime, heroTag: tag));
}

// ═════════════════════════════════════════════════════════════════════════
// Image
// ═════════════════════════════════════════════════════════════════════════

AnimeImageCacheManager get animeImageCache => ImageCacheService.animeImageCache;

/// Network image that fades in over a tinted placeholder.
class AnimeImage extends StatelessWidget {
  const AnimeImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.tint,
    this.cacheWidth,
    this.filterQuality = FilterQuality.medium,
  });

  final String? url;
  final BoxFit fit;
  final Alignment alignment;

  /// Optional ARGB tint (the cover's dominant colour) for the placeholder.
  final int? tint;

  /// Decode the image at this pixel width instead of full size. Small values
  /// give a cheap, soft look for blurred-style backgrounds.
  final int? cacheWidth;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHigh;
    final background = tint == null
        ? base
        : Color.alphaBlend(Color(tint!).withValues(alpha: 0.28), base);

    final icon = Center(
      child: Icon(
        Icons.movie_outlined,
        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );

    final src = url;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: background),
        if (src == null)
          icon
        else
          // Image.network(
          //   src,
          //   fit: fit,
          //   alignment: alignment,
          //   cacheWidth: cacheWidth,
          //   filterQuality: filterQuality,
          //   gaplessPlayback: true,
          //   frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          //     if (wasSynchronouslyLoaded) return child;
          //     return AnimatedOpacity(
          //       opacity: frame == null ? 0 : 1,
          //       duration: context.motion(Motion.slow),
          //       curve: Curves.easeOut,
          //       child: child,
          //     );
          //   },
          //   errorBuilder: (context, error, stack) => icon,
          // ),
          CachedNetworkImage(
            cacheManager: animeImageCache,
            imageUrl: src,
            fit: fit,
            alignment: alignment,
            memCacheWidth: cacheWidth,
            filterQuality: filterQuality,
            // The tinted ColoredBox behind already acts as the placeholder, so only the
            // image itself fades in.
            fadeInDuration: Duration.zero,
            fadeInCurve: Curves.easeOut,
            fadeOutDuration: Duration.zero,
            placeholderFadeInDuration: Duration.zero,
            errorWidget: (context, url, error) => icon,
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Score badge
// ═════════════════════════════════════════════════════════════════════════

/// Dark pill with a star, readable on top of any image.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge(this.score, {super.key, this.tint});

  final String score;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final base = Colors.black.withValues(alpha: 0.85);
    final bg = tint == null
        ? base
        : Color.alphaBlend(tint!.withValues(alpha: 0.30), base);

    return Container(
      padding: const EdgeInsets.only(top: 3, bottom: 3, left: 3, right: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: _starColor),
          const SizedBox(width: 3),
          Text(
            score,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark pill with colored status dot and label, readable on top of any image.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.tint,
  });

  final String? status;
  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dotColor = switch (status) {
      'RELEASING' => const Color(0xFF4CD964),
      'FINISHED' => const Color(0xFF42A5F5),
      'NOT_YET_RELEASED' => cs.tertiary,
      'CANCELLED' || 'HIATUS' => cs.error,
      _ => Colors.white70,
    };

    final base = Colors.black.withValues(alpha: 0.85);
    final bg = tint == null
        ? base
        : Color.alphaBlend(tint!.withValues(alpha: 0.30), base);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dotColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Poster card (horizontal rows + grid)
// ═════════════════════════════════════════════════════════════════════════

/// Poster with score badge, two-line title and a short subtitle.
/// Pass [width] in horizontal lists; leave it null inside a grid.
///
/// The whole card (poster and text) squeezes slightly while pressed.
class AnimeCard extends StatelessWidget {
  const AnimeCard({
    super.key,
    required this.anime,
    this.width,
    this.heroTag,
    this.heroPrefix,
    this.onLongPress,
  });

  final AnimeMedia anime;
  final double? width;
  final String? heroTag;
  final String? heroPrefix;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final score = anime.scoreLabel;
    final effectiveTag =
        heroTag ??
        (heroPrefix != null
            ? '$heroPrefix-${anime.id}'
            : 'anime-poster-${anime.id}');

    // Instant colour from AniList; upgraded when the palette is ready.
    final fallback = anime.coverColor == null
        ? (anime.genres.isNotEmpty
            ? genreColor(anime.genres.first)
            : cs.primary)
        : Color(anime.coverColor!);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => openAnime(context, anime, heroTag: effectiveTag),
        onLongPress:
            onLongPress ?? () => showContextualAnimePreview(context, anime, heroTag: effectiveTag),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CoverPaletteBuilder(
                url: anime.coverUrl,
                fallback: fallback,
                builder: (context, accent, palette) {
                  // Keep the glow visible on very dark covers.
                  final glow = HSLColor.fromColor(accent)
                      .withLightness(
                        HSLColor.fromColor(accent).lightness.clamp(0.4, 0.65),
                      )
                      .toColor();

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kPosterRadius),
                      boxShadow: [
                        BoxShadow(
                          color: glow.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: kPosterAspect,
                      child: Hero(
                        tag: effectiveTag,
                        transitionOnUserGestures: true,
                        child: Material(
                          type: MaterialType.transparency,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(kPosterRadius),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AnimeImage(
                                  anime.coverUrl,
                                  tint: anime.coverColor,
                                  cacheWidth: width != null ? (width! * 2.2).round() : 350,
                                ),
                                ValueListenableBuilder<Set<int>>(
                                  valueListenable: CollectionRepository.instance.favoritesNotifier,
                                  builder: (context, favs, _) {
                                    if (!favs.contains(anime.id)) {
                                      return const SizedBox.shrink();
                                    }
                                    return Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.60),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.22),
                                            width: 0.8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.35),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1.5),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.favorite_rounded,
                                            size: 13.5,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (score != null)
                                  Positioned(
                                    left: 6,
                                    bottom: 6,
                                    child: ScoreBadge(score, tint: accent),
                                  ),
                                if (anime.statusLabel != null &&
                                    !anime.isCompleted)
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: StatusBadge(
                                      status: anime.status,
                                      label: anime.statusLabel!,
                                      tint: accent,
                                    ),
                                  ),
                                if (anime.isAdult &&
                                    SharedPreferencesService().blurAdultCovers)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(kPosterRadius),
                                      child: Container(
                                        color: Colors.black
                                            .withValues(alpha: 0.85),
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.55),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.22),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.visibility_off_rounded,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (anime.isAdult)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5.5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.45),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      '18+',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
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
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: scaler.scale(_titleFont) * _lineHeight * 2,
              child: Text(
                anime.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: _titleFont,
                  fontWeight: FontWeight.w600,
                  height: _lineHeight,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              anime.cardSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: _subtitleFont,
                height: _lineHeight,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// List tile (vertical lists)
// ═════════════════════════════════════════════════════════════════════════

/// A grouped row: poster with rank corner, title, details and score.
/// Stack several with a 2px gap and set [isFirst]/[isLast] for the rounded
/// group ends.
class AnimeListTile extends StatelessWidget {
  const AnimeListTile({
    super.key,
    required this.anime,
    required this.rank,
    this.isFirst = false,
    this.isLast = false,
  });

  final AnimeMedia anime;
  final int rank;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final score = anime.scoreLabel;
    final genres = anime.genres.take(3).join(' · ');
    final tileHeroTag = 'list-tile-${anime.id}-$rank';

    return Material(
      color: cs.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: groupedTileRadius(isFirst: isFirst, isLast: isLast),
      ),
      child: InkWell(
        onTap: () => openAnime(context, anime, heroTag: tileHeroTag),
        onLongPress: () => showContextualAnimePreview(context, anime, heroTag: tileHeroTag),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                child: AspectRatio(
                  aspectRatio: kPosterAspect,
                  child: Hero(
                    tag: tileHeroTag,
                    transitionOnUserGestures: true,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimeImage(
                              anime.coverUrl,
                              tint: anime.coverColor,
                              cacheWidth: 180,
                            ),
                            if (anime.isAdult &&
                                SharedPreferencesService().blurAdultCovers)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    color: isDark
                                        ? const Color(0xEE141416)
                                        : const Color(0xEEE8E8ED),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.visibility_off_outlined,
                                      size: 22,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            if (anime.isAdult)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '18+',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
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
            ),
          ),
          const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anime.tileSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (genres.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        genres,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (score != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: _starColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        score,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
