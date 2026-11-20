import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/services/background_notification_worker.dart';
import 'package:aniways/core/services/notification_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/screens/onboarding/widgets/onboarding_card_scaffold.dart';

/// Step: Episode release alerts and Android notification permission.
class NotificationSetupCard extends StatefulWidget {
  const NotificationSetupCard({super.key});

  @override
  State<NotificationSetupCard> createState() => _NotificationSetupCardState();
}

class _NotificationSetupCardState extends State<NotificationSetupCard>
    with WidgetsBindingObserver {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  late bool _enabled;
  bool _hasSystemPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enabled = _prefs.notificationEnabled;
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance
        .areNotificationsEnabled();
    if (mounted && granted != _hasSystemPermission) {
      setState(() => _hasSystemPermission = granted);
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    HapticFeedback.selectionClick();
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      _hasSystemPermission = granted;
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
        setState(() => _enabled = false);
        return;
      }
      await _prefs.setNotificationEnabled(true);
      await BackgroundNotificationWorker.registerPeriodicTask();
      await BackgroundNotificationWorker.rescheduleAllSubscriptions();
      setState(() => _enabled = true);
      if (mounted) {
        AniwaysSnackBar.success(
          context,
          message: 'Notifications enabled',
          icon: Icons.notifications_active_rounded,
        );
      }
    } else {
      await _prefs.setNotificationEnabled(false);
      await BackgroundNotificationWorker.cancelPeriodicTask();
      await NotificationService.instance.cancelAll();
      setState(() => _enabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = CategoryColors.of(context);

    return OnboardingPage(
      title: 'Notifications',
      subtitle:
          'Get notified about new episodes, releases, and app updates.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── System Permission Notice (if enabled in app but blocked in OS) ──
          if (_enabled && !_hasSystemPermission) ...[
            Container(
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
                      _checkPermission();
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
            const SizedBox(height: 20),
          ],

          // ── Main Permission Toggle ──
          OnboardingSection(
            child: OnboardingGroup(
              tiles: [
                OnboardingTile(
                  icon: Icons.notifications_active_rounded,
                  color: cat.playback,
                  title: 'Notifications',
                  subtitle: _enabled
                      ? 'Enabled · You will receive alerts and updates'
                      : 'Disabled · Tap switch to grant permission',
                  trailing: Switch.adaptive(
                    value: _enabled,
                    onChanged: _toggleEnabled,
                  ),
                  onTap: () => _toggleEnabled(!_enabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Clean info card explaining where settings can be fine-tuned ──
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          //     borderRadius: BorderRadius.circular(20),
          //     border: Border.all(
          //       color: cs.outlineVariant.withValues(alpha: 0.3),
          //       width: 0.8,
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(
          //         Icons.tune_rounded,
          //         color: cs.onSurfaceVariant,
          //         size: 22,
          //       ),
          //       const SizedBox(width: 14),
          //       Expanded(
          //         child: Text(
          //           'You can fine-tune streaming audio preferences, provider verification, and manage anime subscriptions anytime in Settings → Notifications.',
          //           style: TextStyle(
          //             fontSize: 13,
          //             color: cs.onSurfaceVariant,
          //             height: 1.35,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
