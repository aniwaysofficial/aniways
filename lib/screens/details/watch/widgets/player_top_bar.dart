import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/providers/watch_provider.dart';
import 'package:aniways/screens/details/watch/player_episode_sidebar.dart';
import 'package:aniways/screens/details/watch/watch_settings_sheet.dart';

/// Top bar with anime/episode details, provider badge, and player utility actions.
class ControlsTopBar extends StatelessWidget {
  const ControlsTopBar({
    super.key,
    required this.wp,
    required this.accent,
    required this.onInteract,
    this.anime,
    this.onBack,
  });

  final WatchProvider wp;
  final Color accent;
  final AnimeMedia? anime;
  final VoidCallback onInteract;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Back',
              onPressed: () {
                HapticFeedback.selectionClick();
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ),

          // Episode info & provider badge
          if (wp.currentEpisode != null)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EP ${wp.currentEpisode!.number} · ${wp.currentEpisode!.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (wp.selectedProviderId != null &&
                      wp.selectedProviderId!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onInteract();
                        WatchSettingsSheet.show(
                          context,
                          wp,
                          accent,
                          initialCategory: WatchSettingsCategory.provider,
                        );
                      },
                      child: Text(
                        wp.activeProviderDisplayName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            const Spacer(),

          // Next Episode button
          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              color: wp.hasNextEpisode ? Colors.white : Colors.white30,
              size: 24,
            ),
            tooltip: 'Next Episode',
            onPressed: wp.hasNextEpisode
                ? () {
                    HapticFeedback.selectionClick();
                    wp.playNextEpisode();
                    onInteract();
                  }
                : null,
          ),

          // Episodes sidebar button
          IconButton(
            icon: const Icon(
              Icons.video_library_rounded,
              color: Colors.white,
              size: 21,
            ),
            tooltip: 'Episodes',
            onPressed: () {
              onInteract();
              PlayerEpisodeSidebar.show(
                context,
                wp: wp,
                accent: accent,
                anime: anime,
              );
            },
          ),

          // Lock controls button
          IconButton(
            icon: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Lock controls',
            onPressed: () {
              HapticFeedback.selectionClick();
              wp.toggleControlsLock();
            },
          ),

          // Settings sheet button
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            tooltip: 'Quality & Stream Settings',
            onPressed: () {
              onInteract();
              WatchSettingsSheet.show(context, wp, accent);
            },
          ),
        ],
      ),
    );
  }
}

