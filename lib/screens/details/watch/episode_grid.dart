import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/database/repositories/watch_repository.dart'
    show EpisodeProgressInfo;
import 'package:aniways/core/helpers.dart';
import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/providers/watch_provider.dart';

import 'anime_player_screen.dart';
import 'episode_watch_options_sheet.dart';

/// Renders the episode collection with chunked ranges, watched progress,
/// and support for lazy list and compact grid views.
class EpisodeViewSection extends StatelessWidget {
  const EpisodeViewSection({
    super.key,
    required this.wp,
    required this.anime,
    required this.accent,
    required this.bottom,
    this.isEmbeddedInTwoPane = false,
  });

  final WatchProvider wp;
  final AnimeMedia anime;
  final Color accent;
  final double bottom;
  final bool isEmbeddedInTwoPane;

  int _calculateColumns(double availableWidth) {
    if (availableWidth >= 800) return 4;
    if (availableWidth >= 520) return 3;
    return 2;
  }

  void _playEpisode(BuildContext context, EpisodeItem ep) async {
    HapticFeedback.selectionClick();
    wp.playEpisode(ep, accent: accent);
    await AnimePlayerScreen.open(
      context,
      wp,
      anime: anime,
      accent: accent,
    );
    if (context.mounted) {
      await wp.refreshWatchState();
    }
  }

  void _showOptions(BuildContext context, EpisodeItem ep) {
    showEpisodeWatchOptionsSheet(
      context,
      episode: ep,
      watchProvider: wp,
      anime: anime,
      accent: accent,
      onPlay: () => _playEpisode(context, ep),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episodes = wp.chunkedEpisodes;
    final totalEpisodes = wp.allEpisodesForAudio;

    if (totalEpisodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_filter_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No ${wp.selectedAudio.name.toUpperCase()} episodes available on ${wp.selectedProviderId}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Range chunking tabs (for shows with >25 episodes) ──
            if (wp.totalChunks > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChunkSelector(wp: wp, accent: accent),
                ),
              ),

            switch (wp.viewMode) {
              EpisodeViewMode.list => _buildSliverList(context, episodes, bottom),
              EpisodeViewMode.cards => _buildSliverCards(
                  context,
                  episodes,
                  constraints.maxWidth,
                  bottom,
                ),
              EpisodeViewMode.compact => _buildSliverCompact(
                  context,
                  episodes,
                  bottom,
                ),
            },
          ],
        );
      },
    );
  }

  Widget _buildSliverCards(
    BuildContext context,
    List<EpisodeItem> episodes,
    double maxWidth,
    double bottom,
  ) {
    const double hPadding = 16.0;
    const double crossSpacing = 10.0;
    final availableWidth = maxWidth - (hPadding * 2);
    final columns = _calculateColumns(availableWidth);

    final cardWidth =
        (availableWidth - (crossSpacing * (columns - 1))) / columns;
    final thumbHeight = cardWidth * 9.0 / 16.0;
    final mainAxisExtent = thumbHeight + 48.0;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(hPadding, 6, hPadding, bottom + 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: crossSpacing,
          mainAxisSpacing: 10,
          mainAxisExtent: mainAxisExtent,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ep = episodes[index];
            return _EpisodeCardTile(
              ep: ep,
              anime: anime,
              isSelected: wp.currentEpisode?.number == ep.number,
              watchedPercent: wp.watchedPercentages[ep.number],
              progress: wp.episodeProgressMap[ep.number],
              accent: accent,
              onTap: () => _playEpisode(context, ep),
              onOptions: () => _showOptions(context, ep),
            );
          },
          childCount: episodes.length,
        ),
      ),
    );
  }

  Widget _buildSliverList(
    BuildContext context,
    List<EpisodeItem> episodes,
    double bottom,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottom + 24),
      sliver: SliverList.separated(
        itemCount: episodes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final ep = episodes[index];
          final isSelected = wp.currentEpisode?.number == ep.number;
          final percent = wp.watchedPercentages[ep.number];

          return _EpisodeTile(
            ep: ep,
            anime: anime,
            isSelected: isSelected,
            watchedPercent: percent,
            progress: wp.episodeProgressMap[ep.number],
            accent: accent,
            onTap: () => _playEpisode(context, ep),
            onOptions: () => _showOptions(context, ep),
          );
        },
      ),
    );
  }

  Widget _buildSliverCompact(
    BuildContext context,
    List<EpisodeItem> episodes,
    double bottom,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 72,
          mainAxisExtent: 48,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ep = episodes[index];
            return _EpisodeNumberChip(
              ep: ep,
              isSelected: wp.currentEpisode?.number == ep.number,
              watchedPercent: wp.watchedPercentages[ep.number],
              accent: accent,
              onTap: () => _playEpisode(context, ep),
              onOptions: () => _showOptions(context, ep),
            );
          },
          childCount: episodes.length,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Range Chunk Tabs (e.g. 1–25, 26–50)
// ═════════════════════════════════════════════════════════════════════════

class ChunkSelector extends StatelessWidget {
  const ChunkSelector({
    super.key,
    required this.wp,
    required this.accent,
    this.height = 36,
    this.horizontalPadding = 16,
    this.itemPadding = 14,
    this.borderRadius = 18,
    this.fontSize = 12,
  });

  final WatchProvider wp;
  final Color accent;
  final double height;
  final double horizontalPadding;
  final double itemPadding;
  final double borderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = wp.allEpisodesForAudio.length;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: wp.totalChunks,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final allEps = wp.episodes;
          final startIdx = i * WatchProvider.chunkSize;
          final endIdx = ((i + 1) * WatchProvider.chunkSize).clamp(
            0,
            allEps.length,
          );
          final String label;
          if (startIdx < allEps.length && endIdx > startIdx) {
            final firstNum = allEps[startIdx].number;
            final lastNum = allEps[endIdx - 1].number;
            label = firstNum == lastNum ? '$firstNum' : '$firstNum–$lastNum';
          } else {
            final start = i * WatchProvider.chunkSize + 1;
            final end = ((i + 1) * WatchProvider.chunkSize).clamp(1, total);
            label = '$start–$end';
          }
          final isSelected = wp.selectedChunkIndex == i;

          return Material(
            color: isSelected ? accent : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                wp.selectChunk(i);
              },
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: itemPadding),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isSelected
                        ? accent
                        : cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Episode Tile (List Mode)
// ═════════════════════════════════════════════════════════════════════════

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.ep,
    required this.anime,
    required this.isSelected,
    required this.watchedPercent,
    this.progress,
    required this.accent,
    required this.onTap,
    this.onOptions,
  });

  final EpisodeItem ep;
  final AnimeMedia anime;
  final bool isSelected;
  final double? watchedPercent;
  final EpisodeProgressInfo? progress;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onOptions;

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final m = seconds ~/ 60;
    return '${m}m';
  }

  String? _formatAirDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final dt = DateTime.tryParse(raw.trim());
    if (dt != null) {
      return formatShortDate(dt);
    }
    return raw.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isSelected
        ? Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.20 : 0.12),
            theme.scaffoldBackgroundColor,
          )
        : cs.surfaceContainerHigh;

    final imageUrl = ep.image ?? anime.bannerUrl ?? anime.coverUrl;
    final durationLabel = _formatDuration(ep.duration);
    final formattedAirDate = _formatAirDate(ep.airDate);
    final isCompleted = watchedPercent != null && watchedPercent! >= 0.90;
    final hasWatchProgress = progress != null &&
        progress!.position > Duration.zero &&
        progress!.duration > Duration.zero &&
        !isCompleted;
    final watchProgressLabel = hasWatchProgress
        ? '${formatDuration(progress!.position)} / ${formatDuration(progress!.duration)}'
        : '';
    final timeLabel =
        watchProgressLabel.isNotEmpty ? watchProgressLabel : durationLabel;

    return RepaintBoundary(
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onOptions != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onOptions!();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? accent.withValues(alpha: isDark ? 0.65 : 0.85)
                    : cs.outlineVariant.withValues(alpha: isDark ? 0.12 : 0.22),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final thumbWidth = (constraints.maxWidth * 0.38).clamp(
                  124.0,
                  156.0,
                );

                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 82),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Edge-to-edge Flush Thumbnail ──
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 82,
                            maxHeight: 136,
                          ),
                          child: SizedBox(
                            width: thumbWidth,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (imageUrl != null)
                                  CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    cacheManager:
                                        ImageCacheService.animeImageCache,
                                    memCacheWidth: 280,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) =>
                                        const Skeleton(radius: 0),
                                    errorWidget: (_, _, _) => Container(
                                      color: cs.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.movie_rounded,
                                        color: cs.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                        size: 28,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    color: cs.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.movie_rounded,
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                      size: 28,
                                    ),
                                  ),

                                // Top/bottom gradient scrim + right edge dissolve into cardBg
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      stops: const [0.0, 0.40, 0.72, 1.0],
                                      colors: [
                                        Colors.transparent,
                                        Colors.transparent,
                                        cardBg.withValues(alpha: 0.50),
                                        cardBg,
                                      ],
                                    ),
                                  ),
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.45, 1.0],
                                      colors: [
                                        Colors.black.withValues(alpha: 0.15),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.35),
                                      ],
                                    ),
                                  ),
                                ),

                                // Center play indicator icon
                                Center(
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            // Watched Progress Bar (flush along the bottom)
                            if (!isSelected &&
                                watchedPercent != null &&
                                watchedPercent! > 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LinearProgressIndicator(
                                  value: watchedPercent!,
                                  minHeight: 3.0,
                                  backgroundColor: Colors.black54,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted ? Colors.green : accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                      // ── Details column ──
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top line: Episode number tracking + badges
                              Row(
                                children: [
                                  Text(
                                    'EPISODE ${ep.number}',
                                    style: TextStyle(
                                      color: isSelected ? accent : cs.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  if (ep.filler) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(
                                          alpha: isDark ? 0.20 : 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.amber.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        'FILLER',
                                        style: TextStyle(
                                          color: Colors.amber.shade700,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (ep.recap) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.tertiaryContainer.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'RECAP',
                                        style: TextStyle(
                                          color: cs.onTertiaryContainer,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (isCompleted) ...[
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green.shade400,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  if (onOptions != null)
                                    InkResponse(
                                      onTap: onOptions,
                                      radius: 16,
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Icon(
                                          Icons.more_vert_rounded,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.65),
                                          size: 17,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Title
                              Text(
                                ep.title.isNotEmpty
                                    ? ep.title
                                    : 'Episode ${ep.number}',
                                maxLines: (ep.description != null &&
                                        ep.description!.trim().isNotEmpty)
                                    ? 2
                                    : 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: cs.onSurface,
                                  fontSize: 13,
                                  height: 1.25,
                                ),
                              ),

                              if (ep.description != null &&
                                  ep.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  ep.description!.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.75),
                                    height: 1.25,
                                  ),
                                ),
                              ],

                              // Bottom row: air date • duration / progress (only if metadata exists)
                              if (formattedAirDate != null ||
                                  timeLabel.isNotEmpty) ...[
                                const Spacer(),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (formattedAirDate != null) ...[
                                      Text(
                                        formattedAirDate,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.75),
                                            ),
                                      ),
                                      if (timeLabel.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                          ),
                                          child: Text(
                                            '•',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.45),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timeLabel,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: hasWatchProgress
                                                    ? (isSelected
                                                        ? accent
                                                        : cs.primary)
                                                    : cs.onSurfaceVariant
                                                        .withValues(alpha: 0.75),
                                              ),
                                        ),
                                      ],
                                    ] else if (timeLabel.isNotEmpty) ...[
                                      Text(
                                        timeLabel,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: hasWatchProgress
                                                  ? (isSelected
                                                      ? accent
                                                      : cs.primary)
                                                  : cs.onSurfaceVariant
                                                      .withValues(alpha: 0.75),
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Episode Card Tile (Card Grid Mode)
// ═════════════════════════════════════════════════════════════════════════

class _EpisodeCardTile extends StatelessWidget {
  const _EpisodeCardTile({
    required this.ep,
    required this.anime,
    required this.isSelected,
    required this.watchedPercent,
    this.progress,
    required this.accent,
    required this.onTap,
    this.onOptions,
  });

  final EpisodeItem ep;
  final AnimeMedia anime;
  final bool isSelected;
  final double? watchedPercent;
  final EpisodeProgressInfo? progress;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onOptions;

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final m = seconds ~/ 60;
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isSelected
        ? Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.20 : 0.12),
            theme.scaffoldBackgroundColor,
          )
        : cs.surfaceContainerHigh;

    final imageUrl = ep.image ?? anime.bannerUrl ?? anime.coverUrl;
    final durationLabel = _formatDuration(ep.duration);
    final isCompleted = watchedPercent != null && watchedPercent! >= 0.90;
    final hasWatchProgress = progress != null &&
        progress!.position > Duration.zero &&
        progress!.duration > Duration.zero &&
        !isCompleted;
    final watchProgressLabel = hasWatchProgress
        ? '${formatDuration(progress!.position)} / ${formatDuration(progress!.duration)}'
        : '';
    final timeBadgeLabel =
        watchProgressLabel.isNotEmpty ? watchProgressLabel : durationLabel;

    return RepaintBoundary(
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onOptions != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onOptions!();
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? accent.withValues(alpha: isDark ? 0.65 : 0.85)
                    : cs.outlineVariant.withValues(alpha: isDark ? 0.12 : 0.22),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 16:9 Thumbnail with Badges & Progress ──
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          cacheManager: ImageCacheService.animeImageCache,
                          memCacheWidth: 420,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Skeleton(radius: 0),
                          errorWidget: (_, _, _) => Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(
                              Icons.movie_rounded,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              size: 24,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie_rounded,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            size: 24,
                          ),
                        ),

                      // Top scrim + smooth bottom dissolve into cardBg
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.40, 0.72, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                              cardBg.withValues(alpha: 0.50),
                              cardBg,
                            ],
                          ),
                        ),
                      ),

                      // Center Play Icon Indicator
                      Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.55),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Bottom-Right Duration / Progress Badge
                      if (timeBadgeLabel.isNotEmpty)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              timeBadgeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Watched progress bar along bottom edge (hidden when selected)
                      if (!isSelected && watchedPercent != null && watchedPercent! > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 3,
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: watchedPercent!.clamp(0.0, 1.0),
                                child: Container(
                                  color: isCompleted ? Colors.green : accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Episode Info (Number & Title) ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'EPISODE ${ep.number}',
                              style: TextStyle(
                                color: isSelected ? accent : cs.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                            if (ep.filler) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(
                                    alpha: isDark ? 0.20 : 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.5),
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  'FILLER',
                                  style: TextStyle(
                                    color: Colors.amber.shade700,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (isCompleted)
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade400,
                                size: 13,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ep.title.isNotEmpty ? ep.title : 'Episode ${ep.number}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: cs.onSurface,
                            height: 1.2,
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
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Compact Number Chip
// ═════════════════════════════════════════════════════════════════════════

class _EpisodeNumberChip extends StatelessWidget {
  const _EpisodeNumberChip({
    required this.ep,
    required this.isSelected,
    required this.watchedPercent,
    required this.accent,
    required this.onTap,
    this.onOptions,
  });

  final EpisodeItem ep;
  final bool isSelected;
  final double? watchedPercent;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = watchedPercent != null && watchedPercent! >= 0.90;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      bgColor = accent;
      borderColor = accent;
      textColor = Colors.white;
    } else if (ep.filler) {
      bgColor = isDark ? const Color(0xFF2A2200) : const Color(0xFFFFF8E1);
      borderColor = Colors.amber.withValues(alpha: 0.5);
      textColor = Colors.amber.shade700;
    } else {
      bgColor = cs.surfaceContainerHighest;
      borderColor = cs.outlineVariant.withValues(alpha: 0.35);
      textColor = cs.onSurface;
    }

    return RepaintBoundary(
      child: Tooltip(
        message: ep.title,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            onLongPress: onOptions != null
                ? () {
                    HapticFeedback.mediumImpact();
                    onOptions!();
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${ep.number}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isCompleted && !isSelected)
                    Positioned(
                      top: 3,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
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
  }
}
