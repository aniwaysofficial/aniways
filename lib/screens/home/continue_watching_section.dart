import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:aniways/core/database/repositories/watch_repository.dart';
import 'package:aniways/core/helpers.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/navigation/main_navigation.dart' show pushFullScreen;
import 'package:aniways/screens/details/anime_details_screen.dart';
import 'package:aniways/screens/home/home_section.dart' show SectionHeader;

/// A horizontal section on the home screen showing anime the user is currently watching.
/// Automatically hides if there are no watch history records.
class ContinueWatchingSection extends StatelessWidget {
  const ContinueWatchingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inset = pageInset(context);

    return StreamBuilder<List<ContinueWatchingItem>>(
      stream: WatchRepository.instance.watchContinueWatching(limit: 15),
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null || items.isEmpty) {
          return const SizedBox.shrink();
        }

        final cardWidth = context.layoutSize.isCompact ? 220.0 : 250.0;
        final thumbHeight = cardWidth / (16 / 9);

        return Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Continue Watching',
                icon: Icons.play_circle_outline_rounded,
                color: cs.primary,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: thumbHeight + 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final imageUrl = (item.history.episodeThumbnail?.isNotEmpty ?? false)
                        ? item.history.episodeThumbnail!
                        : (item.anime.bannerUrl?.isNotEmpty ?? false)
                            ? item.anime.bannerUrl!
                            : (item.anime.coverUrl ?? '');

                    final hasProgress = item.duration > Duration.zero &&
                        item.position > Duration.zero &&
                        !item.isCompleted;
                    final progressTimeStr = hasProgress
                        ? '${formatDuration(item.position)} / ${formatDuration(item.duration)}'
                        : '';

                    final String subtitle;
                    if (item.history.episodeTitle != null &&
                        item.history.episodeTitle!.isNotEmpty) {
                      subtitle =
                          'EP ${item.episodeNumber} · ${item.history.episodeTitle!}';
                    } else {
                      subtitle = 'Play Episode ${item.episodeNumber}';
                    }

                    return SizedBox(
                      width: cardWidth,
                      child: InkWell(
                        onTap: () {
                          pushFullScreen(
                            context,
                            AnimeDetailsScreen(
                              anime: item.anime,
                              initialTab: 1,
                            ),
                          );
                        },
                        onLongPress: () {
                          _showOptions(context, item);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Thumbnail with progress bar ──────────────
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    height: thumbHeight,
                                    child: imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            cacheManager:
                                                ImageCacheService.animeImageCache,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) =>
                                                const Skeleton(radius: 0),
                                            errorWidget: (_, _, _) =>
                                                Container(
                                              color: cs.surfaceContainerHighest,
                                              child: Icon(
                                                Icons.movie_outlined,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: cs.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.movie_outlined,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                  ),
                                  // Subtle bottom scrim for progress bar clarity
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.6),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Episode Badge
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.72),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'EP ${item.episodeNumber}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Play center pill
                                  Positioned.fill(
                                    child: Center(
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Time seen & duration badge on thumbnail (bottom-right)
                                  if (progressTimeStr.isNotEmpty)
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.50),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          progressTimeStr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Progress bar
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: LinearProgressIndicator(
                                      value: item.percent.clamp(0.0, 1.0),
                                      minHeight: 3.5,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        cs.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ── Title & Episode info ─────────────────────
                            Text(
                              item.anime.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptions(BuildContext context, ContinueWatchingItem item) {
    showOneUiBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OneUiDragHandle(),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Remove from Continue Watching'),
                  onTap: () {
                    WatchRepository.instance.removeFromHistory(item.anime.id);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
