import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/providers/watch_provider.dart';

/// Center playback controls: Rewind, Play/Pause/Buffering, and Fast-Forward.
class CenterTransportBar extends StatelessWidget {
  const CenterTransportBar({
    super.key,
    required this.wp,
    required this.accent,
    required this.onInteract,
    required this.controlsAnimation,
  });

  final WatchProvider wp;
  final Color accent;
  final VoidCallback onInteract;
  final Animation<double> controlsAnimation;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: wp.isInitializedNotifier,
      builder: (context, isInitialized, _) {
        final seekStep = SharedPreferencesService().doubleTapSeekDuration;
        final rewindIcon = switch (seekStep) {
          5 => Icons.replay_5_rounded,
          30 => Icons.replay_30_rounded,
          _ => Icons.replay_10_rounded,
        };
        final forwardIcon = switch (seekStep) {
          5 => Icons.forward_5_rounded,
          30 => Icons.forward_30_rounded,
          _ => Icons.forward_10_rounded,
        };

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rewind (fades with controls overlay)
            FadeTransition(
              opacity: controlsAnimation,
              child: AnimatedBuilder(
                animation: controlsAnimation,
                builder: (context, child) {
                  return IgnorePointer(
                    ignoring: controlsAnimation.value <= 0.05,
                    child: child,
                  );
                },
                child: IconButton(
                  icon: Icon(
                    rewindIcon,
                    color: isInitialized ? Colors.white : Colors.white38,
                    size: 34,
                  ),
                  onPressed: isInitialized
                      ? () {
                          HapticFeedback.selectionClick();
                          wp.seekRelative(Duration(seconds: -seekStep));
                          onInteract();
                        }
                      : null,
                ),
              ),
            ),

            const SizedBox(width: 28),

            // Center Play / Pause / Buffering Indicator
            // When buffering/loading: persistent spinner (always visible, true screen center)
            // When playing/paused: Play/Pause button (fades with controls overlay)
            // When loading AND controls overlay visible: spinner surrounds the Play/Pause button!
            ListenableBuilder(
              listenable: Listenable.merge([
                wp,
                wp.isBufferingNotifier,
                wp.isInitializedNotifier,
              ]),
              builder: (context, _) {
                final isStreaming =
                    wp.state == WatchState.loadingStream ||
                    wp.state == WatchState.loading;
                final isBuffering = wp.isBufferingNotifier.value;
                final isInit =
                    wp.isInitializedNotifier.value && wp.isVideoInitialized;
                final isLoading = isStreaming || isBuffering || !isInit;

                return SizedBox(
                  width: 86,
                  height: 86,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Loading / Buffering Spinner (always visible at opacity 1 when loading)
                      if (isLoading)
                        IgnorePointer(
                          child: SizedBox(
                            width: 86,
                            height: 86,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ),

                      // Play / Pause Button (fades in/out with controls overlay)
                      FadeTransition(
                        opacity: controlsAnimation,
                        child: AnimatedBuilder(
                          animation: controlsAnimation,
                          builder: (context, child) {
                            return IgnorePointer(
                              ignoring: controlsAnimation.value <= 0.05,
                              child: child,
                            );
                          },
                          child: ValueListenableBuilder<bool>(
                            valueListenable: wp.isPlayingNotifier,
                            builder: (context, isPlaying, _) {
                              return Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.60),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isLoading
                                        ? Colors.white24
                                        : Colors.white38,
                                    width: 1.5,
                                  ),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 52,
                                  ),
                                  onPressed: isInit
                                      ? () {
                                          HapticFeedback.selectionClick();
                                          wp.togglePlay();
                                          onInteract();
                                        }
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(width: 28),

            // Forward (fades with controls overlay)
            FadeTransition(
              opacity: controlsAnimation,
              child: AnimatedBuilder(
                animation: controlsAnimation,
                builder: (context, child) {
                  return IgnorePointer(
                    ignoring: controlsAnimation.value <= 0.05,
                    child: child,
                  );
                },
                child: IconButton(
                  icon: Icon(
                    forwardIcon,
                    color: isInitialized ? Colors.white : Colors.white38,
                    size: 34,
                  ),
                  onPressed: isInitialized
                      ? () {
                          HapticFeedback.selectionClick();
                          wp.seekRelative(Duration(seconds: seekStep));
                          onInteract();
                        }
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Floating action button to quickly skip opening/ending sequences.
class SkipButton extends StatelessWidget {
  const SkipButton({
    super.key,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fast_forward_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
