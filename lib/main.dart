import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/scroll/app_scroll.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

const String _kSentryDsn =
    'https://74ed062158fd2bd2b0880f47b5eaca81@o4512481811365888.ingest.de.sentry.io/4512481817788496';

void _startDeferredServices() {
  // Defer non-critical services until after the UI has mounted and rendered its first frame.
  // This eliminates the 2-4 second splash freeze while ensuring background workers,
  // extension engines, and notifications are fully operational.
  unawaited(() async {
    // 1. Notification system and background WorkManager registration
    try {
      await NotificationService.instance.init();
      await BackgroundNotificationWorker.initialize();
    } catch (e) {
      log.w('Failed to initialize notification or background worker: $e');
    }

    // 2. Extension manager (compiled QuickJS runtimes)
    try {
      await extensionManager.initialize();
    } catch (e) {
      log.w('Failed to initialize extension manager: $e');
    }

    // 3. Low-priority maintenance tasks (delayed slightly so startup interactions stay smooth)
    try {
      await Future.delayed(const Duration(seconds: 3));
      await ImageCacheService.instance.enforceCacheLimit();
      await BackupRestoreService.instance.checkAndRunAutoBackup();
      if (SharedPreferencesService().notificationEnabled) {
        await checkAndNotifyEpisodes();
        await BackgroundNotificationWorker.rescheduleAllSubscriptions();
      }
    } catch (e) {
      log.w('Startup maintenance tasks encountered an error: $e');
    }
  }());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Await only essential services required for theme and root routing
  await Future.wait([
    AppInfoService.instance.init(),
    SharedPreferencesService().init(),
  ]);

  _setupNotificationNavigation();

  final app = MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
    child: const AniwaysApp(),
  );

  // If user disabled crash reporting in settings, launch app directly without Sentry initialization
  if (!SharedPreferencesService().isCrashReportingEnabled) {
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

    runApp(app);
    _startDeferredServices();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _kSentryDsn;
      // Traces sample rate for performance profiling (20% to stay comfortably within free tier)
      options.tracesSampleRate = 0.2;
      // Active user sessions tracking (DAU/MAU)
      options.enableAutoSessionTracking = true;
      options.autoSessionTrackingInterval = const Duration(minutes: 30);
      options.sendDefaultPii = false;

      // Filter or drop events if crash reporting is toggled off
      options.beforeSend = (event, hint) {
        if (!SharedPreferencesService().isCrashReportingEnabled) {
          return null;
        }
        return event;
      };
    },
    appRunner: () {
      runApp(
        DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: app,
        ),
      );
      _startDeferredServices();
    },
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
