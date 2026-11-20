import 'package:flutter/material.dart';

import 'package:aniways/core/constants.dart';
import 'package:aniways/core/widgets/app_logo.dart';
import 'package:aniways/screens/onboarding/widgets/onboarding_card_scaffold.dart';

/// Step 0: Welcome. Returning users can restore a backup from here instead of
/// a button crowding the top bar on every step.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    super.key,
    required this.onStart,
    required this.onRestore,
    required this.isRestoring,
  });

  final VoidCallback onStart;
  final VoidCallback onRestore;
  final bool isRestoring;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kOnboardingMaxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 20,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                cs.primary.withValues(alpha: 0.28),
                                                cs.primary.withValues(alpha: 0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const AppLogo(size: 88),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppConstants.appName,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Track what you watch and find what to watch next.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: onStart,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Get started'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton.icon(
                          onPressed: isRestoring ? null : onRestore,
                          icon: isRestoring
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    strokeCap: StrokeCap.round,
                                  ),
                                )
                              : const Icon(
                                  Icons.settings_backup_restore_rounded,
                                  size: 20,
                                ),
                          label: const Text('Restore from a backup'),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
