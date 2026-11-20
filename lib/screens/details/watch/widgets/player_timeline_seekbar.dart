import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/helpers.dart';
import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/providers/watch_provider.dart';
import 'package:aniways/screens/details/watch/watch_settings_sheet.dart';

/// Interactive timeline slider, intro/outro markers, timestamps, and bottom utility toolbar
/// (Speed, Audio, Subtitles, Quality, Aspect Ratio).
class TimelineSeekbar extends StatefulWidget {
  const TimelineSeekbar({
    super.key,
    required this.wp,
    required this.accent,
    required this.onInteract,
    this.fmt = formatDuration,
  });

  final WatchProvider wp;
  final Color accent;
  final String Function(Duration) fmt;
  final VoidCallback onInteract;

  @override
  State<TimelineSeekbar> createState() => _TimelineSeekbarState();
}

class _TimelineSeekbarState extends State<TimelineSeekbar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final wp = widget.wp;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: ValueListenableBuilder<Duration>(
        valueListenable: wp.durationNotifier,
        builder: (context, totalDuration, _) {
          return ValueListenableBuilder<Duration>(
            valueListenable: wp.positionNotifier,
            builder: (context, currentPosition, _) {
              final totalMs = totalDuration.inMilliseconds;
              final currentMs = currentPosition.inMilliseconds;
              final progress = totalMs > 0
                  ? (currentMs / totalMs).clamp(0.0, 1.0)
                  : 0.0;
              final effectiveProgress = _dragValue ?? progress;
              final effectivePosition = _dragValue != null && totalMs > 0
                  ? Duration(milliseconds: (_dragValue! * totalMs).round())
                  : currentPosition;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Track with intro / outro markers
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Intro marker line
                      if (wp.watchResult?.intro != null &&
                          totalDuration.inSeconds > 0)
                        MarkerLine(
                          range: wp.watchResult!.intro!,
                          total: totalDuration.inSeconds,
                          color: Colors.amber.withValues(alpha: 0.8),
                        ),
                      // Outro marker line
                      if (wp.watchResult?.outro != null &&
                          totalDuration.inSeconds > 0)
                        MarkerLine(
                          range: wp.watchResult!.outro!,
                          total: totalDuration.inSeconds,
                          color: Colors.amber.withValues(alpha: 0.8),
                        ),

                      ValueListenableBuilder<Duration>(
                        valueListenable: wp.bufferedNotifier,
                        builder: (context, bufferedDuration, _) {
                          final bufferedMs = bufferedDuration.inMilliseconds;
                          final bufferedProgress = totalMs > 0
                              ? (bufferedMs / totalMs).clamp(0.0, 1.0)
                              : 0.0;
                          final secondaryProgress =
                              bufferedProgress > effectiveProgress
                                  ? bufferedProgress
                                  : null;

                          return SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3.5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                              activeTrackColor: widget.accent,
                              secondaryActiveTrackColor:
                                  Colors.white.withValues(alpha: 0.38),
                              disabledSecondaryActiveTrackColor:
                                  Colors.white.withValues(alpha: 0.20),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: wp.isInitializedNotifier,
                              builder: (context, isInitialized, _) {
                                final canSeek = totalMs > 0 && isInitialized;
                                return Slider(
                                  value: effectiveProgress.clamp(0.0, 1.0),
                                  secondaryTrackValue:
                                      canSeek ? secondaryProgress : null,
                                  onChangeStart: canSeek
                                      ? (val) {
                                          setState(() => _dragValue = val);
                                          widget.onInteract();
                                        }
                                      : null,
                                  onChanged: canSeek
                                      ? (val) {
                                          setState(() => _dragValue = val);
                                          widget.onInteract();
                                        }
                                      : null,
                                  onChangeEnd: canSeek
                                      ? (val) {
                                          final target = Duration(
                                            milliseconds: (val * totalMs).round(),
                                          );
                                          wp.seek(target);
                                          setState(() => _dragValue = null);
                                          widget.onInteract();
                                        }
                                      : null,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 14,
                      right: 6,
                      bottom: 2,
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.fmt(effectivePosition),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          ' / ',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          widget.fmt(totalDuration),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                          ),
                        ),
                        const Spacer(),
                        ListenableBuilder(
                          listenable: wp,
                          builder: (context, _) {
                            final hasSubs = wp.hasActiveSubtitles;
                            final qHeight = wp.currentQualityHeight;
                            final isAuto = wp.isAutoQuality;
                            final isDub = wp.selectedAudio == StreamAudio.dub;
                            final hasDub = wp.hasDub;

                            final IconData qualityIcon;
                            if (!isAuto && qHeight >= 1080) {
                              qualityIcon = Icons.hd_rounded;
                            } else if (!isAuto && qHeight >= 720) {
                              qualityIcon = Icons.hd_outlined;
                            } else if (!isAuto && qHeight > 0) {
                              qualityIcon = Icons.sd_outlined;
                            } else {
                              qualityIcon = Icons.auto_awesome_rounded;
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Speed Button
                                PlayerActionButton(
                                  icon: Icons.speed_rounded,
                                  label:
                                      '${wp.playbackSpeed == 1.0 ? '1' : wp.playbackSpeed}×',
                                  tooltip: 'Playback Speed',
                                  isActive: wp.playbackSpeed != 1.0,
                                  accent: widget.accent,
                                  onTap: () {
                                    widget.onInteract();
                                    WatchSettingsSheet.show(
                                      context,
                                      wp,
                                      widget.accent,
                                      initialCategory:
                                          WatchSettingsCategory.speed,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),

                                // Audio Track (Sub / Dub) Button
                                PlayerActionButton(
                                  icon: isDub
                                      ? Icons.record_voice_over_rounded
                                      : Icons.record_voice_over_outlined,
                                  label: isDub ? 'DUB' : 'SUB',
                                  tooltip: hasDub
                                      ? (isDub
                                            ? 'Audio: Dubbed (Tap for Sub)'
                                            : 'Audio: Subtitled (Tap for Dub)')
                                      : 'Audio: Subtitled (Dub unavailable)',
                                  isActive: isDub,
                                  isEnabled: hasDub || isDub,
                                  accent: widget.accent,
                                  onTap: () {
                                    widget.onInteract();
                                    WatchSettingsSheet.show(
                                      context,
                                      wp,
                                      widget.accent,
                                      initialCategory:
                                          WatchSettingsCategory.audio,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),

                                // Subtitles Button
                                PlayerActionButton(
                                  icon: hasSubs
                                      ? Icons.subtitles_rounded
                                      : Icons.subtitles_outlined,
                                  label: wp.currentSubtitleLabel,
                                  tooltip:
                                      'Subtitles (${wp.currentSubtitleLabel})',
                                  isActive: hasSubs,
                                  accent: widget.accent,
                                  onTap: () {
                                    widget.onInteract();
                                    WatchSettingsSheet.show(
                                      context,
                                      wp,
                                      widget.accent,
                                      initialCategory:
                                          WatchSettingsCategory.subtitles,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),

                                // Quality & Server Button
                                PlayerActionButton(
                                  icon: qualityIcon,
                                  label: wp.currentQualityLabel,
                                  tooltip:
                                      'Quality (${wp.currentQualityLabel}) & Server',
                                  isActive: !isAuto,
                                  accent: widget.accent,
                                  onTap: () {
                                    widget.onInteract();
                                    WatchSettingsSheet.show(
                                      context,
                                      wp,
                                      widget.accent,
                                      initialCategory:
                                          WatchSettingsCategory.quality,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),

                                // Aspect Ratio Button (Fit, Fill/Zoom, Stretch, 4:3)
                                PlayerActionButton(
                                  icon: wp.currentAspectRatioIcon,
                                  label: wp.currentAspectRatioLabel,
                                  tooltip:
                                      'Aspect Ratio: ${wp.currentAspectRatioDescription}',
                                  isActive:
                                      wp.currentAspectRatio !=
                                      PlayerAspectRatio.fit,
                                  accent: widget.accent,
                                  onTap: () {
                                    widget.onInteract();
                                    final size = MediaQuery.sizeOf(context);
                                    final screenAspect =
                                        size.width /
                                        (size.height > 0 ? size.height : 1.0);
                                    wp.cycleAspectRatio(screenAspect);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class PlayerActionButton extends StatelessWidget {
  const PlayerActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
    this.isEnabled = true,
    this.accent = Colors.white,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;
  final bool isEnabled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? accent
        : (isEnabled
              ? Colors.white.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.38));
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 1.5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: 0.2,
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

class MarkerLine extends StatelessWidget {
  const MarkerLine({
    super.key,
    required this.range,
    required this.total,
    required this.color,
  });

  final TimeRange range;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final startRatio = (range.start / total).clamp(0.0, 1.0);
    final endRatio = (range.end / total).clamp(0.0, 1.0);
    final widthRatio = (endRatio - startRatio).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth =
            constraints.maxWidth - 28; // Slider inset padding (14 on each side)
        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              margin: EdgeInsets.only(left: trackWidth * startRatio),
              width: trackWidth * widthRatio,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

