import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:aniways/core/device_control.dart';
import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/navigation/main_navigation.dart'
    show FullBleedScreen, MainNavigation;
import 'package:aniways/providers/watch_provider.dart';

import 'player_controls.dart';

/// Dedicated fullscreen landscape video player screen.
///
/// Automatically rotates the device to landscape, hides system status and
/// navigation bars, enables wakelock, and presents the full Aniways custom
/// player controls overlay with gestures.
class AnimePlayerScreen extends StatefulWidget implements FullBleedScreen {
  const AnimePlayerScreen({
    super.key,
    required this.wp,
    required this.anime,
    required this.accent,
  });

  final WatchProvider wp;
  final AnimeMedia anime;
  final Color accent;

  static Future<void> open(
    BuildContext context,
    WatchProvider wp, {
    required AnimeMedia anime,
    required Color accent,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    MainNavigation.hideNavRail.value = true;
    await DeviceControl.ensureBetterPlayerReady();

    // Flag fullscreen immediately so fast responses from cache/local server trigger autoplay
    wp.isFullScreenNotifier.value = true;
    try {
      await WakelockPlus.enable();
    } catch (_) {}

    // Request landscape upfront so the window starts rotating immediately
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!context.mounted) {
      MainNavigation.hideNavRail.value = false;
      wp.isFullScreenNotifier.value = false;
      try {
        await WakelockPlus.disable();
      } catch (_) {}
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return;
    }

    final parentTheme = Theme.of(context);
    final isDark = parentTheme.brightness == Brightness.dark;
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;

    final seededScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: parentTheme.brightness,
    );

    final isPureBlack =
        parentTheme.colorScheme.surface == const Color(0xFF000000) ||
        parentTheme.scaffoldBackgroundColor == const Color(0xFF000000);

    final themed = parentTheme.copyWith(
      colorScheme: seededScheme.copyWith(
        primary: accent,
        onPrimary: onAccent,
        primaryContainer: accent.withValues(alpha: isDark ? 0.25 : 0.15),
        onPrimaryContainer: isDark ? Colors.white : accent,
        surface: isPureBlack
            ? const Color(0xFF000000)
            : (isDark ? const Color(0xFF141416) : const Color(0xFFFFFFFF)),
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerLow: isPureBlack
            ? const Color(0xFF0A0A0A)
            : (isDark ? const Color(0xFF18181A) : const Color(0xFFF2F2F6)),
        surfaceContainer: isPureBlack
            ? const Color(0xFF121214)
            : (isDark ? const Color(0xFF202024) : const Color(0xFFEDEDF2)),
        surfaceContainerHigh: Color.alphaBlend(
          accent.withValues(alpha: isDark ? 0.15 : 0.09),
          isDark ? const Color(0xFF18181C) : const Color(0xFFEAEAEF),
        ),
        surfaceContainerHighest: Color.alphaBlend(
          accent.withValues(alpha: isDark ? 0.22 : 0.14),
          isDark ? const Color(0xFF1E1E22) : const Color(0xFFE4E4E8),
        ),
        outlineVariant: Color.alphaBlend(
          accent.withValues(alpha: isDark ? 0.32 : 0.24),
          seededScheme.outlineVariant,
        ),
      ),
      scaffoldBackgroundColor: Colors.black,
      primaryColor: accent,
    );

    NavigatorState nav;
    try {
      nav = Navigator.of(context, rootNavigator: false);
    } catch (_) {
      nav = Navigator.of(context, rootNavigator: true);
    }

    try {
      await nav.push<void>(
        PageRouteBuilder<void>(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (pageContext, animation, secondaryAnimation) {
            return Theme(
              data: themed,
              child: ChangeNotifierProvider<WatchProvider>.value(
                value: wp,
                child: AnimePlayerScreen(wp: wp, anime: anime, accent: accent),
              ),
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } finally {
      MainNavigation.hideNavRail.value = false;
    }
  }

  @override
  State<AnimePlayerScreen> createState() => _AnimePlayerScreenState();
}

class _AnimePlayerScreenState extends State<AnimePlayerScreen>
    with WidgetsBindingObserver {
  bool _isExiting = false;
  bool _hasInitialStreamLoaded = false;

  void _handleExit() {
    if (_isExiting) return;
    _isExiting = true;
    MainNavigation.hideNavRail.value = false;
    widget.wp.cancelPlayback();
  }

  @override
  void initState() {
    super.initState();
    MainNavigation.hideNavRail.value = true;
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    _hasInitialStreamLoaded =
        widget.wp.isVideoInitialized && widget.wp.state == WatchState.playing;
    WidgetsBinding.instance.addObserver(this);
    _enterLandscape();
    try {
      WakelockPlus.enable();
    } catch (_) {}
    widget.wp.isFullScreenNotifier.value = true;
    widget.wp.syncDeviceVolumeAndBrightness();

    // Guard against autoplay race: if player is already initialized by the time this mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.wp.isVideoInitialized &&
          !widget.wp.isPlayingNotifier.value &&
          widget.wp.state == WatchState.playing) {
        widget.wp.play();
      }
    });
  }

  Future<void> _enterLandscape() async {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Suppress soft keyboard reopening across physical/software rotation
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  Future<void> _exitLandscape() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.wp.betterPlayerController?.pause();
      widget.wp.isPlayingNotifier.value = false;
      try {
        WakelockPlus.disable();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      try {
        WakelockPlus.enable();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.wp.isFullScreenNotifier.value = false;
    _handleExit();
    DeviceControl.resetBrightness();
    _exitLandscape();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WatchProvider>();
    final size = MediaQuery.sizeOf(context);
    final screenAspect = size.width / (size.height > 0 ? size.height : 1.0);
    wp.updateScreenAspect(screenAspect);

    if (!_hasInitialStreamLoaded &&
        wp.state == WatchState.playing &&
        wp.betterPlayerController != null) {
      _hasInitialStreamLoaded = true;
    }

    // Only show full-screen artwork splash on cold start entry.
    // Subsequent in-player stream switches (e.g. Sub -> Dub, server switch)
    // stay in the player theater with standard center buffering loader.
    final showInitialSplash = !_hasInitialStreamLoaded &&
        (wp.state == WatchState.loadingStream ||
            wp.state == WatchState.loading ||
            wp.betterPlayerController == null);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _handleExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. BetterPlayer Video View
            if (wp.betterPlayerController != null)
              Center(
                child: BetterPlayer(
                  key: ValueKey(
                    'player_${wp.playerKeyVersion}_${wp.currentAspectRatio}',
                  ),
                  controller: wp.betterPlayerController!,
                ),
              ),

            // 2. Loading stream spinner overlay (solid, initial launch only)
            if (showInitialSplash)
              Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    if (wp.currentEpisode?.image != null ||
                        widget.anime.bannerUrl != null ||
                        widget.anime.coverUrl != null)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.22,
                          child: CachedNetworkImage(
                            imageUrl:
                                wp.currentEpisode?.image ??
                                widget.anime.bannerUrl ??
                                widget.anime.coverUrl!,
                            cacheManager: ImageCacheService.animeImageCache,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              strokeCap: StrokeCap.round,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            wp.currentEpisode != null
                                ? 'Loading Episode ${wp.currentEpisode!.number}...'
                                : 'Loading stream...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PlayerBackButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _handleExit();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

            // 3. Error state overlay
            if (wp.state == WatchState.error)
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            wp.errorMessage ?? 'Playback error occurred',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white38),
                                ),
                                onPressed: () {
                                  if (wp.currentEpisode != null) {
                                    wp.playEpisode(
                                      wp.currentEpisode!,
                                      accent: widget.accent,
                                    );
                                  }
                                },
                                child: const Text('Retry'),
                              ),
                              if (wp.selectedAudio == StreamAudio.dub &&
                                  wp.hasSub)
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: widget.accent,
                                  ),
                                  icon: const Icon(
                                    Icons.subtitles_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Watch in Subtitled'),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    wp.setAudio(StreamAudio.sub);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _PlayerBackButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _handleExit();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),

            // 4. Custom Aniways Player Controls (active when playing or switching streams in-player)
            if ((wp.state == WatchState.playing || _hasInitialStreamLoaded) &&
                wp.state != WatchState.error)
              PlayerControls(
                wp: wp,
                anime: widget.anime,
                accent: widget.accent,
                onBack: () {
                  _handleExit();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerBackButton extends StatelessWidget {
  const _PlayerBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 24,
        ),
        tooltip: 'Back',
        onPressed: onPressed,
      ),
    );
  }
}
