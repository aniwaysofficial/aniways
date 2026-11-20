import 'package:flutter/material.dart';

import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/models/playback_preference_options.dart';
import 'package:aniways/screens/settings/settings_components.dart';

/// Preferences screen for configuring default video playback, audio, subtitles,
/// automation, and player gestures.
class PlaybackPreferencesScreen extends StatefulWidget {
  const PlaybackPreferencesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PlaybackPreferencesScreen> createState() =>
      _PlaybackPreferencesScreenState();
}

class _PlaybackPreferencesScreenState extends State<PlaybackPreferencesScreen> {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  @override
  Widget build(BuildContext context) {
    final cat = CategoryColors.of(context);

    final defaultAudio = _prefs.defaultAudioTrack;
    final quality = _prefs.streamingQuality;
    final subLang = _prefs.subtitleLanguage;
    final subSize = _prefs.subtitleFontSize;
    final subColor = _prefs.subtitleTextColor;
    final subStyle = _prefs.subtitleOutlineStyle;
    final autoNext = _prefs.autoNextEpisode;
    final autoNextSecs = _prefs.autoNextDuration;
    final autoSkipIntro = _prefs.autoSkipIntro;
    final autoSkipOutro = _prefs.autoSkipOutro;
    final seekStep = _prefs.doubleTapSeekDuration;
    final swipeGestures = _prefs.enableSwipeGestures;
    final speedBoost = _prefs.enableLongPressSpeedBoost;
    final defaultAspect = _prefs.defaultAspectRatio;
    final defaultSpeed = _prefs.defaultPlaybackSpeed;
    final episodeLayout = _prefs.episodeViewMode;

    return Scaffold(
      body: OneUiScrollView(
        title: 'Player & Playback',
        showBackButton: !widget.embedded,
        bottomPadding: MediaQuery.viewPaddingOf(context).bottom + 24,
        children: [
          // ── Episode Display ─────────────────────────────────────────────
          const SettingsSectionHeader('Episode Display'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSelectorTile<EpisodeViewMode>(
                  icon: Icons.dashboard_customize_rounded,
                  color: cat.appearance,
                  title: 'Default Episode Layout',
                  subtitle: switch (episodeLayout) {
                    EpisodeViewMode.list =>
                      'List View (Thumbnails & Summaries)',
                    EpisodeViewMode.cards =>
                      'Card Grid (2–3 visual cards per row)',
                    EpisodeViewMode.compact =>
                      'Compact Numbers (Fast grid chips)',
                  },
                  currentValue: episodeLayout,
                  options: const [
                    SettingsOption(
                      EpisodeViewMode.list,
                      'List View',
                      'Full-width items with thumbnails & summaries',
                    ),
                    SettingsOption(
                      EpisodeViewMode.cards,
                      'Card Grid',
                      'Visual thumbnails in 2–3 columns',
                    ),
                    SettingsOption(
                      EpisodeViewMode.compact,
                      'Compact Numbers',
                      'Dense grid of episode number chips',
                    ),
                  ],
                  isFirst: true,
                  isLast: true,
                  onSelected: (val) async {
                    await _prefs.setEpisodeViewMode(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 1. Audio & Video Streams ────────────────────────────────────────
          const SettingsSectionHeader('Audio & Video Streams'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSelectorTile<String>(
                  icon: Icons.record_voice_over_rounded,
                  color: cat.playback,
                  title: 'Default Audio Track',
                  subtitle: defaultAudio == 'dub'
                      ? 'Dubbed (English / Localized)'
                      : 'Subtitled (Original with subtitles)',
                  currentValue: defaultAudio,
                  options: const [
                    SettingsOption(
                      'sub',
                      'Subtitled (Original)',
                      'Preferred for original voice acting',
                    ),
                    SettingsOption(
                      'dub',
                      'Dubbed',
                      'Preferred for localized voice overs',
                    ),
                  ],
                  isFirst: true,
                  isLast: false,
                  onSelected: (val) async {
                    await _prefs.setDefaultAudioTrack(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<String>(
                  icon: Icons.high_quality_rounded,
                  color: cat.accounts,
                  title: 'Preferred Streaming Quality',
                  subtitle: PlaybackQuality.format(quality),
                  currentValue: quality,
                  options: [
                    for (final q in PlaybackQuality.all)
                      SettingsOption(q.value, q.title, q.subtitle),
                  ],
                  isFirst: false,
                  isLast: true,
                  onSelected: (val) async {
                    await _prefs.setStreamingQuality(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 2. Subtitles & Styling ──────────────────────────────────────────
          const SettingsSectionHeader('Subtitles & Captions'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSelectorTile<String>(
                  icon: Icons.subtitles_rounded,
                  color: cat.appearance,
                  title: 'Preferred Subtitle Language',
                  subtitle: PlaybackLanguage.format(subLang),
                  currentValue: subLang,
                  options: [
                    for (final l in PlaybackLanguage.all)
                      SettingsOption(l.code, l.displayName, l.description),
                  ],
                  isFirst: true,
                  isLast: false,
                  onSelected: (val) async {
                    await _prefs.setSubtitleLanguage(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<double>(
                  icon: Icons.format_size_rounded,
                  color: cat.backup,
                  title: 'Subtitle Font Size',
                  subtitle: _formatFontSize(subSize),
                  currentValue: subSize,
                  options: const [
                    SettingsOption(14.0, 'Small (14sp)', 'Compact text size'),
                    SettingsOption(
                      18.0,
                      'Normal (18sp)',
                      'Default recommended size',
                    ),
                    SettingsOption(
                      22.0,
                      'Large (22sp)',
                      'Easier readability from distance',
                    ),
                    SettingsOption(
                      26.0,
                      'Extra Large (26sp)',
                      'Maximum visibility',
                    ),
                  ],
                  isFirst: false,
                  isLast: false,
                  onSelected: (val) async {
                    await _prefs.setSubtitleFontSize(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<String>(
                  icon: Icons.color_lens_outlined,
                  color: cat.playback,
                  title: 'Subtitle Text Color',
                  subtitle: _formatColorName(subColor),
                  currentValue: subColor,
                  options: const [
                    SettingsOption(
                      'white',
                      'Pure White',
                      'Traditional crisp anime subtitles',
                    ),
                    SettingsOption(
                      'yellow',
                      'Warm Yellow',
                      'High visibility on bright scenes',
                    ),
                    SettingsOption(
                      'cyan',
                      'Neon Cyan',
                      'Modern vivid subtitles',
                    ),
                  ],
                  isFirst: false,
                  isLast: false,
                  onSelected: (val) async {
                    await _prefs.setSubtitleTextColor(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<String>(
                  icon: Icons.border_style_rounded,
                  color: cat.downloads,
                  title: 'Outline & Contrast Style',
                  subtitle: _formatOutlineStyle(subStyle),
                  currentValue: subStyle,
                  options: const [
                    SettingsOption(
                      'outline',
                      'Black Stroke Outline',
                      'Sharp dark contour around letters',
                    ),
                    SettingsOption(
                      'background',
                      'Dark Box Background',
                      'Translucent black box behind text',
                    ),
                    SettingsOption(
                      'none',
                      'None (Clean Text)',
                      'No border or background',
                    ),
                  ],
                  isFirst: false,
                  isLast: false,
                  onSelected: (val) async {
                    await _prefs.setSubtitleOutlineStyle(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                // Live Subtitle Preview Container
                _SubtitlePreviewCard(
                  fontSize: subSize,
                  textColorName: subColor,
                  outlineStyle: subStyle,
                  isFirst: false,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 3. Playback Automation ──────────────────────────────────────────
          const SettingsSectionHeader('Automation'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.skip_next_rounded,
                  color: cat.playback,
                  title: 'Auto-Next Episode',
                  subtitle:
                      'Automatically start the next episode when current ends',
                  value: autoNext,
                  isFirst: true,
                  isLast: false,
                  onChanged: (val) async {
                    await _prefs.setAutoNextEpisode(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<int>(
                  icon: Icons.timer_outlined,
                  color: cat.accounts,
                  title: 'Countdown Duration',
                  subtitle: autoNextSecs == 0
                      ? 'Immediate (0s)'
                      : '$autoNextSecs seconds before next episode',
                  currentValue: autoNextSecs,
                  options: const [
                    SettingsOption(
                      0,
                      'Immediate',
                      'Play next episode without countdown',
                    ),
                    SettingsOption(3, '3 seconds', 'Brief transition'),
                    SettingsOption(
                      5,
                      '5 seconds (Default)',
                      'Balanced countdown with cancel option',
                    ),
                    SettingsOption(
                      10,
                      '10 seconds',
                      'Longer window to review or pause',
                    ),
                  ],
                  isFirst: false,
                  isLast: false,
                  onSelected: autoNext
                      ? (val) async {
                          await _prefs.setAutoNextDuration(val);
                          setState(() {});
                        }
                      : null,
                ),
                const SizedBox(height: 2),
                SettingsSwitchTile(
                  icon: Icons.fast_forward_rounded,
                  color: cat.backup,
                  title: 'Auto-Skip Intro (OP)',
                  subtitle:
                      'Automatically skip opening theme songs when detected',
                  value: autoSkipIntro,
                  isFirst: false,
                  isLast: false,
                  onChanged: (val) async {
                    await _prefs.setAutoSkipIntro(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSwitchTile(
                  icon: Icons.fast_forward_rounded,
                  color: cat.downloads,
                  title: 'Auto-Skip Outro (ED)',
                  subtitle:
                      'Automatically jump past ending themes when detected',
                  value: autoSkipOutro,
                  isFirst: false,
                  isLast: true,
                  onChanged: (val) async {
                    await _prefs.setAutoSkipOutro(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 4. Player Controls & Gestures ───────────────────────────────────
          const SettingsSectionHeader('Controls & Gestures'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSelectorTile<int>(
                  icon: Icons.replay_10_rounded,
                  color: cat.playback,
                  title: 'Double-Tap Seek Step',
                  subtitle: '${seekStep}s per double-tap',
                  currentValue: seekStep,
                  options: const [
                    SettingsOption(5, '5 seconds', 'Fine-grained seeking'),
                    SettingsOption(
                      10,
                      '10 seconds (Default)',
                      'Standard playback seeking',
                    ),
                    SettingsOption(15, '15 seconds', 'Faster scrubbing'),
                    SettingsOption(30, '30 seconds', 'Jump past long dialogs'),
                  ],
                  isFirst: true,
                  isLast: false,
                  onSelected: (val) async {
                    await _prefs.setDoubleTapSeekDuration(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSwitchTile(
                  icon: Icons.swipe_vertical_rounded,
                  color: cat.appearance,
                  title: 'Swipe for Brightness & Volume',
                  subtitle: 'Left side controls brightness, right side controls volume',
                  value: swipeGestures,
                  isFirst: false,
                  isLast: false,
                  onChanged: (val) async {
                    await _prefs.setEnableSwipeGestures(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSwitchTile(
                  icon: Icons.speed_rounded,
                  color: cat.accounts,
                  title: 'Hold for 2× Speed Boost',
                  subtitle: 'Press and hold anywhere on the video to temporarily boost speed',
                  value: speedBoost,
                  isFirst: false,
                  isLast: false,
                  onChanged: (val) async {
                    await _prefs.setEnableLongPressSpeedBoost(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<String>(
                  icon: Icons.aspect_ratio_rounded,
                  color: cat.backup,
                  title: 'Default Aspect Ratio',
                  subtitle: _formatAspect(defaultAspect),
                  currentValue: defaultAspect,
                  options: const [
                    SettingsOption(
                      'fit',
                      'Fit (16:9)',
                      'Standard aspect ratio with letterboxing',
                    ),
                    SettingsOption(
                      'zoom',
                      'Fill Screen (Crop)',
                      'Expands video to fill full device screen',
                    ),
                    SettingsOption(
                      'stretch',
                      'Stretch to Screen',
                      'Stretches video to fill screen edges',
                    ),
                    SettingsOption(
                      'ratio4x3',
                      'Classic 4:3',
                      'Ideal for classic and retro anime',
                    ),
                  ],
                  isFirst: false,
                  isLast: false,
                  onSelected: (val) async {
                    await _prefs.setDefaultAspectRatio(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<double>(
                  icon: Icons.slow_motion_video_rounded,
                  color: cat.downloads,
                  title: 'Default Playback Speed',
                  subtitle: '${defaultSpeed}x',
                  currentValue: defaultSpeed,
                  options: const [
                    SettingsOption(0.75, '0.75×', 'Slow motion'),
                    SettingsOption(1.0, '1.0× (Normal)', 'Standard speed'),
                    SettingsOption(1.25, '1.25×', 'Slightly faster'),
                    SettingsOption(1.5, '1.5×', 'Fast'),
                    SettingsOption(2.0, '2.0×', 'Double speed'),
                  ],
                  isFirst: false,
                  isLast: true,
                  onSelected: (val) async {
                    await _prefs.setDefaultPlaybackSpeed(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatFontSize(double s) {
    if (s <= 14.5) return 'Small (14sp)';
    if (s <= 18.5) return 'Normal (18sp)';
    if (s <= 22.5) return 'Large (22sp)';
    return 'Extra Large (26sp)';
  }

  static String _formatColorName(String c) {
    return switch (c) {
      'yellow' => 'Warm Yellow',
      'cyan' => 'Neon Cyan',
      _ => 'Pure White',
    };
  }

  static String _formatOutlineStyle(String s) {
    return switch (s) {
      'background' => 'Dark Box Background',
      'none' => 'None (Clean Text)',
      _ => 'Black Stroke Outline',
    };
  }

  static String _formatAspect(String a) {
    return switch (a) {
      'zoom' => 'Fill Screen (Crop)',
      'stretch' => 'Stretch to Screen',
      'ratio4x3' => 'Classic 4:3',
      _ => 'Fit (16:9)',
    };
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Subtitle Preview Card
// ═════════════════════════════════════════════════════════════════════════

/// Live interactive preview of subtitle rendering.
class _SubtitlePreviewCard extends StatelessWidget {
  const _SubtitlePreviewCard({
    required this.fontSize,
    required this.textColorName,
    required this.outlineStyle,
    required this.isFirst,
    required this.isLast,
  });

  final double fontSize;
  final String textColorName;
  final String outlineStyle;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color textColor = switch (textColorName) {
      'yellow' => const Color(0xFFFFEB3B),
      'cyan' => const Color(0xFF00E5FF),
      _ => Colors.white,
    };

    final isOutline = outlineStyle == 'outline';
    final isBackground = outlineStyle == 'background';

    return Material(
      color: cs.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: settingsTileBorderRadius(
          isFirst: isFirst,
          isLast: isLast,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.remove_red_eye_outlined,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Live Subtitle Preview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1C24),
                    Color(0xFF2E3240),
                    Color(0xFF14161D),
                  ],
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: isBackground
                    ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                    : EdgeInsets.zero,
                decoration: isBackground
                    ? BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  'Watashi ga kita! (I am here!)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    shadows: isOutline
                        ? [
                            const Shadow(
                              offset: Offset(-1.5, -1.5),
                              color: Colors.black,
                            ),
                            const Shadow(
                              offset: Offset(1.5, -1.5),
                              color: Colors.black,
                            ),
                            const Shadow(
                              offset: Offset(1.5, 1.5),
                              color: Colors.black,
                            ),
                            const Shadow(
                              offset: Offset(-1.5, 1.5),
                              color: Colors.black,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
