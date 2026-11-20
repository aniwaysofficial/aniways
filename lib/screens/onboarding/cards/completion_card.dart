import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aniways/core/services/backup_restore_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/providers/theme_provider.dart';
import 'package:aniways/screens/onboarding/widgets/onboarding_card_scaffold.dart';

/// Final step: a recap of the choices. Tapping a row jumps back to that step.
/// The "Start watching" button lives in the screen shell.
class CompletionCard extends StatelessWidget {
  const CompletionCard({super.key, required this.onEdit});

  /// Called with the page index of the step to edit.
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = CategoryColors.of(context);
    final theme = context.watch<ThemeProvider>();
    final prefs = SharedPreferencesService();

    final themeModeStr = switch (theme.themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      ThemeMode.system => 'Follows system',
    };

    final paletteStr = theme.dynamicTheme
        ? 'Dynamic color'
        : theme.colorPreset.label;

    final lang = prefs.subtitleLanguage.toUpperCase();
    final audioStr = prefs.defaultAudioTrack == 'dub'
        ? 'Dubbed, $lang subtitles'
        : 'Subtitled, $lang';
    final qualityStr = prefs.streamingQuality == 'auto'
        ? 'Auto quality'
        : prefs.streamingQuality;

    final notifyOn = prefs.notificationEnabled;
    final notifyStr = notifyOn ? 'Active' : 'Disabled';

    final backupFolder = BackupRestoreService.instance
        .getBackupLocationDisplayName();
    final autoBackupStr = switch (prefs.autoBackupFrequency) {
      'daily' => 'Daily backups',
      'weekly' => 'Weekly backups',
      _ => 'Manual backups',
    };

    final animeCount = prefs.onboardingFavoriteAnimeIds.length;
    final tasteStr = animeCount == 0
        ? 'Default recommendations'
        : '$animeCount favorite${animeCount == 1 ? '' : 's'} selected';

    Widget edit() =>
        Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant);

    return OnboardingPage(
      title: "You're all set",
      subtitle: 'Tap any row to change it. Everything is also in Settings.',
      body: OnboardingSection(
        title: 'Your setup',
        child: OnboardingGroup(
          tiles: [
            OnboardingTile(
              icon: Icons.palette_outlined,
              color: cat.appearance,
              title: 'Appearance',
              subtitle: '$themeModeStr, $paletteStr',
              trailing: edit(),
              onTap: () => onEdit(1),
            ),
            OnboardingTile(
              icon: Icons.play_circle_outline_rounded,
              color: cat.playback,
              title: 'Player & playback',
              subtitle: '$audioStr, $qualityStr',
              trailing: edit(),
              onTap: () => onEdit(2),
            ),
            OnboardingTile(
              icon: Icons.notifications_active_outlined,
              color: cat.playback,
              title: 'Notifications',
              subtitle: notifyStr,
              trailing: edit(),
              onTap: () => onEdit(3),
            ),
            OnboardingTile(
              icon: Icons.folder_outlined,
              color: cat.backup,
              title: 'Backups',
              subtitle: '$autoBackupStr to $backupFolder',
              trailing: edit(),
              onTap: () => onEdit(4),
            ),
            OnboardingTile(
              icon: Icons.auto_awesome_outlined,
              color: cat.downloads,
              title: 'Your taste',
              subtitle: tasteStr,
              trailing: edit(),
              onTap: () => onEdit(5),
            ),
          ],
        ),
      ),
    );
  }
}
