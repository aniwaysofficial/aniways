import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';

/// VLC/YouTube style directional seek ripple and arc overlay on double-tap.
class SeekArcIndicator extends StatefulWidget {
  const SeekArcIndicator({
    super.key,
    required this.isLeft,
    required this.accumulatedSeconds,
  });

  final bool isLeft;
  final int accumulatedSeconds;

  @override
  State<SeekArcIndicator> createState() => _SeekArcIndicatorState();
}

class _SeekArcIndicatorState extends State<SeekArcIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _slideAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // VLC directional kick: nudges in seek direction and settles
    _slideAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: widget.isLeft ? -14.0 : 14.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.isLeft ? -14.0 : 14.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_pulseCtrl);

    // VLC-style scale pop on tap
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.90,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_pulseCtrl);

    _pulseCtrl.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant SeekArcIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accumulatedSeconds != widget.accumulatedSeconds) {
      _pulseCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final width = (screenW * 0.28).clamp(180.0, 320.0);
    final displaySec = widget.accumulatedSeconds > 0
        ? widget.accumulatedSeconds
        : SharedPreferencesService().doubleTapSeekDuration;

    return ClipPath(
      clipper: SeekArcClipper(isLeft: widget.isLeft),
      child: Container(
        width: width,
        height: double.infinity,
        color: Colors.black.withValues(alpha: 0.52),
        child: Align(
          alignment: const Alignment(0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // VLC Fast-Forward / Fast-Rewind double-arrow icon with directional animation
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset(_slideAnim.value, 0),
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Icon(
                        widget.isLeft
                            ? Icons.fast_rewind_rounded
                            : Icons.fast_forward_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                widget.isLeft ? '-${displaySec}s' : '+${displaySec}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeekArcClipper extends CustomClipper<Path> {
  const SeekArcClipper({required this.isLeft});

  final bool isLeft;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final chordHalf = h / 2;

    // Use circular geometry (constant radius) so the arc is a true circle segment
    final double r = math.max(w, chordHalf * 1.05);
    final topX = (w - r + math.sqrt(r * r - chordHalf * chordHalf)).clamp(
      0.0,
      w,
    );

    if (isLeft) {
      path.moveTo(0, 0);
      path.lineTo(topX, 0);
      path.arcToPoint(
        Offset(topX, h),
        radius: Radius.circular(r),
        clockwise: true,
      );
      path.lineTo(0, h);
      path.close();
    } else {
      final startX = w - topX;
      path.moveTo(w, 0);
      path.lineTo(startX, 0);
      path.arcToPoint(
        Offset(startX, h),
        radius: Radius.circular(r),
        clockwise: false,
      );
      path.lineTo(w, h);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(SeekArcClipper oldClipper) => oldClipper.isLeft != isLeft;
}

/// VLC-style vertical edge slider indicator for volume & brightness gesture feedback.
class VlcVerticalIndicator extends StatelessWidget {
  const VlcVerticalIndicator({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final double value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 160,
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black87)],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: 5.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(3),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4),
                ],
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
            ),
          ),
        ],
      ),
    );
  }
}

