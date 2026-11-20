import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/scroll/app_scroll.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'package:aniways/core/constants.dart';
import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/services/app_info_service.dart';
import 'package:aniways/core/services/background_notification_worker.dart';
import 'package:aniways/core/services/backup_restore_service.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/core/services/notification_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/app_theme.dart';
import 'package:aniways/core/update/update_service.dart';
import 'package:aniways/core/widgets/update_bottom_sheet.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/navigation/main_navigation.dart';
import 'package:aniways/providers/theme_provider.dart';
import 'package:aniways/screens/details/anime_details_screen.dart';
import 'package:aniways/screens/onboarding/onboarding_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void _setupNotificationNavigation() {
  NotificationService.onNotificationTapped = (data) {
    final type = data['type'] as String?;
    if (type == 'app_update') {
      void openUpdate() async {
        final nav = appNavigatorKey.currentState;
        final ctx = nav?.overlay?.context ?? nav?.context;
        if (ctx != null) {
          final res = await UpdateService.instance.checkForUpdate();
          if (res.hasUpdate && res.release != null && ctx.mounted) {
            UpdateBottomSheet.show(ctx, res.release!);
          }
        }
      }

      if (appNavigatorKey.currentState != null) {
        openUpdate();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          openUpdate();
        });
      }
      return;
    }

    final animeId = data['animeId'] as int?;
    if (animeId == null) return;

    final title = data['title'] as String? ?? 'Anime';
    final coverUrl = data['coverUrl'] as String?;

    final media = AnimeMedia(
      id: animeId,
      romajiTitle: title,
      englishTitle: title,
      coverUrl: coverUrl,
    );

    void navigate() {
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => AnimeDetailsScreen(anime: media),
          ),
        );
      }
    }

    if (appNavigatorKey.currentState != null) {
      navigate();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigate();
      });
    }
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppInfoService.instance.init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log.e(
      'Unhandled Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.e('Unhandled async error', error: error, stackTrace: stack);
    return true;
  };

  await SharedPreferencesService().init();

  _setupNotificationNavigation();

  // Initialize notification engine and background worker
  try {
    await NotificationService.instance.init();
    await BackgroundNotificationWorker.initialize();
  } catch (_) {}

  // Initialize extensions so provider cache & states are ready before UI builds
  try {
    await extensionManager.initialize();
  } catch (_) {}

  // Background startup tasks (cache size enforcement, auto-backup, episode check)
  Future.microtask(() async {
    try {
      await ImageCacheService.instance.enforceCacheLimit();
      await BackupRestoreService.instance.checkAndRunAutoBackup();
      if (SharedPreferencesService().notificationEnabled) {
        await checkAndNotifyEpisodes();
        await BackgroundNotificationWorker.rescheduleAllSubscriptions();
      }
    } catch (_) {}
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // TODO: add more providers here as the app grows
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => WatchlistProvider()),
      ],
      child: const AniwaysApp(),
    ),
  );
}

class AniwaysApp extends StatefulWidget {
  const AniwaysApp({super.key});

  @override
  State<AniwaysApp> createState() => _AniwaysAppState();
}

class _AniwaysAppState extends State<AniwaysApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = NotificationService.instance.pendingPayload;
      if (pending != null) {
        NotificationService.instance.clearPendingPayload();
        NotificationService.onNotificationTapped?.call(pending);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // DynamicColorBuilder provides the device's wallpaper-derived ColorScheme
    // (Android 12+ only; null on other platforms).
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final useDynamic = themeProvider.dynamicTheme;
            final pureBlack = themeProvider.pureBlack;
            final preset = themeProvider.colorPreset;
            final customColor = themeProvider.customColor;
            final paletteStyle = themeProvider.paletteStyle;
            final contrastLevel = themeProvider.contrastLevel;

            return MaterialApp(
              navigatorKey: appNavigatorKey,
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              // Soft bouncing scroll, and lists/carousels that can also be
              // dragged with a mouse or trackpad on desktop.
              scrollBehavior: const AppScrollBehavior(),
              theme: AppTheme.generateLightTheme(
                dynamicColorScheme: lightDynamic,
                useDynamic: useDynamic,
                preset: preset,
                customColor: customColor,
                paletteStyle: paletteStyle,
                contrastLevel: contrastLevel,
              ),
              darkTheme: AppTheme.generateDarkTheme(
                dynamicColorScheme: darkDynamic,
                useDynamic: useDynamic,
                pureBlack: pureBlack,
                preset: preset,
                customColor: customColor,
                paletteStyle: paletteStyle,
                contrastLevel: contrastLevel,
              ),
              themeMode: themeProvider.themeMode,
              home: SharedPreferencesService().hasCompletedOnboarding
                  ? const MainNavigation()
                  : const OnboardingScreen(),
            );
          },
        );
      },
    );
  }
}
