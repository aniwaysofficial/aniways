import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/database/repositories/collection_repository.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/models/collection_status.dart';

/// Opens a bottom sheet to set the anime's watch status and favorite state.
Future<void> showCollectionStatusSheet(
  BuildContext context,
  AnimeMedia anime,
) async {
  await showOneUiBottomSheet<void>(
    context: context,
    builder: (ctx) => _CollectionStatusContent(anime: anime),
  );
}

class _CollectionStatusContent extends StatefulWidget {
  const _CollectionStatusContent({required this.anime});

  final AnimeMedia anime;

  @override
  State<_CollectionStatusContent> createState() =>
      _CollectionStatusContentState();
}

class _CollectionStatusContentState extends State<_CollectionStatusContent> {
  final CollectionRepository _repo = CollectionRepository.instance;
  String? _currentStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final status = await _repo.getAnimeStatus(widget.anime.id);
    if (!mounted) return;
    setState(() {
      _currentStatus = status;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final anime = widget.anime;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag Handle ─────────────────────────────────────────
              const OneUiDragHandle(margin: EdgeInsets.only(bottom: 14)),

              // ── Header: Cover + Title + Details ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 48,
                      height: 68,
                      child: AnimeImage(anime.coverUrl, tint: anime.coverColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (anime.format != null) ...[
                              Text(
                                anime.format!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (anime.episodes != null)
                                Text(
                                  ' • ${anime.episodes} Ep',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                            ],
                            if (anime.scoreLabel != null) ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                anime.scoreLabel!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    style: IconButton.styleFrom(
                      foregroundColor: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                )
              else ...[
                // ── Watch Status Header ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.video_library_rounded,
                        size: 15,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'WATCH STATUS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Watch Status Partitioned Card ─────────────────────
                Material(
                  color: cs.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(
                        alpha: isDark ? 0.20 : 0.32,
                      ),
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < CollectionStatus.watchStatuses.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 0.8,
                            indent: 64,
                            endIndent: 16,
                            color: cs.outlineVariant.withValues(
                              alpha: isDark ? 0.12 : 0.22,
                            ),
                          ),
                        _StatusPartitionTile(
                          opt: CollectionStatus.watchStatuses[i],
                          isSelected: _currentStatus == CollectionStatus.watchStatuses[i].id,
                          isDark: isDark,
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final isSelected =
                                _currentStatus == CollectionStatus.watchStatuses[i].id;
                            final newStatus = isSelected
                                ? null
                                : CollectionStatus.watchStatuses[i].id;
                            setState(() => _currentStatus = newStatus);
                            await _repo.setAnimeStatus(anime, newStatus);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        ),
                      ],
                      if (_currentStatus != null) ...[
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          indent: 64,
                          endIndent: 16,
                          color: cs.outlineVariant.withValues(
                            alpha: isDark ? 0.12 : 0.22,
                          ),
                        ),
                        _RemoveStatusPartitionTile(
                          isDark: isDark,
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            setState(() => _currentStatus = null);
                            await _repo.setAnimeStatus(anime, null);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPartitionTile extends StatelessWidget {
  const _StatusPartitionTile({
    required this.opt,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final CollectionStatus opt;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = opt.color;

    return Material(
      color: isSelected
          ? statusColor.withValues(alpha: isDark ? 0.16 : 0.10)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? statusColor.withValues(alpha: isDark ? 0.26 : 0.18)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? statusColor.withValues(alpha: isDark ? 0.55 : 0.40)
                        : cs.outlineVariant.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  opt.icon,
                  size: 20,
                  color: isSelected ? statusColor : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opt.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : statusColor)
                            : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.25 : 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveStatusPartitionTile extends StatelessWidget {
  const _RemoveStatusPartitionTile({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(
                    alpha: isDark ? 0.16 : 0.10,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 20,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Remove from watch status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Clear current watch status for this anime',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
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
