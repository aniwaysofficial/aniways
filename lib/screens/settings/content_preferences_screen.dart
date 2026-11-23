import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/network/api_cache.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/screens/settings/settings_components.dart';

/// Preferences screen for managing content maturity, 18+ adult filters, and privacy shields.
class ContentPreferencesScreen extends StatefulWidget {
  const ContentPreferencesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ContentPreferencesScreen> createState() =>
      _ContentPreferencesScreenState();
}

class _ContentPreferencesScreenState extends State<ContentPreferencesScreen> {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  Future<void> _handleToggleAdult(bool targetValue) async {
    HapticFeedback.selectionClick();
    if (targetValue) {
      // Must pass age confirmation gate before enabling
      final confirmed = await _showAgeGateSheet(context);
      if (confirmed == true && mounted) {
        await _prefs.setEnableAdultContent(true);
        await ApiCache.instance.clear();
        anilistService.clearGenreCache();
        setState(() {});
        if (mounted) {
          AniwaysSnackBar.success(
            context,
            message: '18+ adult content enabled',
            icon: Icons.eighteen_up_rating_rounded,
          );
        }
      }
    } else {
      await _prefs.setEnableAdultContent(false);
      await ApiCache.instance.clear();
      anilistService.clearGenreCache();
      setState(() {});
      if (mounted) {
        AniwaysSnackBar.info(
          context,
          message: '18+ adult content disabled',
          icon: Icons.shield_outlined,
        );
      }
    }
  }

  Future<bool?> _showAgeGateSheet(BuildContext context) {
    return showOneUiBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      useRootNavigator: false,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle
                const OneUiDragHandle(margin: EdgeInsets.only(bottom: 20)),

                // Header icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.eighteen_up_rating_rounded,
                    color: cs.error,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Age Verification',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Body description
                Text(
                  'Enabling this option unlocks adult (18+) anime titles, explicit poster artwork, and mature tags from AniList across search and discovery.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Please confirm that you are at least 18 years of age (or the legal age of majority in your jurisdiction).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('I am 18+'),
                      ),
                    ),
                  ],
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

    final adultEnabled = _prefs.enableAdultContent;
    final blurCovers = _prefs.blurAdultCovers;
    final includeInHome = _prefs.includeAdultInHome;

    return Scaffold(
      body: OneUiScrollView(
        title: 'Content & Privacy',
        showBackButton: !widget.embedded,
        bottomPadding: MediaQuery.viewPaddingOf(context).bottom + 24,
        children: [
          // ── 1. Maturity & Age Restrictions ──────────────────────────────────
          const Padding(
            padding: kSettingsHorizontalPadding,
            child: SettingsSectionHeader('Maturity & Content Filter'),
          ),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.eighteen_up_rating_rounded,
                  color: adultEnabled ? cs.error : cat.appearance,
                  title: '18+ Adult Content',
                  subtitle: adultEnabled
                      ? 'Adult anime titles and explicit results unlocked'
                      : 'All 18+ mature content strictly filtered out',
                  value: adultEnabled,
                  isFirst: true,
                  isLast: !adultEnabled,
                  onChanged: (val) => _handleToggleAdult(val),
                ),
                if (adultEnabled) ...[
                  const SizedBox(height: 2),
                  SettingsSwitchTile(
                    icon: Icons.blur_on_rounded,
                    color: cat.playback,
                    title: 'Blur 18+ Covers (NSFW Shield)',
                    subtitle: blurCovers
                        ? 'Mature posters are blurred with a tap-to-peek privacy shield'
                        : 'Posters shown clearly without blur',
                    value: blurCovers,
                    isFirst: false,
                    isLast: false,
                    onChanged: (val) async {
                      HapticFeedback.selectionClick();
                      await _prefs.setBlurAdultCovers(val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 2),
                  SettingsSwitchTile(
                    icon: Icons.home_outlined,
                    color: cat.downloads,
                    title: 'Show in Home Feed',
                    subtitle: includeInHome
                        ? '18+ titles may appear in Home trending and seasonal carousels'
                        : 'Home feed stays safe; adult titles restricted to Search & Library',
                    value: includeInHome,
                    isFirst: false,
                    isLast: true,
                    onChanged: (val) async {
                      HapticFeedback.selectionClick();
                      await _prefs.setIncludeAdultInHome(val);
                      await ApiCache.instance.clear();
                      setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 2. Privacy & Diagnostics ──────────────────────────────────────
          const Padding(
            padding: kSettingsHorizontalPadding,
            child: SettingsSectionHeader('Diagnostics & Crash Reports'),
          ),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.bug_report_outlined,
                  color: cs.primary,
                  title: 'Anonymous Crash Reporting',
                  subtitle: _prefs.isCrashReportingEnabled
                      ? 'Automatically send anonymized error logs to help fix bugs'
                      : 'Disabled - no error diagnostics or crash logs are sent',
                  value: _prefs.isCrashReportingEnabled,
                  isFirst: true,
                  isLast: true,
                  onChanged: (val) async {
                    HapticFeedback.selectionClick();
                    await _prefs.setCrashReportingEnabled(val);
                    setState(() {});
                    if (mounted) {
                      AniwaysSnackBar.info(
                        context,
                        message: val
                            ? 'Anonymous crash reporting enabled'
                            : 'Crash reporting disabled',
                        icon: val
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 3. Information Card ─────────────────────────────────────────────
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adult anime titles are classified and tagged by the community on AniList. When 18+ content is enabled, mature titles such as Hentai and adult OVAs can be queried and filtered in the Search tab.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
