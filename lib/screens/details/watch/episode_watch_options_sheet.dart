import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/providers/watch_provider.dart';

/// Opens a bottom sheet providing manual episode watch state controls:
/// - Mark episode watched / unwatched
/// - Mark all previous episodes watched
/// - Unmark previous episodes
/// - Quick play episode
Future<void> showEpisodeWatchOptionsSheet(
  BuildContext context, {
  required EpisodeItem episode,
  required WatchProvider watchProvider,
  required AnimeMedia anime,
  required Color accent,
  VoidCallback? onPlay,
}) async {
  await showOneUiBottomSheet<void>(
    context: context,
    builder: (ctx) => _EpisodeWatchOptionsContent(
      episode: episode,
      watchProvider: watchProvider,
      anime: anime,
      accent: accent,
      onPlay: onPlay,
    ),
  );
}

class _EpisodeWatchOptionsContent extends StatelessWidget {
  const _EpisodeWatchOptionsContent({
    required this.episode,
    required this.watchProvider,
    required this.anime,
    required this.accent,
    this.onPlay,
  });

  final EpisodeItem episode;
  final WatchProvider watchProvider;
  final AnimeMedia anime;
  final Color accent;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final watchedPercent = watchProvider.watchedPercentages[episode.number];
    final isCompleted = watchedPercent != null && watchedPercent >= 0.90;
    final isCurrentPlaying =
        watchProvider.currentEpisode?.number == episode.number;

    // Check if any episode up to this one has any watch progress
    final hasWatchedPrevious =
        episode.number > 1 &&
        watchProvider.watchedPercentages.entries.any(
          (e) => e.key <= episode.number && e.value > 0,
        );

    // Check if any episode up to this one is not yet fully completed
    final previousEpisodes = watchProvider.allEpisodesForAudio
        .where((e) => e.number <= episode.number)
        .toList();
    final hasUnwatchedPrevious =
        episode.number > 1 &&
        (previousEpisodes.isNotEmpty
            ? previousEpisodes.any((e) {
                final p = watchProvider.watchedPercentages[e.number];
                return p == null || p < 0.90;
              })
            : !isCompleted);

    final thumbUrl = episode.image ?? anime.bannerUrl ?? anime.coverUrl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag Handle ──
            const OneUiDragHandle(margin: EdgeInsets.only(bottom: 14)),

            // ── Episode Info Card ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  // Thumbnail preview
                  SizedBox(
                    width: 104,
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
                                    Icons.movie_rounded,
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                    size: 22,
                                  ),
                                ),
                              )
                            else
                              Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.movie_rounded,
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                  size: 22,
                                ),
                              ),

                            if (episode.filler)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade900.withValues(
                                      alpha: 0.85,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'FILLER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),

                            // Watched Progress Bar
                            if (watchedPercent != null && watchedPercent > 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LinearProgressIndicator(
                                  value: watchedPercent,
                                  minHeight: 2.5,
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
                  ),

                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'EPISODE ${episode.number}',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            if (isCompleted)
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade400,
                                size: 16,
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          episode.title.isNotEmpty
                              ? episode.title
                              : 'Episode ${episode.number}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Watch Actions List ──
            // 1. Mark watched / unwatched
            if (isCompleted)
              _ActionTile(
                icon: Icons.remove_done_rounded,
                iconColor: Colors.orange.shade400,
                iconBgColor: Colors.orange.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
                title: 'Mark as unwatched',
                subtitle: 'Clear watch progress for Episode ${episode.number}',
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  await watchProvider.markEpisodeUnwatched(episode);
                  if (context.mounted) {
                    AniwaysSnackBar.show(
                      context,
                      message: 'Marked Episode ${episode.number} as unwatched',
                      icon: Icons.history_toggle_off_rounded,
                    );
                  }
                },
              )
            else
              _ActionTile(
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green.shade400,
                iconBgColor: Colors.green.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
                title: 'Mark as watched',
                subtitle: 'Set Episode ${episode.number} as completed',
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  await watchProvider.markEpisodeWatched(episode);
                  if (context.mounted) {
                    AniwaysSnackBar.show(
                      context,
                      message: 'Marked Episode ${episode.number} as watched',
                      icon: Icons.check_circle_outline_rounded,
                    );
                  }
                },
              ),

            // 2. Mark previous episodes watched (only if there are unwatched prior episodes)
            if (hasUnwatchedPrevious) ...[
              const SizedBox(height: 6),
              _ActionTile(
                icon: Icons.done_all_rounded,
                iconColor: accent,
                iconBgColor: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                title: 'Mark episodes 1–${episode.number} as watched',
                subtitle:
                    'Set all episodes up to #${episode.number} as completed',
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  await watchProvider.markPreviousEpisodesWatched(episode);
                  if (context.mounted) {
                    AniwaysSnackBar.show(
                      context,
                      message: 'Marked episodes 1–${episode.number} as watched',
                      icon: Icons.done_all_rounded,
                    );
                  }
                },
              ),
            ],

            // 3. Unmark previous episodes (only if at least one prior episode was watched)
            if (hasWatchedPrevious) ...[
              const SizedBox(height: 6),
              _ActionTile(
                icon: Icons.history_toggle_off_rounded,
                iconColor: cs.error,
                iconBgColor: cs.error.withValues(alpha: isDark ? 0.18 : 0.12),
                title: 'Unmark episodes 1–${episode.number}',
                subtitle:
                    'Clear watch progress for all episodes up to #${episode.number}',
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  await watchProvider.unmarkPreviousEpisodes(episode);
                  if (context.mounted) {
                    AniwaysSnackBar.show(
                      context,
                      message: 'Unmarked episodes 1–${episode.number}',
                      icon: Icons.history_toggle_off_rounded,
                    );
                  }
                },
              ),
            ],

            // 4. Play episode action (if not currently playing)
            if (!isCurrentPlaying && onPlay != null) ...[
              const SizedBox(height: 6),
              _ActionTile(
                icon: Icons.play_arrow_rounded,
                iconColor: accent,
                iconBgColor: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                title: 'Play Episode ${episode.number}',
                subtitle: episode.title.isNotEmpty
                    ? episode.title
                    : 'Start playback now',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                  onPlay!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.70),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
