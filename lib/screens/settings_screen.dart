import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/widgets/app_logo.dart';
import 'package:provider/provider.dart';

import 'package:aniways/core/constants.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/services/app_info_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/theme/theme_presets.dart';
import 'package:aniways/core/update/update_service.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/core/widgets/update_bottom_sheet.dart';
import 'package:aniways/navigation/main_navigation.dart'
    show navBarClearance, pushFullScreen;
import 'package:aniways/providers/theme_provider.dart';
import 'package:aniways/screens/settings/appearance_screen.dart';
import 'package:aniways/screens/settings/backup_restore_screen.dart';
import 'package:aniways/screens/settings/content_preferences_screen.dart';
import 'package:aniways/screens/settings/extensions/extensions_screen.dart';
import 'package:aniways/screens/settings/favorite_anime_picks_screen.dart';
import 'package:aniways/screens/settings/notification_preferences_screen.dart';
import 'package:aniways/screens/settings/playback_preferences_screen.dart';
import 'package:aniways/screens/settings/settings_components.dart';

/// Width of the settings list when the screen is split in two.
const double _listPaneWidth = 400;

/// Sections that open in the detail pane on wide layouts. Add more here as
/// they become real pages (the sheets can move over one at a time).
enum _Detail {
  appearance,
  playback,
  notifications,
  content,
  backup,
  extensions,
  animePicks,
}

/// Settings screen.
///
/// Compact: one column, Appearance opens as a full-screen page.
/// Expanded and up: list on the left, selected section on the right.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Detail _detail = _Detail.appearance;

  @override
  Widget build(BuildContext context) {
    final wide = context.layoutSize.atLeast(WindowSize.expanded);

    final list = _SettingsList(
      // Only highlight a row when there is a detail pane to show it in.
      selected: wide ? _detail : null,
      onOpenAppearance: () {
        if (wide) {
          setState(() => _detail = _Detail.appearance);
        } else {
          pushFullScreen(context, const AppearanceScreen());
        }
      },
      onOpenPlayback: () {
        if (wide) {
          setState(() => _detail = _Detail.playback);
        } else {
          pushFullScreen(context, const PlaybackPreferencesScreen());
        }
      },
      onOpenNotifications: () async {
        if (wide) {
          setState(() => _detail = _Detail.notifications);
        } else {
          await pushFullScreen(context, const NotificationPreferencesScreen());
          if (mounted) setState(() {});
        }
      },
      onOpenContent: () {
        if (wide) {
          setState(() => _detail = _Detail.content);
        } else {
          pushFullScreen(context, const ContentPreferencesScreen());
        }
      },
      onOpenBackup: () {
        if (wide) {
          setState(() => _detail = _Detail.backup);
        } else {
          pushFullScreen(context, const BackupRestoreScreen());
        }
      },
      onOpenExtensions: () {
        if (wide) {
          setState(() => _detail = _Detail.extensions);
        } else {
          pushFullScreen(context, const ExtensionsScreen());
        }
      },
      onOpenAnimePicks: () {
        if (wide) {
          setState(() => _detail = _Detail.animePicks);
        } else {
          pushFullScreen(context, const FavoriteAnimePicksScreen());
        }
      },
    );

    if (!wide) return Scaffold(body: list);

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: _listPaneWidth, child: list),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: switch (_detail) {
              _Detail.appearance => const AppearanceScreen(embedded: true),
              _Detail.playback => const PlaybackPreferencesScreen(
                embedded: true,
              ),
              _Detail.notifications => const NotificationPreferencesScreen(
                embedded: true,
              ),
              _Detail.content => const ContentPreferencesScreen(embedded: true),
              _Detail.backup => const BackupRestoreScreen(embedded: true),
              _Detail.extensions => const ExtensionsScreen(embedded: true),
              _Detail.animePicks => const FavoriteAnimePicksScreen(
                embedded: true,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// Account banner followed by grouped setting sections.
class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.selected,
    required this.onOpenAppearance,
    required this.onOpenPlayback,
    required this.onOpenNotifications,
    required this.onOpenContent,
    required this.onOpenBackup,
    required this.onOpenExtensions,
    required this.onOpenAnimePicks,
  });

  /// Which row is highlighted (null on phones).
  final _Detail? selected;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenPlayback;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenContent;
  final VoidCallback onOpenBackup;
  final VoidCallback onOpenExtensions;
  final VoidCallback onOpenAnimePicks;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = CategoryColors.of(context);

    final appearanceSubtitle = context.select((ThemeProvider p) {
      if (p.dynamicTheme || p.colorPreset == AppColorPreset.dynamic) {
        return 'Dynamic Color · Material You';
      }
      final mode = switch (p.appTheme) {
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
        AppThemeMode.auto => 'System',
      };
      return '${p.colorPreset.label} · $mode';
    });

    final prefs = SharedPreferencesService();
    final audio = prefs.defaultAudioTrack == 'dub' ? 'Dub' : 'Sub';
    final q = prefs.streamingQuality == 'auto'
        ? 'Auto'
        : prefs.streamingQuality;
    final playbackSubtitle =
        '$audio · $q · ${prefs.autoNextEpisode ? 'Auto-next' : 'Manual'}';

    final adultOn = prefs.enableAdultContent;
    final contentSubtitle = adultOn
        ? (prefs.blurAdultCovers ? '18+ Enabled · Shield on' : '18+ Enabled')
        : '18+ Disabled';

    final notifyOn = prefs.notificationEnabled;
    final notificationSubtitle = notifyOn
        ? 'Active · ${prefs.notificationMinimumProviders >= 2 ? 'Reliable' : 'Fastest'}'
        : 'Disabled';

    return OneUiScrollView(
      title: 'Settings',
      horizontalPadding: 16,
      bottomPadding: navBarClearance(context),
      showBackButton: false,
      children: [
        //const _AccountCard(),
        //const SizedBox(height: 24),

        _SettingsGroup(
          title: 'General',
          items: [
            _Item(
              icon: Icons.palette_outlined,
              color: cat.appearance,
              title: 'Appearance',
              subtitle: appearanceSubtitle,
              selected: selected == _Detail.appearance,
              onTap: onOpenAppearance,
            ),
            _Item(
              icon: Icons.play_circle_outline_rounded,
              color: cat.playback,
              title: 'Player & Playback',
              subtitle: playbackSubtitle,
              selected: selected == _Detail.playback,
              onTap: onOpenPlayback,
            ),
            _Item(
              icon: Icons.notifications_active_outlined,
              color: cat.playback,
              title: 'Notifications',
              subtitle: notificationSubtitle,
              selected: selected == _Detail.notifications,
              onTap: onOpenNotifications,
            ),
          ],
        ),
        const SizedBox(height: 20),

        _SettingsGroup(
          title: 'Content & Privacy',
          items: [
            _Item(
              icon: adultOn
                  ? Icons.eighteen_up_rating_rounded
                  : Icons.shield_outlined,
              color: adultOn ? cs.error : cat.appearance,
              title: 'Content & Maturity',
              subtitle: contentSubtitle,
              selected: selected == _Detail.content,
              onTap: onOpenContent,
            ),
          ],
        ),
        const SizedBox(height: 20),

        ValueListenableBuilder<int>(
          valueListenable:
              SharedPreferencesService.recommendationsChangedNotifier,
          builder: (context, _, _) {
            final animePicksCount = prefs.onboardingFavoriteAnimeIds.length;
            final animePicksSubtitle = !prefs.showHomeRecommendations
                ? 'Hidden from home feed'
                : (animePicksCount == 0
                      ? 'Pick shows to tailor recommendations'
                      : '$animePicksCount favorite show${animePicksCount == 1 ? '' : 's'} selected');

            return _SettingsGroup(
              title: 'Recommendations',
              items: [
                _Item(
                  icon: Icons.auto_awesome_rounded,
                  color: cat.downloads,
                  title: 'Anime You Love',
                  subtitle: animePicksSubtitle,
                  selected: selected == _Detail.animePicks,
                  onTap: onOpenAnimePicks,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        _SettingsGroup(
          title: 'Sources & Extensions',
          items: [
            _Item(
              icon: Icons.extension_rounded,
              color: cat.accounts,
              title: 'Extensions',
              subtitle: 'Manage streaming providers, repositories & updates',
              selected: selected == _Detail.extensions,
              onTap: onOpenExtensions,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // _SettingsGroup(
        //   title: 'Accounts',
        //   items: [
        //     _Item(
        //       icon: Icons.sync_rounded,
        //       color: cat.accounts,
        //       title: 'Accounts & Tracking',
        //       subtitle: 'AniList, MyAnimeList, Simkl',
        //       onTap: () => _showAccountsTrackingSheet(context),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 20),
        _SettingsGroup(
          title: 'Data',
          items: [
            // _Item(
            //   icon: Icons.download_rounded,
            //   color: cat.downloads,
            //   title: 'Downloads',
            //   subtitle: 'Location, quality & Wi-Fi only',
            //   onTap: () => AniwaysSnackBar.info(
            //     context,
            //     message: "Download is coming soon!",
            //   ),
            // ),
            _Item(
              icon: Icons.settings_backup_restore_rounded,
              color: cat.backup,
              title: 'Backup & Restore',
              subtitle: 'Export or restore library and settings',
              selected: selected == _Detail.backup,
              onTap: onOpenBackup,
            ),
          ],
        ),
        const SizedBox(height: 20),

        _SettingsGroup(
          title: 'About',
          items: [
            _Item(
              icon: Icons.system_update_rounded,
              color: cs.primary,
              title: 'Check for updates',
              subtitle: 'v${AppInfoService.instance.version} · Tap to check',
              onTap: () => _checkForUpdates(context),
            ),
            _Item(
              icon: Icons.info_outline_rounded,
              color: cs.onSurfaceVariant,
              title: 'About',
              subtitle: '${AppConstants.appName} v${AppInfoService.instance.version}',
              onTap: () => _showAboutSheet(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    HapticFeedback.lightImpact();
    AniwaysSnackBar.info(
      context,
      message: 'Checking for updates...',
      icon: Icons.sync_rounded,
      duration: const Duration(seconds: 2),
    );

    final res = await UpdateService.instance.checkForUpdate(isManual: true);
    if (!context.mounted) return;

    if (res.hasUpdate && res.release != null) {
      UpdateBottomSheet.show(context, res.release!);
    } else if (res.errorMessage != null) {
      AniwaysSnackBar.error(context, message: res.errorMessage!);
    } else {
      AniwaysSnackBar.success(
        context,
        message:
            '${AppConstants.appName} is up to date (v${AppInfoService.instance.version})',
      );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Grouped list building blocks
// ═════════════════════════════════════════════════════════════════════════

class _Item {
  const _Item({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// True when this row's page is open in the detail pane.
  final bool selected;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});

  final String title;
  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          _SettingsTile(
            item: items[i],
            isFirst: i == 0,
            isLast: i == items.length - 1,
          ),
        ],
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final _Item item;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = item.selected;

    return Material(
      color: selected ? cs.secondaryContainer : cs.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: settingsTileBorderRadius(
          isFirst: isFirst,
          isLast: isLast,
        ),
      ),
      child: ListTile(
        onTap: item.onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SettingsTileIcon(icon: item.icon, color: item.color),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: selected ? cs.onSecondaryContainer : null,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          style: TextStyle(
            color: selected
                ? cs.onSecondaryContainer.withValues(alpha: 0.8)
                : cs.onSurfaceVariant,
            fontSize: 12.5,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: (selected ? cs.onSecondaryContainer : cs.onSurfaceVariant)
              .withValues(alpha: 0.6),
          size: 22,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Account banner
// ═════════════════════════════════════════════════════════════════════════

// ignore: unused_element
class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 32,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign in to sync your saved anime and watch progress',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _showAccountsTrackingSheet(context),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Bottom sheets (shared scaffold)
// ═════════════════════════════════════════════════════════════════════════

/// One sheet layout for all three sheets. Uses the root navigator so the
/// sheet opens above the floating nav pill.
void _showSheet(
  BuildContext context, {
  required String title,
  required String description,
  required List<Widget> children,
}) {
  showOneUiBottomSheet(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      );
    },
  );
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: cs.surfaceContainerHigh,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing,
      ),
    );
  }
}

void _comingSoon(BuildContext context, String message) {
  AniwaysSnackBar.info(context, message: message);
}

void _showAccountsTrackingSheet(BuildContext context) {
  const trackers = [
    (
      title: 'AniList',
      subtitle: 'Sync anime status and progress',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF02A9FF),
    ),
    (
      title: 'MyAnimeList',
      subtitle: 'MAL account integration',
      icon: Icons.star_rounded,
      color: Color(0xFF2E51A2),
    ),
    (
      title: 'Simkl',
      subtitle: 'TV, Anime and Movie tracker',
      icon: Icons.movie_filter_rounded,
      color: Color(0xFF00C853),
    ),
  ];

  _showSheet(
    context,
    title: 'Accounts & Tracking',
    description:
        'Link your tracker accounts to automatically sync completed '
        'episodes, scores, and bookmarks.',
    children: [
      for (final t in trackers)
        _SheetTile(
          icon: t.icon,
          color: t.color,
          title: t.title,
          subtitle: t.subtitle,
          trailing: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _comingSoon(context, '${t.title} integration coming soon!');
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Connect'),
          ),
        ),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════════════
// About sheet
// ═════════════════════════════════════════════════════════════════════════

void _showAboutSheet(BuildContext context) {
  showOneUiBottomSheet(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    topRadius: 28,
    builder: (sheetContext) => _AboutSheet(parentContext: context),
  );
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet({required this.parentContext});

  /// Context of the settings screen, used to open the licenses page after
  /// the sheet has been dismissed.
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AboutHero(),
            const SizedBox(height: 12),

            // Two quick-facts tiles side by side.
            const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _VersionTile()),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.flutter_dash_rounded,
                      label: 'Built with',
                      value: 'Flutter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Grouped list, same corner language as the settings screen.
            _AboutRow(
              icon: Icons.groups_rounded,
              color: cs.tertiary,
              title: 'Design & Engineering',
              subtitle: 'Aniways Team',
              position: _RowPosition.top,
            ),
            _AboutRow(
              icon: Icons.description_outlined,
              color: cs.secondary,
              title: 'Open source licenses',
              subtitle: 'Libraries used in this app',
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
              onTap: () {
                Navigator.pop(context);
                showLicensePage(
                  context: parentContext,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppInfoService.instance.version,
                );
              },
              position: _RowPosition.bottom,
            ),
            const SizedBox(height: 24),

            // Large translucent "Made with Love" watermark footer
            Opacity(
              opacity: 0.28,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Made with Love',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.favorite_rounded,
                          size: 32,
                          color: cs.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'BY ANIWAYS TEAM',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient card with the logo, name, version and tagline. A large faint
/// flower in the corner gives it some character without adding clutter.
class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer.withValues(alpha: 0.55),
                    cs.tertiaryContainer.withValues(alpha: 0.20),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -34,
            top: -34,
            child: Icon(
              Icons.local_florist_rounded,
              size: 170,
              color: cs.primary.withValues(alpha: 0.09),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -30,
            child: Icon(
              Icons.local_florist_rounded,
              size: 100,
              color: cs.tertiary.withValues(alpha: 0.07),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.30),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: AppLogo(size: 64, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${AppInfoService.instance.version}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'A modern, beautiful, and open anime tracking, '
                    'discovery, and schedule experience built with Flutter and Material 3.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
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

/// Small square-ish fact tile: icon, label, value.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: cs.primary),
                  ),
                  const Spacer(),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Version tile - tap to copy, with inline "Copied" feedback (a snackbar
/// would be hidden behind the sheet).
class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: '${AppConstants.appName} v${AppInfoService.instance.version}'),
    );
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _StatTile(
      icon: Icons.tag_rounded,
      label: _copied ? 'Copied to clipboard' : 'Version',
      value: AppInfoService.instance.version,
      onTap: _copy,
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          key: ValueKey(_copied),
          size: 18,
          color: _copied ? cs.primary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

enum _RowPosition { top, bottom }

/// A list row with a tinted icon, title and subtitle. Big radius on the
/// group's outer corners, small where rows meet (matches the settings list).
class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.position,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final _RowPosition position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final radius = BorderRadius.vertical(
      top: position == _RowPosition.top
          ? kSettingsBigRadius
          : kSettingsSmallRadius,
      bottom: position == _RowPosition.bottom
          ? kSettingsBigRadius
          : kSettingsSmallRadius,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: position == _RowPosition.bottom ? 0 : 3),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
