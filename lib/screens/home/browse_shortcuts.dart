import 'package:flutter/material.dart';

import 'package:aniways/core/responsive.dart';

/// Two compact shortcut tiles for the home screen: Genres and Schedule.
///
/// Same visual language as [SectionHeader] and the nav bar: surface card with
/// a hairline border, a tinted rounded-square icon, bold title and a chevron
/// in the accent colour. Taps are optional for now (the tile still ripples).
class BrowseShortcuts extends StatelessWidget {
  const BrowseShortcuts({super.key, this.onGenres, this.onSchedule});

  final VoidCallback? onGenres;
  final VoidCallback? onSchedule;

  static const _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inset = pageInset(context, maxWidth: _maxWidth);
    final today = _shortDays[DateTime.now().weekday - 1];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Row(
            children: [
              Expanded(
                child: _ShortcutTile(
                  color: cs.tertiary,
                  icon: Icons.category_rounded,
                  title: 'Genres',
                  subtitle: 'Browse',
                  onTap: onGenres,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutTile(
                  color: cs.secondary,
                  icon: Icons.calendar_month_rounded,
                  title: 'Schedule',
                  subtitle: 'Airing $today',
                  onTap: onSchedule,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              // Same tinted square as SectionHeader.
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}
