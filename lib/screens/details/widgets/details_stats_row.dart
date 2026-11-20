import 'package:flutter/material.dart';
import 'package:aniways/core/helpers.dart';

/// Quick statistics strip (Popularity and Favourites).
class DetailsStatsRow extends StatelessWidget {
  const DetailsStatsRow({
    super.key,
    required this.popularity,
    required this.favourites,
  });

  final int? popularity;
  final int? favourites;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Row(
        children: [
          Expanded(
            child: DetailsStatCell(
              icon: Icons.people_alt_rounded,
              color: cs.primary,
              value: popularity == null
                  ? '-'
                  : formatCompactNumber(popularity!),
              label: 'Popularity',
            ),
          ),
          SizedBox(
            height: 38,
            child: VerticalDivider(
              width: 1,
              thickness: 0.8,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          Expanded(
            child: DetailsStatCell(
              icon: Icons.favorite_rounded,
              color: const Color(0xFFFF4081),
              value: favourites == null
                  ? '-'
                  : formatCompactNumber(favourites!),
              label: 'Favourites',
            ),
          ),
        ],
      ),
    );
  }
}

class DetailsStatCell extends StatelessWidget {
  const DetailsStatCell({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
