import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aniways/core/helpers.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/models/anime_media.dart';

/// Formats the airing date for next episode banner.
String formatNextAiringDate(NextAiring n) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final dt = DateTime.fromMillisecondsSinceEpoch(n.airingAt * 1000);
  final now = DateTime.now();
  final diff = DateTime(
    dt.year,
    dt.month,
    dt.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;

  final h12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';

  final day = diff == 0
      ? 'Today'
      : diff == 1
      ? 'Tomorrow'
      : '${days[dt.weekday - 1]}, ${kShortMonths[dt.month - 1]} ${dt.day}';

  return '$day · $h12:$m $period';
}

/// Next episode countdown card showing episode number, date/time, and live countdown units.
class DetailsNextEpisodeCard extends StatefulWidget {
  const DetailsNextEpisodeCard({super.key, required this.next});

  final NextAiring next;

  @override
  State<DetailsNextEpisodeCard> createState() => _DetailsNextEpisodeCardState();
}

class _DetailsNextEpisodeCardState extends State<DetailsNextEpisodeCard> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateRemaining();
        });
      }
    });
  }

  void _updateRemaining() {
    final airDate = DateTime.fromMillisecondsSinceEpoch(
      widget.next.airingAt * 1000,
    );
    _remaining = airDate.difference(DateTime.now());
  }

  @override
  void didUpdateWidget(DetailsNextEpisodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.next.airingAt != widget.next.airingAt) {
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final airingNow = _remaining.isNegative || _remaining.inSeconds <= 0;

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final units = <(int, String)>[];
    if (!airingNow) {
      if (days > 0) {
        units
          ..add((days, 'DAYS'))
          ..add((hours, 'HRS'))
          ..add((minutes, 'MIN'));
      } else if (hours > 0) {
        units
          ..add((hours, 'HRS'))
          ..add((minutes, 'MIN'))
          ..add((seconds, 'SEC'));
      } else {
        units
          ..add((minutes, 'MIN'))
          ..add((seconds, 'SEC'));
      }
    }

    return Row(
      children: [
        // Episode number badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'EP',
                style: TextStyle(
                  color: cs.onPrimary.withValues(alpha: 0.75),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.next.episode}',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Episode title & date/time details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next Episode',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formatNextAiringDate(widget.next),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Countdown pills or Airing badge
        if (airingNow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fiber_manual_record_rounded,
                  size: 8,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 4),
                Text(
                  'AIRING',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < units.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        ':',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  DetailsCountdownUnit(value: units[i].$1, label: units[i].$2),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class DetailsCountdownUnit extends StatelessWidget {
  const DetailsCountdownUnit({
    super.key,
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = context.layoutSize.isCompact;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
