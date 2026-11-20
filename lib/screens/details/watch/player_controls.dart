import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/helpers.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/providers/watch_provider.dart';

import 'widgets/locked_controls_overlay.dart';
import 'widgets/player_gestures.dart';
import 'widgets/player_timeline_seekbar.dart';
import 'widgets/player_top_bar.dart';
import 'widgets/player_transport_bar.dart';

/// Custom, themed player controls overlay designed specifically for Aniways.
///
/// Features:
/// - Double tap left/right to seek ±10s with VLC-style arc overlay
/// - Vertical drag left for brightness, right for volume
/// - Long press for 2× speed boost with on-screen badge
/// - Timeline seekbar with intro and outro highlighted markers
/// - Lock screen button to prevent accidental touches
/// - Auto-next episode countdown card on video finish
/// - Auto-hiding overlay (3.5s idle)
class PlayerControls extends StatefulWidget {
  const PlayerControls({
    super.key,
    required this.wp,
    required this.accent,
    this.anime,
    this.onBack,
  });

  final WatchProvider wp;
  final Color accent;
  final AnimeMedia? anime;
  final VoidCallback? onBack;

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls>
    with TickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnimation;

  Timer? _hideTimer;
  bool _isVisible = true;

  // Double tap accumulative seek (VLC style: double-taps accumulate, single taps never seek)
  late final AnimationController _leftSeekAnimCtrl;
  late final Animation<double> _leftSeekFade;
  late final AnimationController _rightSeekAnimCtrl;
  late final Animation<double> _rightSeekFade;
  Timer? _leftSingleTapTimer;
  Timer? _rightSingleTapTimer;
  Timer? _leftSeekDismissTimer;
  Timer? _rightSeekDismissTimer;
  int _accumulatedLeftSeek = 0;
  int _accumulatedRightSeek = 0;
  bool _isLeftSeeking = false;
  bool _isRightSeeking = false;

  // Gesture indicators
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  Timer? _gestureIndicatorTimer;

  // System gesture exclusion deadzones (prevents accidental volume/brightness
  // shifts when pulling quick settings / notification shade or nav bar)
  bool _ignoreLeftDrag = false;
  bool _ignoreRightDrag = false;
  Offset? _leftTouchDown;
  Offset? _rightTouchDown;

  // Drag direction disambiguation (prevents accidental horizontal or diagonal
  // gestures from triggering volume or brightness adjustments)
  double _leftAccumulatedDx = 0.0;
  double _leftAccumulatedDy = 0.0;
  bool _leftVerticalLocked = false;

  double _rightAccumulatedDx = 0.0;
  double _rightAccumulatedDy = 0.0;
  bool _rightVerticalLocked = false;

  WatchProvider get wp => widget.wp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );

    _leftSeekAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _leftSeekFade = CurvedAnimation(
      parent: _leftSeekAnimCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _rightSeekAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _rightSeekFade = CurvedAnimation(
      parent: _rightSeekAnimCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    wp.isPlayingNotifier.addListener(_onPlayStateChanged);
    _scheduleHide();
  }

  void _onPlayStateChanged() {
    if (wp.isPlayingNotifier.value && _isVisible) {
      _scheduleHide();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_isVisible && wp.isPlayingNotifier.value) {
      _hideTimer = Timer(const Duration(milliseconds: 3500), _hideControls);
    }
  }

  void _toggleControls() {
    if (_isVisible) {
      _hideControls();
    } else {
      _showControls();
    }
  }

  void _showControls() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
      _animCtrl.forward();
    }
    _scheduleHide();
  }

  void _hideControls() {
    if (_isVisible) {
      setState(() => _isVisible = false);
      _animCtrl.reverse();
    }
  }

  void _onLeftTap() {
    // Cross-side cancellation: cancel any pending or active right-side taps/seeks
    _rightSingleTapTimer?.cancel();
    _rightSingleTapTimer = null;
    if (_isRightSeeking) {
      _rightSeekDismissTimer?.cancel();
      _rightSeekAnimCtrl.reverse();
      _isRightSeeking = false;
      _accumulatedRightSeek = 0;
    }

    if (_leftSingleTapTimer?.isActive ?? false) {
      // ── CONFIRMED DOUBLE TAP ──
      // This is the 2nd tap within doubleTapTimeout (250ms)!
      _leftSingleTapTimer?.cancel();
      _leftSingleTapTimer = null;

      // Seeking requires video to be initialized
      if (!wp.isVideoInitialized) return;

      if (_isVisible) _hideControls();

      final step = SharedPreferencesService().doubleTapSeekDuration;
      setState(() {
        if (_isLeftSeeking) {
          _accumulatedLeftSeek += step;
        } else {
          _isLeftSeeking = true;
          _accumulatedLeftSeek = step;
        }
      });

      wp.seekRelative(Duration(seconds: -step));
      HapticFeedback.lightImpact();
      _leftSeekAnimCtrl.forward();

      // Reset the visual dismissal timer while user continues double-tapping
      _leftSeekDismissTimer?.cancel();
      _leftSeekDismissTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _leftSeekAnimCtrl.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isLeftSeeking = false;
              _accumulatedLeftSeek = 0;
            });
          }
        });
      });
    } else {
      // ── FIRST TAP ──
      // Wait for a possible 2nd tap (double-tap threshold: 250ms).
      // If no 2nd tap arrives, this is strictly a SINGLE TAP:
      // A single tap NEVER seeks! It toggles controls and dismisses seek HUD.
      _leftSingleTapTimer = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _leftSingleTapTimer = null;

        // If the seek HUD is lingering, dismiss it immediately on single tap
        if (_isLeftSeeking) {
          _leftSeekDismissTimer?.cancel();
          _leftSeekAnimCtrl.reverse().then((_) {
            if (mounted) {
              setState(() {
                _isLeftSeeking = false;
                _accumulatedLeftSeek = 0;
              });
            }
          });
        }

        _toggleControls();
      });
    }
  }

  void _onRightTap() {
    // Cross-side cancellation: cancel any pending or active left-side taps/seeks
    _leftSingleTapTimer?.cancel();
    _leftSingleTapTimer = null;
    if (_isLeftSeeking) {
      _leftSeekDismissTimer?.cancel();
      _leftSeekAnimCtrl.reverse();
      _isLeftSeeking = false;
      _accumulatedLeftSeek = 0;
    }

    if (_rightSingleTapTimer?.isActive ?? false) {
      // ── CONFIRMED DOUBLE TAP ──
      // This is the 2nd tap within doubleTapTimeout (250ms)!
      _rightSingleTapTimer?.cancel();
      _rightSingleTapTimer = null;

      // Seeking requires video to be initialized
      if (!wp.isVideoInitialized) return;

      if (_isVisible) _hideControls();

      final step = SharedPreferencesService().doubleTapSeekDuration;
      setState(() {
        if (_isRightSeeking) {
          _accumulatedRightSeek += step;
        } else {
          _isRightSeeking = true;
          _accumulatedRightSeek = step;
        }
      });

      wp.seekRelative(Duration(seconds: step));
      HapticFeedback.lightImpact();
      _rightSeekAnimCtrl.forward();

      // Reset the visual dismissal timer while user continues double-tapping
      _rightSeekDismissTimer?.cancel();
      _rightSeekDismissTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _rightSeekAnimCtrl.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isRightSeeking = false;
              _accumulatedRightSeek = 0;
            });
          }
        });
      });
    } else {
      // ── FIRST TAP ──
      // Wait for a possible 2nd tap (double-tap threshold: 250ms).
      // If no 2nd tap arrives, this is strictly a SINGLE TAP:
      // A single tap NEVER seeks! It toggles controls and dismisses seek HUD.
      _rightSingleTapTimer = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _rightSingleTapTimer = null;

        // If the seek HUD is lingering, dismiss it immediately on single tap
        if (_isRightSeeking) {
          _rightSeekDismissTimer?.cancel();
          _rightSeekAnimCtrl.reverse().then((_) {
            if (mounted) {
              setState(() {
                _isRightSeeking = false;
                _accumulatedRightSeek = 0;
              });
            }
          });
        }

        _toggleControls();
      });
    }
  }

  void _showGestureIndicator({required bool isVolume}) {
    setState(() {
      if (isVolume) {
        _showVolumeIndicator = true;
      } else {
        _showBrightnessIndicator = true;
      }
    });
    _gestureIndicatorTimer?.cancel();
    _gestureIndicatorTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showVolumeIndicator = false;
          _showBrightnessIndicator = false;
        });
      }
    });
  }

  bool _isSystemGestureZone(Offset position) {
    final screenSize = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final topDeadzone = math.max(75.0, padding.top + 45.0);
    final bottomDeadzone = math.max(50.0, padding.bottom + 30.0);
    const sideDeadzone = 32.0;

    final x = position.dx;
    final y = position.dy;

    if (y < topDeadzone) return true;
    if (y > screenSize.height - bottomDeadzone) return true;
    if (x < sideDeadzone || x > screenSize.width - sideDeadzone) return true;

    return false;
  }

  // ── Left Side Drag (Brightness) ──

  void _onLeftDragDown(DragDownDetails details) {
    _leftTouchDown = details.globalPosition;
  }

  void _onLeftDragStart(DragStartDetails details) {
    _leftSingleTapTimer?.cancel();
    _leftSingleTapTimer = null;
    if (_isLeftSeeking) {
      _leftSeekDismissTimer?.cancel();
      _leftSeekAnimCtrl.reverse();
      _isLeftSeeking = false;
      _accumulatedLeftSeek = 0;
    }
    if (_isRightSeeking) {
      _rightSeekDismissTimer?.cancel();
      _rightSeekAnimCtrl.reverse();
      _isRightSeeking = false;
      _accumulatedRightSeek = 0;
    }

    _leftAccumulatedDx = 0.0;
    _leftAccumulatedDy = 0.0;
    _leftVerticalLocked = false;

    if (!SharedPreferencesService().enableSwipeGestures) {
      _ignoreLeftDrag = true;
      return;
    }
    final startPos = _leftTouchDown ?? details.globalPosition;
    _ignoreLeftDrag = _isSystemGestureZone(startPos);
  }

  void _onLeftDragUpdate(DragUpdateDetails details) {
    if (_ignoreLeftDrag) return;

    final dx = details.delta.dx.abs();
    final dy = (details.primaryDelta ?? details.delta.dy).abs();
    _leftAccumulatedDx += dx;
    _leftAccumulatedDy += dy;

    if (!_leftVerticalLocked) {
      // If horizontal displacement equals or exceeds vertical displacement,
      // this is an accidental horizontal swipe. Immediately ignore this gesture.
      if (_leftAccumulatedDx >= _leftAccumulatedDy) {
        _ignoreLeftDrag = true;
        return;
      }

      // Require a minimum vertical movement threshold (10dp) and dominant
      // vertical orientation (dy > dx * 1.25) to confirm a vertical gesture.
      const double threshold = 10.0;
      if (_leftAccumulatedDy >= threshold &&
          _leftAccumulatedDy > _leftAccumulatedDx * 1.25) {
        _leftVerticalLocked = true;
      } else {
        return;
      }
    }

    _scheduleHide();
    final primaryDelta = details.primaryDelta ?? details.delta.dy;
    if (primaryDelta == 0.0) return;
    final delta = -primaryDelta / 180;
    final next = (wp.brightnessNotifier.value + delta).clamp(0.0, 1.0);
    wp.setBrightness(next);
    _showGestureIndicator(isVolume: false);
  }

  void _onLeftDragEnd(DragEndDetails details) {
    _ignoreLeftDrag = false;
    _leftTouchDown = null;
    _leftAccumulatedDx = 0.0;
    _leftAccumulatedDy = 0.0;
    _leftVerticalLocked = false;
  }

  void _onLeftDragCancel() {
    _ignoreLeftDrag = false;
    _leftTouchDown = null;
    _leftAccumulatedDx = 0.0;
    _leftAccumulatedDy = 0.0;
    _leftVerticalLocked = false;
  }

  // ── Left Side Horizontal Drag (Absorbs horizontal gestures safely) ──

  void _onLeftHorizontalDragDown(DragDownDetails details) {
    _leftTouchDown = details.globalPosition;
  }

  void _onLeftHorizontalDragStart(DragStartDetails details) {
    _leftSingleTapTimer?.cancel();
    _leftSingleTapTimer = null;
    if (_isLeftSeeking) {
      _leftSeekDismissTimer?.cancel();
      _leftSeekAnimCtrl.reverse();
      _isLeftSeeking = false;
      _accumulatedLeftSeek = 0;
    }
    if (_isVisible) {
      _scheduleHide();
    }
  }

  void _onLeftHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isVisible) {
      _scheduleHide();
    }
  }

  void _onLeftHorizontalDragEnd(DragEndDetails details) {
    _leftTouchDown = null;
  }

  void _onLeftHorizontalDragCancel() {
    _leftTouchDown = null;
  }

  // ── Right Side Drag (Volume) ──

  void _onRightDragDown(DragDownDetails details) {
    _rightTouchDown = details.globalPosition;
  }

  void _onRightDragStart(DragStartDetails details) {
    _rightSingleTapTimer?.cancel();
    _rightSingleTapTimer = null;
    if (_isLeftSeeking) {
      _leftSeekDismissTimer?.cancel();
      _leftSeekAnimCtrl.reverse();
      _isLeftSeeking = false;
      _accumulatedLeftSeek = 0;
    }
    if (_isRightSeeking) {
      _rightSeekDismissTimer?.cancel();
      _rightSeekAnimCtrl.reverse();
      _isRightSeeking = false;
      _accumulatedRightSeek = 0;
    }

    _rightAccumulatedDx = 0.0;
    _rightAccumulatedDy = 0.0;
    _rightVerticalLocked = false;

    if (!SharedPreferencesService().enableSwipeGestures) {
      _ignoreRightDrag = true;
      return;
    }
    final startPos = _rightTouchDown ?? details.globalPosition;
    _ignoreRightDrag = _isSystemGestureZone(startPos);
  }

  void _onRightDragUpdate(DragUpdateDetails details) {
    if (_ignoreRightDrag) return;

    final dx = details.delta.dx.abs();
    final dy = (details.primaryDelta ?? details.delta.dy).abs();
    _rightAccumulatedDx += dx;
    _rightAccumulatedDy += dy;

    if (!_rightVerticalLocked) {
      // If horizontal displacement equals or exceeds vertical displacement,
      // this is an accidental horizontal swipe. Immediately ignore this gesture.
      if (_rightAccumulatedDx >= _rightAccumulatedDy) {
        _ignoreRightDrag = true;
        return;
      }

      // Require a minimum vertical movement threshold (10dp) and dominant
      // vertical orientation (dy > dx * 1.25) to confirm a vertical gesture.
      const double threshold = 10.0;
      if (_rightAccumulatedDy >= threshold &&
          _rightAccumulatedDy > _rightAccumulatedDx * 1.25) {
        _rightVerticalLocked = true;
      } else {
        return;
      }
    }

    _scheduleHide();
    final primaryDelta = details.primaryDelta ?? details.delta.dy;
    if (primaryDelta == 0.0) return;
    final delta = -primaryDelta / 180;
    final next = (wp.volumeNotifier.value + delta).clamp(0.0, 1.0);
    wp.setVolume(next);
    _showGestureIndicator(isVolume: true);
  }

  void _onRightDragEnd(DragEndDetails details) {
    _ignoreRightDrag = false;
    _rightTouchDown = null;
    _rightAccumulatedDx = 0.0;
    _rightAccumulatedDy = 0.0;
    _rightVerticalLocked = false;
  }

  void _onRightDragCancel() {
    _ignoreRightDrag = false;
    _rightTouchDown = null;
    _rightAccumulatedDx = 0.0;
    _rightAccumulatedDy = 0.0;
    _rightVerticalLocked = false;
  }

  // ── Right Side Horizontal Drag (Absorbs horizontal gestures safely) ──

  void _onRightHorizontalDragDown(DragDownDetails details) {
    _rightTouchDown = details.globalPosition;
  }

  void _onRightHorizontalDragStart(DragStartDetails details) {
    _rightSingleTapTimer?.cancel();
    _rightSingleTapTimer = null;
    if (_isRightSeeking) {
      _rightSeekDismissTimer?.cancel();
      _rightSeekAnimCtrl.reverse();
      _isRightSeeking = false;
      _accumulatedRightSeek = 0;
    }
    if (_isVisible) {
      _scheduleHide();
    }
  }

  void _onRightHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isVisible) {
      _scheduleHide();
    }
  }

  void _onRightHorizontalDragEnd(DragEndDetails details) {
    _rightTouchDown = null;
  }

  void _onRightHorizontalDragCancel() {
    _rightTouchDown = null;
  }

  @override
  void dispose() {
    wp.isPlayingNotifier.removeListener(_onPlayStateChanged);
    _hideTimer?.cancel();
    _leftSingleTapTimer?.cancel();
    _rightSingleTapTimer?.cancel();
    _leftSeekDismissTimer?.cancel();
    _rightSeekDismissTimer?.cancel();
    _gestureIndicatorTimer?.cancel();
    _leftSeekAnimCtrl.dispose();
    _rightSeekAnimCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: wp.isControlsLockedNotifier,
      builder: (context, isLocked, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Background Gradient (Visual only, never blocks touches) ──
            IgnorePointer(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.28, 0.72, 1.0],
                      colors: [
                        Color(0xB3000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0xD9000000),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 2. Gesture Detection Surface (Always active for swipe & tap) ──
            Positioned.fill(
              child: isLocked
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleControls,
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleControls,
                      onLongPressStart: (_) {
                        _leftSingleTapTimer?.cancel();
                        _leftSingleTapTimer = null;
                        _rightSingleTapTimer?.cancel();
                        _rightSingleTapTimer = null;
                        if (!SharedPreferencesService()
                            .enableLongPressSpeedBoost) {
                          return;
                        }
                        HapticFeedback.heavyImpact();
                        wp.setSpeedBoost(true);
                      },
                      onLongPressEnd: (_) {
                        if (!SharedPreferencesService()
                            .enableLongPressSpeedBoost) {
                          return;
                        }
                        wp.setSpeedBoost(false);
                      },
                      child: Row(
                        children: [
                          // Left half (brightness + double-tap rewind)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onLeftTap,
                              onVerticalDragDown: _onLeftDragDown,
                              onVerticalDragStart: _onLeftDragStart,
                              onVerticalDragUpdate: _onLeftDragUpdate,
                              onVerticalDragEnd: _onLeftDragEnd,
                              onVerticalDragCancel: _onLeftDragCancel,
                              onHorizontalDragDown: _onLeftHorizontalDragDown,
                              onHorizontalDragStart: _onLeftHorizontalDragStart,
                              onHorizontalDragUpdate:
                                  _onLeftHorizontalDragUpdate,
                              onHorizontalDragEnd: _onLeftHorizontalDragEnd,
                              onHorizontalDragCancel:
                                  _onLeftHorizontalDragCancel,
                            ),
                          ),
                          // Right half (volume + double-tap forward)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onRightTap,
                              onVerticalDragDown: _onRightDragDown,
                              onVerticalDragStart: _onRightDragStart,
                              onVerticalDragUpdate: _onRightDragUpdate,
                              onVerticalDragEnd: _onRightDragEnd,
                              onVerticalDragCancel: _onRightDragCancel,
                              onHorizontalDragDown: _onRightHorizontalDragDown,
                              onHorizontalDragStart:
                                  _onRightHorizontalDragStart,
                              onHorizontalDragUpdate:
                                  _onRightHorizontalDragUpdate,
                              onHorizontalDragEnd: _onRightHorizontalDragEnd,
                              onHorizontalDragCancel:
                                  _onRightHorizontalDragCancel,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // ── 3. Main Controls Overlay ──
            if (isLocked) ...[
              FadeTransition(
                opacity: _fadeAnimation,
                child: IgnorePointer(
                  ignoring: !_isVisible,
                  child: LockedControlsOverlay(wp: wp),
                ),
              ),
              // Persistent buffering indicator when locked
              ListenableBuilder(
                listenable: Listenable.merge([
                  wp,
                  wp.isBufferingNotifier,
                  wp.isInitializedNotifier,
                ]),
                builder: (context, _) {
                  final isStreaming =
                      wp.state == WatchState.loadingStream ||
                      wp.state == WatchState.loading;
                  final isBuffering = wp.isBufferingNotifier.value;
                  final isInit =
                      wp.isInitializedNotifier.value && wp.isVideoInitialized;
                  final isLoading = isStreaming || isBuffering || !isInit;
                  if (!isLoading) return const SizedBox.shrink();

                  return Align(
                    alignment: Alignment.center,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 86,
                        height: 86,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.accent,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              // Center Transport Controls pinned to true physical screen center (no cutout skew)
              Align(
                alignment: Alignment.center,
                child: CenterTransportBar(
                  wp: wp,
                  accent: widget.accent,
                  onInteract: _scheduleHide,
                  controlsAnimation: _fadeAnimation,
                ),
              ),

              // Top and Bottom Bars (fade with controls, respect display cutout)
              FadeTransition(
                opacity: _fadeAnimation,
                child: IgnorePointer(
                  ignoring: !_isVisible,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    left: true,
                    right: true,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Top Bar pinned to top
                        Align(
                          alignment: Alignment.topCenter,
                          child: ControlsTopBar(
                            wp: wp,
                            accent: widget.accent,
                            anime: widget.anime,
                            onInteract: _scheduleHide,
                            onBack: widget.onBack,
                          ),
                        ),

                        // Seekbar & Duration pinned to bottom
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: TimelineSeekbar(
                            wp: wp,
                            accent: widget.accent,
                            fmt: formatDuration,
                            onInteract: _scheduleHide,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // ── 4. Floating Skip Intro / Outro Pills ──
            ValueListenableBuilder<bool>(
              valueListenable: wp.showSkipIntroNotifier,
              builder: (context, showIntro, _) {
                if (!showIntro) return const SizedBox.shrink();
                return Positioned(
                  bottom: 74,
                  right: 16,
                  child: SkipButton(
                    label: 'Skip Intro',
                    accent: widget.accent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      wp.skipIntro();
                    },
                  ),
                );
              },
            ),

            ValueListenableBuilder<bool>(
              valueListenable: wp.showSkipOutroNotifier,
              builder: (context, showOutro, _) {
                if (!showOutro) return const SizedBox.shrink();
                return Positioned(
                  bottom: 74,
                  right: 16,
                  child: SkipButton(
                    label: 'Skip Outro',
                    accent: widget.accent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      wp.skipOutro();
                    },
                  ),
                );
              },
            ),

            // ── 5. Auto-Next Episode Countdown Card ──
            ValueListenableBuilder<int?>(
              valueListenable: wp.autoNextCountdownNotifier,
              builder: (context, countdown, _) {
                if (countdown == null) return const SizedBox.shrink();
                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.accent, width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next Episode in ${countdown}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                wp.cancelAutoNext();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                wp.playNextEpisode();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Play Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── 6. Visual HUD Indicators (Always on top, pass touches) ──
            IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Double Tap Seek Visual Indicators (VLC-style 1/3 rounded arc with smooth fade)
                  FadeTransition(
                    opacity: _leftSeekFade,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SeekArcIndicator(
                        isLeft: true,
                        accumulatedSeconds: _accumulatedLeftSeek,
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _rightSeekFade,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SeekArcIndicator(
                        isLeft: false,
                        accumulatedSeconds: _accumulatedRightSeek,
                      ),
                    ),
                  ),

                  // Aspect Ratio Change Pill HUD Indicator
                  ValueListenableBuilder<String?>(
                    valueListenable: wp.aspectRatioNoticeNotifier,
                    builder: (context, notice, _) {
                      if (notice == null) return const SizedBox.shrink();
                      return Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: widget.accent,
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  wp.currentAspectRatioIcon,
                                  color: widget.accent,
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  notice,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // General HUD Notice Indicator (e.g. "Intro Skipped", "Outro Skipped", "Quality: 1080p")
                  ValueListenableBuilder<({String text, IconData icon})?>(
                    valueListenable: wp.hudNoticeNotifier,
                    builder: (context, notice, _) {
                      if (notice == null) return const SizedBox.shrink();
                      return Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: widget.accent,
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  notice.icon,
                                  color: widget.accent,
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  notice.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 2× Speed Boost Pill Indicator
                  ValueListenableBuilder<bool>(
                    valueListenable: wp.isSpeedBoostedNotifier,
                    builder: (context, isBoosted, _) {
                      if (!isBoosted) return const SizedBox.shrink();
                      return Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.accent,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fast_forward_rounded,
                                  color: widget.accent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '2× Speed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // VLC-style Left Brightness Vertical Indicator
                  if (_showBrightnessIndicator)
                    Positioned(
                      left: 48,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: ValueListenableBuilder<double>(
                          valueListenable: wp.brightnessNotifier,
                          builder: (context, br, _) {
                            final icon = br <= 0.33
                                ? Icons.brightness_low_rounded
                                : (br <= 0.66
                                      ? Icons.brightness_medium_rounded
                                      : Icons.brightness_high_rounded);
                            return VlcVerticalIndicator(
                              icon: icon,
                              value: br,
                              label: '${(br * 100).round()}%',
                              accent: widget.accent,
                            );
                          },
                        ),
                      ),
                    ),

                  // VLC-style Right Volume Vertical Indicator
                  if (_showVolumeIndicator)
                    Positioned(
                      right: 48,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: ValueListenableBuilder<double>(
                          valueListenable: wp.volumeNotifier,
                          builder: (context, vol, _) {
                            final icon = vol == 0
                                ? Icons.volume_off_rounded
                                : (vol <= 0.5
                                      ? Icons.volume_down_rounded
                                      : Icons.volume_up_rounded);
                            return VlcVerticalIndicator(
                              icon: icon,
                              value: vol,
                              label: '${(vol * 100).round()}%',
                              accent: widget.accent,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
