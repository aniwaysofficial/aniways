import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aniways/core/services/backup_restore_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/navigation/main_navigation.dart';
import 'package:aniways/providers/theme_provider.dart';
import 'package:aniways/screens/onboarding/cards/anime_picks_card.dart';
import 'package:aniways/screens/onboarding/cards/audio_subtitle_card.dart';
import 'package:aniways/screens/onboarding/cards/backup_setup_card.dart';
import 'package:aniways/screens/onboarding/cards/completion_card.dart';
import 'package:aniways/screens/onboarding/cards/notification_setup_card.dart';
import 'package:aniways/screens/onboarding/cards/theme_setup_card.dart';
import 'package:aniways/screens/onboarding/cards/welcome_card.dart';
import 'package:aniways/screens/onboarding/widgets/onboarding_card_scaffold.dart';
import 'package:aniways/screens/settings/widgets/restore_summary_sheet.dart';

/// Fullscreen first-launch setup.
///
/// Page 0 is a welcome screen (with restore for returning users). Pages 1-6
/// are setup steps with a single progress bar on top and a single primary
/// button at the bottom, so the steps themselves stay uncluttered.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _totalPages = 7;
  static const int _welcomePage = 0;
  static const int _lastPage = _totalPages - 1;

  final PageController _pageController = PageController();
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final BackupRestoreService _backupService = BackupRestoreService.instance;

  int _currentPage = _welcomePage;
  bool _isRestoring = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _lastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToPage(int page) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    await _prefs.setHasCompletedOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainNavigation(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Returning user: restore a .hnm backup directly
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _handleRestoreBackup() async {
    HapticFeedback.lightImpact();
    try {
      final file = await FilePicker.pickFile(type: FileType.any);

      if (file == null) return;
      final fileName = file.name;
      final filePath = file.path;

      if (!fileName.toLowerCase().endsWith('.anw') &&
          !fileName.toLowerCase().endsWith('.hnm') &&
          !fileName.toLowerCase().endsWith('.json') &&
          (filePath == null ||
              (!filePath.toLowerCase().endsWith('.anw') &&
                  !filePath.toLowerCase().endsWith('.hnm') &&
                  !filePath.toLowerCase().endsWith('.json')))) {
        if (!mounted) return;
        AniwaysSnackBar.error(
          context,
          message: 'Please select a valid Aniways backup file (.anw)',
          extraBottomMargin: 130.0,
        );
        return;
      }

      if (filePath == null) {
        throw const FormatException('Could not resolve selected file path.');
      }

      setState(() => _isRestoring = true);
      final summary = await _backupService.readBackupFromFile(filePath);
      if (!mounted) return;
      setState(() => _isRestoring = false);

      await showRestoreSummarySheet(
        context: context,
        summary: summary,
        hideMergeOption: true,
        onRestoreSuccess: () async {
          await _prefs.setHasCompletedOnboarding(true);
          if (mounted) {
            context.read<ThemeProvider>().reload();
            AniwaysSnackBar.success(
              context,
              message: 'Backup restored. Welcome back!',
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigation()),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        AniwaysSnackBar.error(
          context,
          message: 'Failed to restore backup: $e',
          extraBottomMargin: 130.0,
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final showChrome = _currentPage > _welcomePage;
    final isLast = _currentPage == _lastPage;

    return PopScope(
      canPop: _currentPage == _welcomePage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previousPage();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: !showChrome,
          child: Column(
            children: [
              // ── Top bar: clean Back button & Skip action ──────────────────
              AnimatedOpacity(
                opacity: showChrome ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !showChrome,
                  child: Center(
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kOnboardingMaxWidth + 48,
                      ),
                      child: SizedBox(
                        height: 52,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                tooltip: 'Back',
                                onPressed: _previousPage,
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              AnimatedOpacity(
                                opacity: isLast ? 0 : 1,
                                duration: const Duration(milliseconds: 200),
                                child: IgnorePointer(
                                  ignoring: isLast,
                                  child: TextButton(
                                    onPressed: _completeOnboarding,
                                    child: const Text(
                                      'Skip',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Pages ───────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    WelcomeCard(
                      onStart: _nextPage,
                      onRestore: _handleRestoreBackup,
                      isRestoring: _isRestoring,
                    ),
                    const ThemeSetupCard(),
                    const AudioSubtitleCard(),
                    const NotificationSetupCard(),
                    const BackupSetupCard(),
                    const AnimePicksCard(),
                    CompletionCard(onEdit: _goToPage),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: showChrome
              ? SafeArea(
                  top: false,
                  child: Center(
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kOnboardingMaxWidth + 48,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StepIndicator(
                              current: _currentPage,
                              total: _totalPages - 1,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: _nextPage,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 180),
                                  child: Row(
                                    key: ValueKey(isLast),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isLast) ...[
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        isLast
                                            ? 'Start watching'
                                            : 'Continue',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ),
    );
  }
}

/// Minimalist One UI step indicator: inactive steps are subtle dots,
/// and the active step smoothly expands into a rounded pill.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: i == current ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current
                  ? cs.primary
                  : (i < current
                      ? cs.primary.withValues(alpha: 0.38)
                      : cs.outlineVariant.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}
