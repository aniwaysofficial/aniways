import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/core/database/repositories/subscription_repository.dart';
import 'package:aniways/core/services/background_notification_worker.dart';
import 'package:aniways/core/services/notification_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/screens/settings/settings_components.dart';

/// Preferences screen for managing episode release notifications and active subscriptions.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen>
    with WidgetsBindingObserver {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final SubscriptionRepository _subRepo = SubscriptionRepository.instance;
  bool _systemPermissionGranted = true;
  bool _isBatteryUnrestricted = false;
  Timer? _countdownTimer;
  int _remainingTestSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystemPermission();
    _checkBatteryStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemPermission();
      _checkBatteryStatus();
    }
  }

  Future<void> _checkSystemPermission() async {
    final granted = await NotificationService.instance
        .areNotificationsEnabled();
    if (mounted && granted != _systemPermissionGranted) {
      setState(() => _systemPermissionGranted = granted);
    }
  }

  Future<void> _checkBatteryStatus() async {
    final unrestricted = await NotificationService.instance
        .isIgnoringBatteryOptimizations();
    if (mounted && unrestricted != _isBatteryUnrestricted) {
      setState(() => _isBatteryUnrestricted = unrestricted);
    }
  }

  Future<void> _handleToggleMaster(bool value) async {
    HapticFeedback.selectionClick();
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      _systemPermissionGranted = granted;
      if (!granted) {
        if (mounted) {
          AniwaysSnackBar.error(
            context,
            message:
                'Notification permission is required to receive notifications',
            actionLabel: 'Settings',
            onAction: () => NotificationService.instance.openSettings(),
          );
        }
        setState(() {});
        return;
      }
      await _prefs.setNotificationEnabled(true);
      await BackgroundNotificationWorker.registerPeriodicTask();
      await BackgroundNotificationWorker.rescheduleAllSubscriptions();
    } else {
      await _prefs.setNotificationEnabled(false);
      await BackgroundNotificationWorker.cancelPeriodicTask();
      await NotificationService.instance.cancelAll();
    }
    setState(() {});
  }

  Future<void> _sendTestNotification() async {
    HapticFeedback.lightImpact();

    final granted = await NotificationService.instance.requestPermission();
    _systemPermissionGranted = granted;
    if (!granted) {
      if (mounted) {
        AniwaysSnackBar.error(
          context,
          message: 'Notifications are disabled in system settings',
          actionLabel: 'Settings',
          onAction: () => NotificationService.instance.openSettings(),
        );
      }
      setState(() {});
      return;
    }

    final subs = await _subRepo.getActiveSubscriptions();
    final String animeTitle;
    final int animeId;
    final int epNum;
    final String coverUrl;

    if (subs.isNotEmpty) {
      final sample = subs.first;
      animeTitle = sample.animeTitle;
      animeId = sample.animeId;
      epNum = sample.nextEpisodeNumber;
      coverUrl = sample.coverUrl ?? 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-qQTzQnEJJ3oB.jpg';
    } else {
      animeTitle = 'Frieren: Beyond Journey\'s End';
      animeId = 154587;
      epNum = 29;
      coverUrl = 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-qQTzQnEJJ3oB.jpg';
    }

    await NotificationService.instance.showEpisodeNotification(
      animeId: animeId,
      animeTitle: animeTitle,
      episodeNumber: epNum,
      audioLabel: 'Sub & Dub',
      coverUrl: coverUrl,
    );

    if (mounted) {
      AniwaysSnackBar.success(
        context,
        message: 'Test notification sent! Pull down status bar to view',
        icon: Icons.notifications_active_rounded,
      );
    }
  }

  Future<void> _scheduleTestNotification(Duration delay) async {
    final granted = await NotificationService.instance.requestPermission();
    _systemPermissionGranted = granted;
    if (!granted) {
      if (mounted) {
        AniwaysSnackBar.error(
          context,
          message: 'Notifications are disabled in system settings',
          actionLabel: 'Settings',
          onAction: () => NotificationService.instance.openSettings(),
        );
      }
      return;
    }

    final subs = await _subRepo.getActiveSubscriptions();
    final String animeTitle = subs.isNotEmpty
        ? subs.first.animeTitle
        : 'Frieren: Beyond Journey\'s End';
    final int animeId = subs.isNotEmpty ? subs.first.animeId : 154587;
    final int epNum = subs.isNotEmpty ? subs.first.nextEpisodeNumber : 29;
    final String coverUrl = subs.isNotEmpty && subs.first.coverUrl != null
        ? subs.first.coverUrl!
        : 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-qQTzQnEJJ3oB.jpg';

    await BackgroundNotificationWorker.scheduleTestNotification(
      delay: delay,
      animeTitle: animeTitle,
      animeId: animeId,
      episodeNumber: epNum,
      coverUrl: coverUrl,
    );

    _countdownTimer?.cancel();
    _remainingTestSeconds = delay.inSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingTestSeconds--;
        if (_remainingTestSeconds <= 0) {
          timer.cancel();
        }
      });
    });

    setState(() {});

    if (mounted) {
      AniwaysSnackBar.success(
        context,
        message:
            'Alert scheduled in ${delay.inSeconds}s! Close or swipe Aniways away now to test.',
        icon: Icons.timer_outlined,
      );
    }
  }

  Future<void> _cancelTestTimer() async {
    _countdownTimer?.cancel();
    _remainingTestSeconds = 0;
    await BackgroundNotificationWorker.cancelTestNotification();
    setState(() {});
    if (mounted) {
      AniwaysSnackBar.info(
        context,
        message: 'Cancelled scheduled test alert',
        icon: Icons.cancel_outlined,
      );
    }
  }

  // ignore: unused_element
  void _showTestNotificationSheet() {
    HapticFeedback.lightImpact();

    if (_remainingTestSeconds > 0) {
      showOneUiBottomSheet<void>(
        context: context,
        isScrollControlled: false,
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: OneUiDragHandle()),
                  const SizedBox(height: 12),
                  Text(
                    'Active Test Timer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Background notification will trigger in $_remainingTestSeconds seconds via WorkManager.',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(
                          color: cs.error.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _cancelTestTimer();
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      label: const Text(
                        'Cancel Scheduled Test',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    showOneUiBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        double customSeconds = 45;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: OneUiDragHandle()),
                    const SizedBox(height: 12),
                    Text(
                      'Test Notification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify alert layout or test background delivery when Aniways is closed.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimerOptionTile(
                      ctx,
                      icon: Icons.flash_on_rounded,
                      title: 'Send Immediately',
                      subtitle: 'Fires sample alert now in foreground',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _sendTestNotification();
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildTimerOptionTile(
                      ctx,
                      icon: Icons.timer_outlined,
                      title: 'In 15 seconds',
                      subtitle: 'Quick test: lock screen or swipe app away',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _scheduleTestNotification(const Duration(seconds: 15));
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildTimerOptionTile(
                      ctx,
                      icon: Icons.schedule_rounded,
                      title: 'In 30 seconds (Recommended)',
                      subtitle: 'Plenty of time to swipe Aniways from Recents',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _scheduleTestNotification(const Duration(seconds: 30));
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildTimerOptionTile(
                      ctx,
                      icon: Icons.hourglass_bottom_rounded,
                      title: 'In 1 minute',
                      subtitle: 'Standard background worker test',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _scheduleTestNotification(const Duration(minutes: 1));
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Custom Timer',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  customSeconds >= 60
                                      ? '${(customSeconds / 60).toStringAsFixed(1)} min'
                                      : '${customSeconds.round()} sec',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: customSeconds,
                            min: 10,
                            max: 300,
                            divisions: 29,
                            onChanged: (val) {
                              setSheetState(() => customSeconds = val);
                            },
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _scheduleTestNotification(
                                  Duration(seconds: customSeconds.round()),
                                );
                              },
                              child: Text(
                                'Schedule in ${customSeconds.round()}s',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimerOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = CategoryColors.of(context);
    final cs = Theme.of(context).colorScheme;

    final enabled = _prefs.notificationEnabled;
    final minProviders = _prefs.notificationMinimumProviders;
    final autoSubscribe = _prefs.notificationAutoSubscribeWatching;
    final audioTrack = _prefs.notificationPreferredAudio;

    final audioLabel = switch (audioTrack) {
      'dub' => 'Dubbed only',
      'sub' => 'Subtitled only',
      _ => 'Either (Sub or Dub)',
    };

    return Scaffold(
      body: OneUiScrollView(
        title: 'Notifications',
        showBackButton: !widget.embedded,
        bottomPadding: MediaQuery.viewPaddingOf(context).bottom + 24,
        children: [
          // ── 1. Master Configuration ─────────────────────────────────────────
          Padding(
            padding: kSettingsHorizontalPadding,
            child: SettingsSectionHeader('General'),
          ),
          if (enabled && !_systemPermissionGranted) ...[
            Padding(
              padding: kSettingsHorizontalPadding,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.error.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_off_rounded,
                      color: cs.error,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications blocked by system',
                            style: TextStyle(
                              color: cs.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Allow notifications in system settings to receive alerts and updates.',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final granted = await NotificationService.instance
                            .requestPermission();
                        if (!granted) {
                          await NotificationService.instance.openSettings();
                        }
                        _checkSystemPermission();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: cs.error,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text(
                        'Enable',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  color: cat.playback,
                  title: 'Notifications',
                  subtitle: enabled
                      ? 'Receive episode releases, downloads, and app updates'
                      : 'No background alerts',
                  value: enabled,
                  isFirst: true,
                  isLast: !enabled,
                  onChanged: _handleToggleMaster,
                ),
                if (enabled) ...[
                  const SizedBox(height: 2),
                  SettingsActionTile(
                    icon: _isBatteryUnrestricted
                        ? Icons.battery_charging_full_rounded
                        : Icons.battery_saver_rounded,
                    color: _isBatteryUnrestricted ? cs.primary : cat.appearance,
                    title: 'Background Activity',
                    subtitle: _isBatteryUnrestricted
                        ? 'Unrestricted · Ready to deliver alerts in background'
                        : 'Optimized · Some devices may need this set to Unrestricted to deliver alerts on time',
                    isFirst: false,
                    isLast: true,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await NotificationService.instance
                          .openBatteryOptimizationSettings();
                    },
                  ),
                  // const SizedBox(height: 2),
                  // SettingsActionTile(
                  //   icon: _remainingTestSeconds > 0
                  //       ? Icons.timer_rounded
                  //       : Icons.notifications_active_outlined,
                  //   color: _remainingTestSeconds > 0 ? cs.error : cat.accounts,
                  //   title: 'Test Notification',
                  //   subtitle: _remainingTestSeconds > 0
                  //       ? 'Alert firing in ${_remainingTestSeconds}s · Tap to cancel'
                  //       : 'Send sample alert now or schedule a background delivery timer',
                  //   isFirst: false,
                  //   isLast: true,
                  //   onTap: _showTestNotificationSheet,
                  // ),
                ],
              ],
            ),
          ),

          // ── 2. Episode Alerts ────────────────────────────────────────────────
          if (enabled) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: kSettingsHorizontalPadding,
              child: SettingsSectionHeader('Episode Alerts'),
            ),
            Padding(
              padding: kSettingsHorizontalPadding,
              child: Column(
                children: [
                  SettingsSelectorTile<int>(
                    icon: Icons.speed_rounded,
                    color: cat.accounts,
                    title: 'Alert Delivery',
                    subtitle: minProviders >= 2
                        ? 'High Reliability · Wait for multiple servers'
                        : 'Fastest · Alert as soon as first stream appears',
                    currentValue: minProviders,
                    options: const [
                      SettingsOption(
                        2,
                        'High Reliability (Recommended)',
                        'Wait until streams are confirmed on multiple servers to avoid broken links',
                      ),
                      SettingsOption(
                        1,
                        'Fastest',
                        'Notify immediately as soon as the first stream appears online',
                      ),
                    ],
                    onSelected: (val) async {
                      await _prefs.setNotificationMinimumProviders(val);
                      setState(() {});
                    },
                    isFirst: true,
                    isLast: false,
                  ),
                  const SizedBox(height: 2),
                  SettingsSelectorTile<String>(
                    icon: Icons.record_voice_over_rounded,
                    color: cat.appearance,
                    title: 'Audio Preference',
                    subtitle: audioLabel,
                    currentValue: audioTrack,
                    options: const [
                      SettingsOption(
                        'either',
                        'Either (Recommended)',
                        'Notify as soon as either Sub or Dub is ready',
                      ),
                      SettingsOption(
                        'sub',
                        'Subtitled only',
                        'Notify only when original audio is ready',
                      ),
                      SettingsOption(
                        'dub',
                        'Dubbed only',
                        'Notify only when English / localized audio is ready',
                      ),
                    ],
                    onSelected: (val) async {
                      await _prefs.setNotificationPreferredAudio(val);
                      setState(() {});
                    },
                    isFirst: false,
                    isLast: false,
                  ),
                  const SizedBox(height: 2),
                  SettingsSwitchTile(
                    icon: Icons.video_library_rounded,
                    color: cat.downloads,
                    title: 'Auto-subscribe "Watching"',
                    subtitle: autoSubscribe
                        ? 'Automatically alert for any anime in your Watching list'
                        : 'Subscribe using the bell icon on anime pages',
                    value: autoSubscribe,
                    isFirst: false,
                    isLast: true,
                    onChanged: (val) async {
                      HapticFeedback.selectionClick();
                      await _prefs.setNotificationAutoSubscribeWatching(val);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 3. Active Subscriptions ─────────────────────────────────────────
            Padding(
              padding: kSettingsHorizontalPadding,
              child: SettingsSectionHeader(
                'Active Subscriptions',
                trailing: TextButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await checkAndNotifyEpisodes();
                    await BackgroundNotificationWorker.rescheduleAllSubscriptions();
                    if (context.mounted) {
                      AniwaysSnackBar.success(
                        context,
                        message: 'Checked latest episode releases',
                        icon: Icons.refresh_rounded,
                      );
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Check now'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: kSettingsHorizontalPadding,
              child: FutureBuilder<List<EpisodeSubscription>>(
                future: _subRepo.getActiveSubscriptions(),
                builder: (context, snapshot) {
                  final subs = snapshot.data ?? [];
                  if (subs.isEmpty) {
                    return Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 38,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No Active Subscriptions',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add anime to your "Watching" list or tap the bell icon on any anime page to subscribe.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < subs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 2),
                        _SubscriptionTile(
                          sub: subs[i],
                          isFirst: i == 0,
                          isLast: i == subs.length - 1,
                          onUnsubscribe: () async {
                            HapticFeedback.lightImpact();
                            await _subRepo.unsubscribe(subs[i].animeId);
                            setState(() {});
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Sub-components
// ═════════════════════════════════════════════════════════════════════════

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({
    required this.sub,
    required this.isFirst,
    required this.isLast,
    required this.onUnsubscribe,
  });

  final EpisodeSubscription sub;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onUnsubscribe;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: settingsTileBorderRadius(
          isFirst: isFirst,
          isLast: isLast,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 38,
            height: 52,
            child: AnimeImage(sub.coverUrl),
          ),
        ),
        title: Text(
          sub.animeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'Next: Ep ${sub.nextEpisodeNumber}',
          style: TextStyle(
            color: cs.primary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.notifications_active_rounded,
            color: cs.primary,
            size: 22,
          ),
          tooltip: 'Unsubscribe',
          onPressed: onUnsubscribe,
        ),
      ),
    );
  }
}
