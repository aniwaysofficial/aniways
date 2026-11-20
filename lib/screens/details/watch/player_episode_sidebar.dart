import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/providers/watch_provider.dart';
import 'episode_grid.dart';
import 'episode_watch_options_sheet.dart';

/// Fullscreen landscape sidebar sheet allowing users to browse and switch
/// episodes directly while watching.
class PlayerEpisodeSidebar extends StatelessWidget {
  const PlayerEpisodeSidebar({
    super.key,
    required this.wp,
    required this.accent,
    this.anime,
  });

  final WatchProvider wp;
  final Color accent;
  final AnimeMedia? anime;

  /// Shows the episode sidebar sliding in from the right edge.
  static Future<void> show(
    BuildContext context, {
    required WatchProvider wp,
    required Color accent,
    AnimeMedia? anime,
  }) {
    // Ensure current episode chunk is selected when opening the sidebar
    wp.syncChunkWithCurrentEpisode();
    final theme = Theme.of(context);

    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Episodes',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim, secAnim) {
        final screenW = MediaQuery.sizeOf(dialogContext).width;
        final panelWidth = (screenW * 0.44).clamp(320.0, 420.0);

        return Theme(
          data: theme,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: panelWidth,
              height: double.infinity,
              child: PlayerEpisodeSidebar(
                wp: wp,
                accent: accent,
                anime: anime,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, anim, secAnim, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        left: false,
        top: true,
        bottom: true,
        right: true,
        child: AnimatedBuilder(
          animation: wp,
          builder: (context, _) {
            final episodes = wp.chunkedEpisodes;
            final totalEpisodes = wp.allEpisodesForAudio;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
                  child: Row(
                    children: [
                      Icon(Icons.video_library_rounded,
                          color: accent, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Episodes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${totalEpisodes.length}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // ── Range chunk tabs (e.g. 1–25, 26–50) ──
                if (wp.totalChunks > 1) ...[
                  const SizedBox(height: 10),
                  ChunkSelector(
                    wp: wp,
                    accent: accent,
                    height: 32,
                    horizontalPadding: 14,
                    itemPadding: 12,
                    borderRadius: 16,
                    fontSize: 11.5,
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 6),
                ],

                // ── Episodes List ──
                Expanded(
                  child: episodes.isEmpty
                      ? Center(
                          child: Text(
                            'No episodes found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                          itemCount: episodes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final ep = episodes[index];
                            final isCurrent =
                                wp.currentEpisode?.number == ep.number;
                            final percent =
                                wp.watchedPercentages[ep.number];
                            final effectiveAnime = anime ?? wp.anime;

                            return _SidebarEpisodeTile(
                              ep: ep,
                              anime: effectiveAnime,
                              isCurrent: isCurrent,
                              watchedPercent: percent,
                              accent: accent,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop();
                                if (!isCurrent) {
                                  wp.playEpisode(ep, accent: accent);
                                }
                              },
                              onOptions: effectiveAnime != null
                                  ? () {
                                      showEpisodeWatchOptionsSheet(
                                        context,
                                        episode: ep,
                                        watchProvider: wp,
                                        anime: effectiveAnime,
                                        accent: accent,
                                        onPlay: () {
                                          Navigator.of(context).pop();
                                          if (!isCurrent) {
                                            wp.playEpisode(ep, accent: accent);
                                          }
                                        },
                                      );
                                    }
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Individual Episode Tile in Sidebar
// ═════════════════════════════════════════════════════════════════════════

class _SidebarEpisodeTile extends StatelessWidget {
  const _SidebarEpisodeTile({
    required this.ep,
    required this.anime,
    required this.isCurrent,
    required this.watchedPercent,
    required this.accent,
    required this.onTap,
    this.onOptions,
  });

  final EpisodeItem ep;
  final AnimeMedia? anime;
  final bool isCurrent;
  final double? watchedPercent;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final thumbUrl = ep.image ?? anime?.bannerUrl ?? anime?.coverUrl;
    final isCompleted = watchedPercent != null && watchedPercent! >= 0.90;

    return Material(
      color: isCurrent
          ? accent.withValues(alpha: 0.12)
          : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
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
            border: Border.all(
              color: isCurrent
                  ? accent
                  : cs.outlineVariant.withValues(alpha: 0.20),
              width: isCurrent ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // ── Episode Thumbnail ──
              SizedBox(
                width: 106,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumbUrl != null)
                          CachedNetworkImage(
                            imageUrl: thumbUrl,
                            cacheManager: ImageCacheService.animeImageCache,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.movie_outlined,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                                size: 22,
                              ),
                            ),
                          )
                        else
                          Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(
                              Icons.movie_outlined,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                              size: 22,
                            ),
                          ),

                        // If currently playing, show overlay badge/icon
                        if (isCurrent)
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: accent,
                                size: 28,
                              ),
                            ),
                          ),

                        // Watched Progress Bar
                        if (watchedPercent != null && watchedPercent! > 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: LinearProgressIndicator(
                              value: watchedPercent,
                              backgroundColor: Colors.black45,
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                              minHeight: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // ── Episode Details ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'EP ${ep.number}',
                          style: TextStyle(
                            color: isCurrent ? accent : cs.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PLAYING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        if (ep.filler) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.40),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'FILLER',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (isCompleted) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green.shade400,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (onOptions != null)
                          InkResponse(
                            onTap: onOptions,
                            radius: 14,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.65),
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ep.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
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

