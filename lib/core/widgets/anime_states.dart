import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/providers/anime_lists.dart';

// ═════════════════════════════════════════════════════════════════════════
// Skeletons
// ═════════════════════════════════════════════════════════════════════════

/// Shared global pulse ticker so dozens of skeletons in lists/grids share
/// a single lightweight vsync heartbeat instead of spinning up 20+ separate controllers.
class _SkeletonPulse extends ChangeNotifier {
  static final _SkeletonPulse instance = _SkeletonPulse._();
  _SkeletonPulse._();

  Ticker? _ticker;
  int _refCount = 0;
  double _value = 0.0;
  double get value => _value;

  void acquire() {
    _refCount++;
    if (_refCount == 1) {
      _ticker = Ticker(_onTick)..start();
    }
  }

  void release() {
    _refCount--;
    if (_refCount <= 0) {
      _ticker?.stop();
      _ticker?.dispose();
      _ticker = null;
      _refCount = 0;
    }
  }

  void _onTick(Duration elapsed) {
    const period = 1200000; // 1.2s
    final phase = (elapsed.inMicroseconds % period) / period;
    final raw = phase < 0.5 ? phase * 2.0 : (1.0 - phase) * 2.0;
    _value = Curves.easeInOut.transform(raw);
    notifyListeners();
  }
}

/// Pulsing placeholder block. Works on any background (it's a translucent
/// overlay of the text colour).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height, this.radius = 12});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  @override
  void initState() {
    super.initState();
    _SkeletonPulse.instance.acquire();
  }

  @override
  void dispose() {
    _SkeletonPulse.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final color1 = onSurface.withValues(alpha: 0.06);
    final color2 = onSurface.withValues(alpha: 0.12);

    return RepaintBoundary(
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: CustomPaint(
          painter: _SkeletonPainter(
            pulse: _SkeletonPulse.instance,
            color1: color1,
            color2: color2,
            radius: widget.radius,
          ),
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({
    required this.pulse,
    required this.color1,
    required this.color2,
    required this.radius,
  }) : super(repaint: pulse);

  final _SkeletonPulse pulse;
  final Color color1;
  final Color color2;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final t = pulse.value;
    final color = Color.lerp(color1, color2, t) ?? color1;
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) =>
      color1 != oldDelegate.color1 ||
      color2 != oldDelegate.color2 ||
      radius != oldDelegate.radius;
}

/// Placeholder for [AnimeCard].
class AnimeCardSkeleton extends StatelessWidget {
  const AnimeCardSkeleton({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: kPosterAspect,
            child: Skeleton(radius: kPosterRadius),
          ),
          SizedBox(height: 10),
          Skeleton(height: 12, radius: 6),
          SizedBox(height: 6),
          Skeleton(width: 70, height: 10, radius: 6),
        ],
      ),
    );
  }
}

/// Placeholder for [AnimeListTile].
class AnimeTileSkeleton extends StatelessWidget {
  const AnimeTileSkeleton({super.key, this.isFirst = false, this.isLast = false});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: groupedTileRadius(isFirst: isFirst, isLast: isLast),
      ),
      child: Row(
        children: [
          const Skeleton(width: 68, height: 68 / kPosterAspect, radius: 14),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 14, radius: 6),
                SizedBox(height: 10),
                Skeleton(width: 120, height: 11, radius: 6),
                SizedBox(height: 8),
                Skeleton(width: 80, height: 11, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Error + pagination footer
// ═════════════════════════════════════════════════════════════════════════

/// Inline "couldn't load" card with a Retry button.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// What sits under an infinite list: spinner while more is coming, a retry
/// card after a failure, and a quiet "end" note once everything is loaded.
class PagedFooter extends StatelessWidget {
  const PagedFooter({super.key, required this.paged, this.showLoading = true});

  final PagedAnime paged;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    if (paged.items.isEmpty) return const SizedBox.shrink();

    if (paged.hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ErrorCard(
          message: describeError(paged.error),
          onRetry: paged.retry,
        ),
      );
    }

    if (paged.hasMore) {
      if (!showLoading) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Skeleton(width: 80, height: 8, radius: 4),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          "You've reached the end",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
