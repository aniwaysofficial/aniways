import 'package:flutter/material.dart';
import 'package:aniways/core/services/blurred_cover_service.dart';
import 'package:aniways/core/theme/genre_colors.dart';
import 'package:aniways/models/anime_details.dart';
import 'package:aniways/navigation/main_navigation.dart';

/// Genre card for horizontal browsing rows with cover art scrim, blur, and glass badge.
class DetailsGenreCard extends StatelessWidget {
  const DetailsGenreCard({
    super.key,
    required this.genre,
    this.coverUrl,
  });

  final String genre;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final icon = genreIcon(genre);
    final color = genreColor(genre);

    final baseColor = isDark
        ? const Color(0xFF1C1C20)
        : cs.surfaceContainerHighest;
    final textColor = isDark ? Colors.white : cs.onSurface;
    final chevronColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : cs.onSurface.withValues(alpha: 0.60);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : cs.outlineVariant.withValues(alpha: 0.35);
    final badgeBg = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.75);
    final badgeBorder = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.08);
    final badgeIconColor = isDark ? Colors.white : cs.onSurface;

    final scrimColors = isDark
        ? [
            Colors.black.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.70),
            Colors.black.withValues(alpha: 0.90),
          ]
        : [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.88),
          ];
    const scrimStops = [0.0, 0.40, 0.75, 1.0];

    return RepaintBoundary(
      child: SizedBox(
        width: 148,
        child: Material(
          color: baseColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => MainNavigation.switchToSearch(context, genre: genre),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Pre-Blurred Cover Background (Disk-Cached, 0 GPU Shaders) ──
                Positioned.fill(
                  child: BlurredCardCover(
                    url: coverUrl,
                    fallback: ColoredBox(color: color.withValues(alpha: 0.18)),
                  ),
                ),

                // ── Clean Scrim Vignette ──
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: scrimStops,
                        colors: scrimColors,
                      ),
                    ),
                  ),
                ),

                // ── Content ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Glass Icon Badge + Chevron
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: badgeBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Icon(icon, size: 15, color: badgeIconColor),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: chevronColor,
                          ),
                        ],
                      ),

                      // Bottom: Genre Title
                      Text(
                        genre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapped chips for tags with expandable '+N more' toggle.
class DetailsTagsWrap extends StatefulWidget {
  const DetailsTagsWrap({super.key, required this.tags});

  final List<AnimeTag> tags;

  @override
  State<DetailsTagsWrap> createState() => _DetailsTagsWrapState();
}

class _DetailsTagsWrapState extends State<DetailsTagsWrap> {
  static const _collapsedCount = 8;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tags = widget.tags;
    final hidden = tags.length - _collapsedCount;
    final canToggle = hidden > 0;
    final visible = (_expanded || !canToggle)
        ? tags
        : tags.take(_collapsedCount).toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in visible) DetailsTagChip(tag: tag),
            if (canToggle)
              DetailsTagToggleChip(
                label: _expanded ? 'Show less' : '+$hidden more',
                onTap: () => setState(() => _expanded = !_expanded),
              ),
          ],
        ),
      ),
    );
  }
}

class DetailsTagChip extends StatelessWidget {
  const DetailsTagChip({super.key, required this.tag});

  final AnimeTag tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      shape: StadiumBorder(
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => MainNavigation.switchToSearch(context, query: tag.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${tag.rank}%',
                style: TextStyle(
                  color: cs.primary.withValues(alpha: 0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsTagToggleChip extends StatelessWidget {
  const DetailsTagToggleChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.primary.withValues(alpha: 0.14),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: cs.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
