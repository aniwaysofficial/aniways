import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/database/repositories/collection_repository.dart';
import 'package:aniways/core/theme/cover_palette.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/theme/genre_colors.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/models/collection_status.dart';
import 'package:aniways/screens/details/anime_details_screen.dart';

/// Opens an iOS / One UI style contextual floating preview for [anime] with an
/// elevated poster, ambient blur, and a compact quick-action dock.
/// Participates in Flutter [Hero] transitions via a transparent [PageRouteBuilder].
Future<void> showContextualAnimePreview(
  BuildContext context,
  AnimeMedia anime, {
  String? heroTag,
}) async {
  HapticFeedback.mediumImpact();
  final effectiveTag = heroTag ?? 'anime-poster-${anime.id}';

  await Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'Dismiss preview',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _ContextualAnimePreviewDialog(
          anime: anime,
          heroTag: effectiveTag,
          animation: animation,
        );
      },
      transitionsBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final blur = (16.0 * curved.value).clamp(0.01, 16.0);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: child,
        );
      },
    ),
  );
}

class _ContextualAnimePreviewDialog extends StatefulWidget {
  const _ContextualAnimePreviewDialog({
    required this.anime,
    required this.heroTag,
    required this.animation,
  });

  final AnimeMedia anime;
  final String heroTag;
  final Animation<double> animation;

  @override
  State<_ContextualAnimePreviewDialog> createState() =>
      _ContextualAnimePreviewDialogState();
}

class _ContextualAnimePreviewDialogState
    extends State<_ContextualAnimePreviewDialog> {
  final CollectionRepository _repo = CollectionRepository.instance;
  bool _isFavorite = false;
  String? _currentStatus;
  bool _showMoreMenu = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final fav = await _repo.isFavorite(widget.anime.id);
    final status = await _repo.getAnimeStatus(widget.anime.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = fav;
      _currentStatus = status;
    });
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    setState(() => _isFavorite = !_isFavorite);
    await _repo.toggleFavorite(widget.anime);
  }

  Future<void> _setStatus(String? statusId) async {
    HapticFeedback.lightImpact();
    final newStatus = _currentStatus == statusId ? null : statusId;
    setState(() => _currentStatus = newStatus);
    await _repo.setAnimeStatus(widget.anime, newStatus);
  }

  void _openDetails() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AnimeDetailsScreen(
            anime: widget.anime,
            heroTag: widget.heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _shareAnime() {
    Clipboard.setData(
      ClipboardData(text: 'https://anilist.co/anime/${widget.anime.id}'),
    );
    AniwaysSnackBar.show(
      context,
      message: 'Link for "${widget.anime.title}" copied!',
      icon: Icons.copy_rounded,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final anime = widget.anime;
    final fallbackColor = anime.coverColor == null
        ? (anime.genres.isNotEmpty
            ? genreColor(anime.genres.first)
            : cs.primary)
        : Color(anime.coverColor!);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Floating Poster Card (Hero Transitioned) ───────
                  GestureDetector(
                    onTap: _openDetails,
                    child: CoverPaletteBuilder(
                      url: anime.coverUrl,
                      fallback: fallbackColor,
                      builder: (context, accent, palette) {
                        final glow = HSLColor.fromColor(accent)
                            .withLightness(
                              HSLColor.fromColor(accent)
                                  .lightness
                                  .clamp(0.4, 0.65),
                            )
                            .toColor();

                        return AnimatedBuilder(
                          animation: widget.animation,
                          builder: (context, _) {
                            final glowProgress = widget.animation.value;
                            return Container(
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: glow.withValues(
                                      alpha:
                                          (0.45 * glowProgress).clamp(0.0, 1.0),
                                    ),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha:
                                          (0.40 * glowProgress).clamp(0.0, 1.0),
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: AspectRatio(
                                aspectRatio: kPosterAspect,
                                child: Hero(
                                  tag: widget.heroTag,
                                  transitionOnUserGestures: true,
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          AnimeImage(
                                            anime.coverUrl,
                                            tint: anime.coverColor,
                                          ),
                                          // Top-left Favorite Heart Badge
                                          StreamBuilder<bool>(
                                            stream: _repo
                                                .watchIsFavorite(anime.id),
                                            initialData: _isFavorite,
                                            builder: (context, snapshot) {
                                              final isFav =
                                                  snapshot.data ?? _isFavorite;
                                              if (!isFav) {
                                                return const SizedBox.shrink();
                                              }
                                              return Positioned(
                                                top: 8,
                                                left: 8,
                                                child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(
                                                      alpha: 0.65,
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                        alpha: 0.25,
                                                      ),
                                                      width: 0.8,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 1.5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.favorite_rounded,
                                                      size: 16,
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          // Score Badge
                                          if (anime.scoreLabel != null)
                                            Positioned(
                                              left: 8,
                                              bottom: 8,
                                              child: ScoreBadge(
                                                anime.scoreLabel!,
                                                tint: accent,
                                              ),
                                            ),
                                          // Status Badge
                                          if (anime.statusLabel != null &&
                                              !anime.isCompleted)
                                            Positioned(
                                              right: 8,
                                              bottom: 8,
                                              child: StatusBadge(
                                                status: anime.status,
                                                label: anime.statusLabel!,
                                                tint: accent,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Title, Metadata & Action Dock ─────────────────
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: widget.animation,
                      curve: const Interval(0.20, 1.0, curve: Curves.easeOut),
                      reverseCurve:
                          const Interval(0.0, 0.50, curve: Curves.easeIn),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: widget.animation,
                          curve: const Interval(0.20, 1.0,
                              curve: Curves.easeOutCubic),
                          reverseCurve: const Interval(0.0, 0.50,
                              curve: Curves.easeInCubic),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 14),
                          // Title & Format Pill
                          Text(
                            anime.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (anime.format != null)
                                Text(
                                  anime.format!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (anime.episodes != null)
                                Text(
                                  ' • ${anime.episodes} Ep',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              if (anime.scoreLabel != null) ...[
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  anime.scoreLabel!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Action Pill Dock ───────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                cs.primary.withValues(alpha: 0.14),
                                const Color(0xFF1E1E24).withValues(alpha: 0.88),
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                                width: 0.9,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Favorite
                                _DockAction(
                                  icon: _isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  label: 'Favorite',
                                  isActive: _isFavorite,
                                  activeColor: CollectionStatus.favorites.color,
                                  onTap: _toggleFavorite,
                                ),
                                // Watching
                                _DockAction(
                                  icon: CollectionStatus.watching.icon,
                                  label: 'Watching',
                                  isActive:
                                      _currentStatus == CollectionStatus.watching.id,
                                  activeColor: CollectionStatus.watching.color,
                                  onTap: () =>
                                      _setStatus(CollectionStatus.watching.id),
                                ),
                                // Plan to Watch
                                _DockAction(
                                  icon: CollectionStatus.planToWatch.icon,
                                  label: 'Plan',
                                  isActive: _currentStatus ==
                                      CollectionStatus.planToWatch.id,
                                  activeColor: CollectionStatus.planToWatch.color,
                                  onTap: () =>
                                      _setStatus(CollectionStatus.planToWatch.id),
                                ),
                                // Completed
                                _DockAction(
                                  icon: CollectionStatus.completed.icon,
                                  label: 'Done',
                                  isActive:
                                      _currentStatus == CollectionStatus.completed.id,
                                  activeColor: CollectionStatus.completed.color,
                                  onTap: () =>
                                      _setStatus(CollectionStatus.completed.id),
                                ),
                                // More (On hold, dropped, share, details)
                                _DockAction(
                                  icon: _showMoreMenu
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.more_horiz_rounded,
                                  label: 'More',
                                  isActive: _showMoreMenu ||
                                      _currentStatus ==
                                          CollectionStatus.onHold.id ||
                                      _currentStatus ==
                                          CollectionStatus.dropped.id,
                                  activeColor: cs.primary,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(
                                        () => _showMoreMenu = !_showMoreMenu);
                                  },
                                ),
                              ],
                            ),
                          ),

                          // ── Extended Sub-menu (On Hold / Dropped / Details) ──
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E24)
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 0.8,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _MenuRow(
                                    icon: CollectionStatus.onHold.icon,
                                    iconColor: CollectionStatus.onHold.color,
                                    title: CollectionStatus.onHold.title,
                                    isSelected: _currentStatus ==
                                        CollectionStatus.onHold.id,
                                    onTap: () =>
                                        _setStatus(CollectionStatus.onHold.id),
                                  ),
                                  const Divider(height: 1, color: Colors.white12),
                                  _MenuRow(
                                    icon: CollectionStatus.dropped.icon,
                                    iconColor: CollectionStatus.dropped.color,
                                    title: CollectionStatus.dropped.title,
                                    isSelected: _currentStatus ==
                                        CollectionStatus.dropped.id,
                                    onTap: () =>
                                        _setStatus(CollectionStatus.dropped.id),
                                  ),
                                  if (_currentStatus != null) ...[
                                    const Divider(
                                        height: 1, color: Colors.white12),
                                    _MenuRow(
                                      icon: Icons.remove_circle_outline_rounded,
                                      iconColor: Colors.grey,
                                      title: 'Clear status',
                                      isSelected: false,
                                      onTap: () => _setStatus(null),
                                    ),
                                  ],
                                  const Divider(
                                      height: 1, color: Colors.white12),
                                  _MenuRow(
                                    icon: Icons.share_rounded,
                                    iconColor: cs.primary,
                                    title: 'Share link',
                                    isSelected: false,
                                    onTap: _shareAnime,
                                  ),
                                  const Divider(
                                      height: 1, color: Colors.white12),
                                  _MenuRow(
                                    icon: Icons.arrow_outward_rounded,
                                    iconColor: Colors.white,
                                    title: 'View full details',
                                    isSelected: false,
                                    onTap: _openDetails,
                                  ),
                                ],
                              ),
                            ),
                            crossFadeState: _showMoreMenu
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.fastOutSlowIn,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? activeColor.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive ? activeColor : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? activeColor
                    : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? iconColor : Colors.white,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 18, color: iconColor),
          ],
        ),
      ),
    );
  }
}

