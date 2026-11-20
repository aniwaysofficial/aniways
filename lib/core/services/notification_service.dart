import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:aniways/core/logger.dart';

/// Service managing rich local notifications with Android Notification Grouping
/// for new anime episode releases.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _deviceChannel =
      MethodChannel('com.aniways.app/device_control');

  bool _initialized = false;

  /// Global Android notification channel for episode releases
  static const String channelId = 'episode_releases';
  static const String channelName = 'Episode Releases';
  static const String channelDesc =
      'Notifications when newly released episodes are verified and ready to stream';

  /// Notification grouping key
  static const String episodeGroupKey = 'com.aniways.notifications.EPISODES';

  /// Fixed notification ID for the group summary
  static const int groupSummaryId = 999999;

  /// Callback when user taps a notification
  static void Function(Map<String, dynamic> payload)? onNotificationTapped;

  Map<String, dynamic>? _pendingPayload;
  Map<String, dynamic>? get pendingPayload => _pendingPayload;
  void clearPendingPayload() => _pendingPayload = null;

  /// Initializes the local notification plugin and creates notification channels.
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payloadStr = response.payload;
        if (payloadStr != null && payloadStr.isNotEmpty) {
          try {
            final data = jsonDecode(payloadStr) as Map<String, dynamic>;
            onNotificationTapped?.call(data);
          } catch (e) {
            log.w('Failed to decode notification payload: $e');
          }
        }
      },
    );

    try {
      final launchDetails =
          await _notifications.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payloadStr = launchDetails?.notificationResponse?.payload;
        if (payloadStr != null && payloadStr.isNotEmpty) {
          final data = jsonDecode(payloadStr) as Map<String, dynamic>;
          _pendingPayload = data;
        }
      }
    } catch (e) {
      log.w('Could not read notification launch details: $e');
    }

    // Create high-importance Android notification channel
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'general_notifications',
          'General Notifications',
          description: 'App announcements, downloads, and system updates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
  }

  /// Checks whether notifications are allowed by the operating system.
  Future<bool> areNotificationsEnabled() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled ?? false;
    }
    return true;
  }

  /// Requests notification permission on Android 13+ (API 33+).
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Opens the operating system notification settings screen for this app.
  Future<void> openSettings() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.openAppNotificationSettings();
    }
  }

  /// Opens the device battery optimization prompt or App Info settings screen for Aniways.
  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _deviceChannel.invokeMethod('openBatterySettings');
    } catch (e) {
      log.w('Could not open battery settings via device channel: $e');
      await openSettings();
    }
  }

  /// Checks whether battery optimization is ignored (set to "Unrestricted") on Android.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final isIgnoring = await _deviceChannel
          .invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return isIgnoring ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Downloads and caches the anime cover poster to local storage so it can be
  /// displayed as a rich big picture / thumbnail in Android notifications.
  Future<String?> _resolvePosterPath(int animeId, String? coverUrl) async {
    if (coverUrl == null || coverUrl.trim().isEmpty) return null;

    try {
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/poster_$animeId.jpg');
      if (await file.exists() && (await file.length()) > 0) {
        return file.path;
      }

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(coverUrl));
      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, data) => buffer..addAll(data),
      );
      client.close();

      if (bytes.isEmpty) return null;

      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      log.w('Could not download notification poster for anime $animeId: $e');
      return null;
    }
  }

  /// Shows an episode release notification with Android group bundling and rich poster artwork.
  Future<void> showEpisodeNotification({
    required int animeId,
    required String animeTitle,
    required int episodeNumber,
    int availableProvidersCount = 1,
    String? audioLabel,
    String? coverUrl,
  }) async {
    await init();

    final id = (animeId * 1000 + episodeNumber) & 0x7FFFFFFF;
    final audioSuffix = audioLabel != null && audioLabel.isNotEmpty
        ? ' · $audioLabel'
        : '';
    final title = '$animeTitle · Episode $episodeNumber';
    final body = 'Now ready to stream$audioSuffix · Tap to watch';

    final payload = jsonEncode({
      'type': 'episode',
      'animeId': animeId,
      'episode': episodeNumber,
      'title': animeTitle,
      'coverUrl': coverUrl,
    });

    final posterPath = await _resolvePosterPath(animeId, coverUrl);
    final bigTextStyle = BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: audioSuffix.isNotEmpty
          ? audioSuffix.replaceFirst(' · ', '')
          : 'New Episode',
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: episodeGroupKey,
      icon: '@mipmap/ic_launcher',
      largeIcon: posterPath != null ? FilePathAndroidBitmap(posterPath) : null,
      styleInformation: bigTextStyle,
      category: AndroidNotificationCategory.status,
    );

    // 1. Show the individual child notification
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );

    // 2. Update or show the group summary notification
    await _updateGroupSummary();
  }

  /// Notification ID reserved for app updates
  static const int updateNotificationId = 999999;

  /// Shows an in-app update available notification.
  Future<void> showUpdateNotification({
    required String latestVersion,
    required String currentVersion,
    String? title,
  }) async {
    await init();

    final notifTitle = 'Aniways Update Available (v$latestVersion)';
    final notifBody =
        'A new version of Aniways is ready to install. Tap to update.';

    final payload = jsonEncode({
      'type': 'app_update',
      'version': latestVersion,
    });

    final bigTextStyle = BigTextStyleInformation(
      notifBody,
      contentTitle: notifTitle,
      summaryText: 'Update Available',
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigTextStyle,
      category: AndroidNotificationCategory.status,
    );

    await _notifications.show(
      id: updateNotificationId,
      title: notifTitle,
      body: notifBody,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// Shows or updates the summary notification for the episode group.
  Future<void> _updateGroupSummary() async {
    const summaryDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: episodeGroupKey,
      setAsGroupSummary: true,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.show(
      id: groupSummaryId,
      title: 'Aniways · New Episodes Ready',
      body: 'New anime episodes are verified and ready to stream',
      notificationDetails: const NotificationDetails(android: summaryDetails),
    );
  }

  /// Cancels all notifications for a specific anime series.
  Future<void> cancelForAnime(int animeId) async {
    // Cancels potential recent episodes
    for (var ep = 1; ep <= 100; ep++) {
      final id = (animeId * 1000 + ep) & 0x7FFFFFFF;
      await _notifications.cancel(id: id);
    }
  }

  /// Cancels a scheduled or active notification for a specific anime episode.
  Future<void> cancelScheduledNotification(int animeId, int episodeNumber) async {
    final id = (animeId * 1000 + episodeNumber) & 0x7FFFFFFF;
    await _notifications.cancel(id: id);
  }

  /// Clears all active notifications.
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
