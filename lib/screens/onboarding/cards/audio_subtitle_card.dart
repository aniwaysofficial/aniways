import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/models/playback_preference_options.dart';
import 'package:aniways/screens/onboarding/widgets/onboarding_card_scaffold.dart';

/// Step 2: Audio track, subtitle language and default stream quality.
/// Uses the same icons and category colors as Player & Playback settings.
class AudioSubtitleCard extends StatefulWidget {
  const AudioSubtitleCard({super.key});

  @override
  State<AudioSubtitleCard> createState() => _AudioSubtitleCardState();
}

class _AudioSubtitleCardState extends State<AudioSubtitleCard> {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  late String _audioTrack;
  late String _subLang;
  late String _quality;

  @override
  void initState() {
    super.initState();
    _audioTrack = _prefs.defaultAudioTrack;
    _subLang = _prefs.subtitleLanguage;
    _quality = _prefs.streamingQuality;
  }

  void _showLanguagePicker(BuildContext context) {
    HapticFeedback.selectionClick();
    showOneUiBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OneUiDragHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtitle language',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose your preferred language for subtitles',
                        style: Theme.of(sheetContext).textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: PlaybackLanguage.all.length,
                    itemBuilder: (_, index) {
                      final lang = PlaybackLanguage.all[index];
                      final isSelected = lang.code == _subLang;

                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? cs.primary : cs.outline,
                          size: 22,
                        ),
                        title: Text(
                          lang.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          lang.nativeOrRegion,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _subLang = lang.code);
                          _prefs.setSubtitleLanguage(lang.code);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = CategoryColors.of(context);
    final cs = Theme.of(context).colorScheme;

    return OnboardingPage(
      title: 'How you watch',
      subtitle: 'Aniways uses these defaults whenever you start a stream.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingSection(
            title: 'Default audio',
            child: OnboardingGroup(
              tiles: [
                OnboardingTile(
                  icon: Icons.subtitles_rounded,
                  color: cat.appearance,
                  title: 'Subtitled',
                  subtitle: 'Original audio with subtitles',
                  selected: _audioTrack == 'sub',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _audioTrack = 'sub');
                    _prefs.setDefaultAudioTrack('sub');
                  },
                ),
                OnboardingTile(
                  icon: Icons.record_voice_over_rounded,
                  color: cat.playback,
                  title: 'Dubbed',
                  subtitle: 'Languages beyond the original',
                  selected: _audioTrack == 'dub',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _audioTrack = 'dub');
                    _prefs.setDefaultAudioTrack('dub');
                  },
                ),
              ],
            ),
          ),
          OnboardingSection(
            title: 'Subtitle language',
            child: OnboardingGroup(
              tiles: [
                OnboardingTile(
                  icon: Icons.translate_rounded,
                  color: cat.appearance,
                  title: 'Preferred subtitle language',
                  subtitle: PlaybackLanguage.format(_subLang),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  onTap: () => _showLanguagePicker(context),
                ),
              ],
            ),
          ),
          OnboardingSection(
            title: 'Stream quality',
            child: OnboardingGroup(
              tiles: [
                for (final q in PlaybackQuality.all)
                  OnboardingTile(
                    icon: q.icon,
                    color: switch (q.value) {
                      'auto' => cat.playback,
                      '1080p' => cat.appearance,
                      '720p' => cat.accounts,
                      '480p' => cat.downloads,
                      _ => cat.appearance,
                    },
                    title: q.title,
                    subtitle: q.subtitle,
                    selected: _quality == q.value,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _quality = q.value);
                      _prefs.setStreamingQuality(q.value);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
