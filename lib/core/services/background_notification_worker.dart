import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/core/database/repositories/subscription_repository.dart';
import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/services/app_info_service.dart';
import 'package:aniways/core/services/episode_availability_checker.dart';
import 'package:aniways/core/services/notification_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/update/update_service.dart';
import 'package:aniways/models/anime_details.dart';
import 'package:workmanager/workmanager.dart';

const String kEpisodeCheckTaskName = 'com.aniways.tasks.EPISODE_CHECK';

/// Top-level callback dispatcher executed by Android WorkManager in a background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await SharedPreferencesService().init();
      await NotificationService.instance.init();
      await extensionManager.initialize();

      if (!SharedPreferencesService().notificationEnabled) {
        return true;
      }

      await checkAndNotifyEpisodes();
      await checkAndNotifyAppUpdate();
      return true;
    } catch (e, stack) {
      log.e('Background task failed ($task): $e', error: e, stackTrace: stack);
      return false;
    }
  });
}

/// The core verification engine that scans subscribed anime and notifies only
/// when new episodes are genuinely available across providers.
Future<void> checkAndNotifyEpisodes({bool forceCheck = false}) async {
  final subs = await SubscriptionRepository.instance.getActiveSubscriptions();
  if (subs.isEmpty) return;

  final now = DateTime.now();
  final checker = EpisodeAvailabilityChecker.instance;
  final notifier = NotificationService.instance;
  final repo = SubscriptionRepository.instance;

  for (final sub in subs) {
    if (sub.lastNotifiedEpisode >= sub.nextEpisodeNumber) {
      continue;
    }

    final earliestCheckTime = sub.nextAiringAt.add(const Duration(minutes: 40));
    final expirationTime = sub.nextAiringAt.add(const Duration(hours: 12));

    final isUpcoming = now.isBefore(sub.nextAiringAt);
    final isEligible = !isUpcoming && (forceCheck || now.isAfter(earliestCheckTime));

    if (!isEligible) {
      continue;
    }

    final isPastExpiration = now.isAfter(expirationTime);
    final report = await checker.checkAvailability(
      anilistId: sub.animeId,
      episodeNumber: sub.nextEpisodeNumber,
      minimumProviders: isPastExpiration ? 1 : null,
    );

    if (report.isAvailable) {
      // 1. Dispatch rich notification with Android group bundling
      await notifier.showEpisodeNotification(
        animeId: sub.animeId,
        animeTitle: sub.animeTitle,
        episodeNumber: sub.nextEpisodeNumber,
        availableProvidersCount: report.availableCount,
        audioLabel: report.audioLabel,
        coverUrl: sub.coverUrl,
      );

      // 2. Cancel fallback targeted WorkManager task so duplicate doesn't fire
      try {
        await Workmanager().cancelByUniqueName(
          'verify_${sub.animeId}_${sub.nextEpisodeNumber}',
        );
      } catch (_) {}

      // 3. Mark this episode as notified
      await repo.recordNotified(sub.animeId, sub.nextEpisodeNumber);

      // 4. Query AniList for the next episode schedule and pre-schedule it
      try {
        final json = await anilistService.details(sub.animeId);
        final details = AnimeDetails.fromJson(json);
        final next = details.media.nextAiring;
        if (next != null && next.episode > sub.nextEpisodeNumber) {
          final nextAirDate = DateTime.fromMillisecondsSinceEpoch(
            next.airingAt * 1000,
          );
          await repo.updateNextAiring(sub.animeId, next.episode, nextAirDate);
          final updatedSub = sub.copyWith(
            nextEpisodeNumber: next.episode,
            nextAiringAt: nextAirDate,
          );
          await BackgroundNotificationWorker.scheduleForSubscription(
            updatedSub,
          );
        } else if (details.media.status?.toUpperCase() == 'FINISHED') {
          await repo.unsubscribe(sub.animeId);
        }
      } catch (_) {}
    } else {
      await repo.recordCheckAttempt(sub.animeId);
      // If past expiration (12h) and not found, check if AniList already advanced multiple episodes
      if (isPastExpiration) {
        try {
          final json = await anilistService.details(sub.animeId);
          final details = AnimeDetails.fromJson(json);
          final next = details.media.nextAiring;
          if (next != null && next.episode > sub.nextEpisodeNumber) {
            final nextAirDate = DateTime.fromMillisecondsSinceEpoch(
              next.airingAt * 1000,
            );
            await repo.updateNextAiring(
              sub.animeId,
              next.episode,
              nextAirDate,
            );
            final updatedSub = sub.copyWith(
              nextEpisodeNumber: next.episode,
              nextAiringAt: nextAirDate,
            );
            await BackgroundNotificationWorker.scheduleForSubscription(
              updatedSub,
            );
          }
        } catch (_) {}
      }
    }
  }
}

/// Helper to configure and register background periodic and exact alarm execution.
class BackgroundNotificationWorker {
  BackgroundNotificationWorker._();

  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(callbackDispatcher);

      final prefs = SharedPreferencesService();
      if (prefs.notificationEnabled) {
        await registerPeriodicTask();
        await rescheduleAllSubscriptions();
      } else {
        await cancelPeriodicTask();
      }
    } catch (e) {
      log.w('WorkManager initialization error: $e');
    }
  }

  /// Registers or updates the battery-optimized background periodic check.
  static Future<void> registerPeriodicTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        'aniways_periodic_episode_checker',
        kEpisodeCheckTaskName,
        frequency: const Duration(minutes: 30),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      log.w('Failed to register periodic WorkManager task: $e');
    }
  }

  /// Cancels background periodic checks.
  static Future<void> cancelPeriodicTask() async {
    try {
      await Workmanager().cancelByUniqueName(
        'aniways_periodic_episode_checker',
      );
    } catch (e) {
      log.w('Failed to cancel WorkManager task: $e');
    }
  }

  /// Schedules targeted background verification for a single subscribed anime.
  static Future<void> scheduleForSubscription(EpisodeSubscription sub) async {
    if (!SharedPreferencesService().notificationEnabled || !sub.isSubscribed) {
      return;
    }
    if (sub.lastNotifiedEpisode >= sub.nextEpisodeNumber) {
      return;
    }

    // Japanese broadcast + 40-minute provider buffer
    final targetTime = sub.nextAiringAt.add(const Duration(minutes: 40));
    final now = DateTime.now();

    if (targetTime.isAfter(now)) {
      // Schedule targeted WorkManager one-off task for rich verification
      final delay = targetTime.difference(now);
      try {
        await Workmanager().registerOneOffTask(
          'verify_${sub.animeId}_${sub.nextEpisodeNumber}',
          kEpisodeCheckTaskName,
          initialDelay: delay,
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
      } catch (e) {
        log.w('Could not schedule targeted WorkManager task: $e');
      }
    } else {
      // Broadcast time already passed: verify immediately
      await checkAndNotifyEpisodes();
    }
  }

  /// Cancels verification tasks for an anime.
  static Future<void> cancelForSubscription(
    int animeId, [
    int? episodeNumber,
  ]) async {
    if (episodeNumber != null) {
      try {
        await Workmanager().cancelByUniqueName(
          'verify_${animeId}_$episodeNumber',
        );
      } catch (_) {}
    } else {
      await NotificationService.instance.cancelForAnime(animeId);
    }
  }

  /// Reschedules background verification tasks for all active subscriptions with pending episodes.
  static Future<void> rescheduleAllSubscriptions() async {
    if (!SharedPreferencesService().notificationEnabled) return;
    try {
      final subs = await SubscriptionRepository.instance
          .getActiveSubscriptions();
      for (final sub in subs) {
        if (sub.lastNotifiedEpisode < sub.nextEpisodeNumber) {
          await scheduleForSubscription(sub);
        }
      }
    } catch (e) {
      log.w('Error rescheduling subscriptions: $e');
    }
  }

  @Deprecated('Use rescheduleAllSubscriptions instead')
  static Future<void> rescheduleAllExactAlarms() =>
      rescheduleAllSubscriptions();
}

/// Checks for app updates in the background and notifies if a new release is available.
Future<void> checkAndNotifyAppUpdate() async {
  if (kDebugMode) return;
  try {
    final updateService = UpdateService.instance;
    final result = await updateService.checkForUpdate();
    if (result.hasUpdate && result.release != null) {
      final release = result.release!;
      final alreadyNotified = await updateService.hasNotifiedForVersion(
        release.version,
      );
      if (!alreadyNotified) {
        await NotificationService.instance.showUpdateNotification(
          latestVersion: release.version,
          currentVersion: AppInfoService.instance.version,
          title: release.title,
        );
        await updateService.recordNotifiedVersion(release.version);
        log.i('Notified user about new update v${release.version}');
      }
    }
  } catch (e) {
    log.w('Background update check failed: $e');
  }
}
