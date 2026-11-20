import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aniways/core/helpers.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/scroll/app_scroll.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/providers/anime_lists.dart';
import 'package:aniways/core/theme/genre_colors.dart';

const Color _starColor = Color(0xFFFFB300);
const double _posterWidth = 72;
const double _listMaxWidth = 760;

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// Weekly airing schedule: a day tab per weekday, entries grouped by the
/// time they air.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final ScrollController _outerController;
  int _lastTabIndex = -1;
  Timer? _ticker;

  late DateTime _weekStart;
  List<List<AiringSchedule>> _byDay = _emptyWeek();
  bool _loading = true;
  Object? _error;

  /// Ignores answers of requests that were superseded (fast week switching).
  int _token = 0;

  static List<List<AiringSchedule>> _emptyWeek() =>
      List.generate(7, (_) => const <AiringSchedule>[]);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = AnilistService.weekRange(now).$1;
    _lastTabIndex = now.weekday - 1;
    _outerController = ScrollController();
    _tabs = TabController(length: 7, vsync: this, initialIndex: _lastTabIndex);
    _tabs.addListener(_onTabChanged);
    // Keeps "in 7m" / "Aired" fresh without refetching.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabs.index != _lastTabIndex) {
      _lastTabIndex = _tabs.index;
      setState(() {});
      // Smoothly scroll up to reveal the top of the new day's schedule
      // if the header was collapsed from a previous tab.
      if (_outerController.hasClients && _outerController.offset > 0) {
        _outerController.animateTo(
          0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _outerController.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────

  Future<void> _load({bool refresh = false}) async {
    final token = ++_token;
    if (!refresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final all = await anilistService.weeklyAiringSchedules(
        weekOf: _weekStart,
        forceRefresh: refresh,
      );
      if (!mounted || token != _token) return;

      final days = List.generate(7, (_) => <AiringSchedule>[]);
      for (final item in all) {
        final index = _dayIndex(item.airingAt);
        if (index >= 0 && index < 7) days[index].add(item);
      }
      for (final day in days) {
        day.sort((a, b) => a.airingAt.compareTo(b.airingAt));
      }
      setState(() {
        _byDay = days;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      log.e('Schedule load failed', error: e, stackTrace: st);
      if (!mounted || token != _token) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// Calendar-day offset from Monday (DST safe).
  int _dayIndex(DateTime t) {
    final a = DateTime.utc(t.year, t.month, t.day);
    final b = DateTime.utc(_weekStart.year, _weekStart.month, _weekStart.day);
    return a.difference(b).inDays;
  }

  DateTime _dateOf(int index) =>
      DateTime(_weekStart.year, _weekStart.month, _weekStart.day + index);

  int? get _todayIndex {
    final i = _dayIndex(DateTime.now());
    return i >= 0 && i < 7 ? i : null;
  }

  void _shiftWeek(int weeks) {
    setState(() {
      _weekStart = DateTime(
        _weekStart.year,
        _weekStart.month,
        _weekStart.day + 7 * weeks,
      );
      _byDay = _emptyWeek();
    });
    _load();
  }

  void _goToday() {
    final now = DateTime.now();
    final thisWeek = AnilistService.weekRange(now).$1;
    if (thisWeek != _weekStart) {
      setState(() {
        _weekStart = thisWeek;
        _byDay = _emptyWeek();
      });
      _load();
    }
    _tabs.animateTo(now.weekday - 1);
  }

  String get _weekLabel {
    final s = _weekStart;
    final e = _dateOf(6);
    if (s.month == e.month) {
      return '${kShortMonths[s.month - 1]} ${s.day} – ${e.day}';
    }
    return '${kShortMonths[s.month - 1]} ${s.day} – ${kShortMonths[e.month - 1]} ${e.day}';
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inset = pageInset(context, gutter: 16, maxWidth: _listMaxWidth);
    final today = _todayIndex;
    final isCompact = context.layoutSize.isCompact;

    final tabBar = TabBar(
      controller: _tabs,
      isScrollable: true,
      tabAlignment: isCompact ? TabAlignment.start : TabAlignment.center,
      labelColor: cs.primary,
      unselectedLabelColor: cs.onSurfaceVariant,
      indicatorColor: cs.primary,
      indicatorWeight: 2.5,
      dividerColor: cs.outlineVariant.withValues(alpha: 0.5),
      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      tabs: [
        for (var i = 0; i < 7; i++)
          Tab(text: i == today ? 'TODAY' : '${_weekdays[i]} ${_dateOf(i).day}'),
      ],
    );

    final todayButton = AnimatedBuilder(
      animation: _tabs,
      builder: (context, _) {
        final atToday = today != null && _tabs.index == today;
        return TextButton(
          onPressed: atToday ? null : _goToday,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text(
            'Today',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );

    final prevButton = IconButton(
      onPressed: () => _shiftWeek(-1),
      icon: const Icon(Icons.chevron_left_rounded, size: 22),
      visualDensity: VisualDensity.compact,
    );

    final nextButton = IconButton(
      onPressed: () => _shiftWeek(1),
      icon: const Icon(Icons.chevron_right_rounded, size: 22),
      visualDensity: VisualDensity.compact,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        notificationPredicate: (n) {
          if (n.metrics.axis != Axis.vertical) return false;
          // Never trigger pull-to-refresh while the outer header is collapsed.
          // Pulling down while collapsed scrolls the list up / expands the header.
          if (_outerController.hasClients && _outerController.offset > 0) {
            return false;
          }
          // Only trigger when the inner list is also at the very top.
          return n.metrics.extentBefore == 0;
        },
        child: NestedScrollView(
          controller: _outerController,
          physics: const AppScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          headerSliverBuilder: (context, _) => [
            const OneUiSliverHeader(title: 'Schedule'),

            // Week navigator
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? inset + 4 : inset,
                  2,
                  isCompact ? (inset - 8 < 0 ? 0 : inset - 8) : inset,
                  2,
                ),
                child: isCompact
                    ? Row(
                        children: [
                          Text(
                            _weekLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          todayButton,
                          prevButton,
                          nextButton,
                        ],
                      )
                    : SizedBox(
                        height: 40,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              prevButton,
                              const SizedBox(width: 4),
                              Text(
                                _weekLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              nextButton,
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            // Day tabs (stay pinned under the toolbar)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeader(
                tabBar: tabBar,
                background: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            physics: const PageScrollPhysics(parent: AppScrollPhysics()),
            children: [for (var i = 0; i < 7; i++) _dayPage(i, inset)],
          ),
        ),
      ),
    );
  }

  Widget _dayPage(int day, double inset) {
    final isCompact = context.layoutSize.isCompact;
    final columns = isCompact ? 1 : 2;
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final padding = EdgeInsets.fromLTRB(inset, 20, inset, bottom);
    const physics = AppScrollPhysics(parent: AlwaysScrollableScrollPhysics());

    if (_loading) {
      return ListView(
        key: PageStorageKey('sched_${day}_loading'),
        physics: physics,
        padding: padding,
        children: [
          for (var i = 0; i < 3; i++) ...[
            const Skeleton(width: 64, height: 16, radius: 6),
            const SizedBox(height: 12),
            if (columns == 1)
              const _ScheduleCardSkeleton()
            else
              const Row(
                children: [
                  Expanded(child: _ScheduleCardSkeleton()),
                  SizedBox(width: 12),
                  Expanded(child: _ScheduleCardSkeleton()),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ],
      );
    }

    if (_error != null) {
      return ListView(
        key: PageStorageKey('sched_${day}_error'),
        physics: physics,
        padding: padding,
        children: [
          ErrorCard(message: describeError(_error), onRetry: () => _load()),
        ],
      );
    }

    final items = _byDay[day];
    if (items.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return ListView(
        key: PageStorageKey('sched_${day}_empty'),
        physics: physics,
        padding: padding,
        children: [
          SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 44,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nothing scheduled',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Group entries that air at the same minute under one header.
    final groups = <List<AiringSchedule>>[];
    for (final item in items) {
      if (groups.isNotEmpty &&
          _sameMinute(groups.last.first.airingAt, item.airingAt)) {
        groups.last.add(item);
      } else {
        groups.add([item]);
      }
    }

    // "Up next" only applies to today's first group that hasn't aired.
    final nextGroup = day == _todayIndex
        ? groups.indexWhere((g) => !g.first.hasAired)
        : -1;

    return ListView(
      key: PageStorageKey('sched_${day}_${_weekStart.millisecondsSinceEpoch}'),
      physics: physics,
      padding: padding,
      children: [
        for (var g = 0; g < groups.length; g++) ...[
          _TimeHeader(schedule: groups[g].first, isNext: g == nextGroup),
          const SizedBox(height: 12),
          for (var i = 0; i < groups[g].length; i += columns) ...[
            if (columns == 1)
              _ScheduleCard(
                key: ValueKey(groups[g][i].id),
                schedule: groups[g][i],
                isNext: g == nextGroup,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ScheduleCard(
                      key: ValueKey(groups[g][i].id),
                      schedule: groups[g][i],
                      isNext: g == nextGroup,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < groups[g].length
                        ? _ScheduleCard(
                            key: ValueKey(groups[g][i + 1].id),
                            schedule: groups[g][i + 1],
                            isNext: g == nextGroup,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  static bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}

/// Pins the day [TabBar] under the One UI header.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader({required this.tabBar, required this.background});

  final TabBar tabBar;
  final Color background;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: background, child: tabBar);

  // Labels change when the week changes.
  @override
  bool shouldRebuild(covariant _TabsHeader oldDelegate) => true;
}

// ═════════════════════════════════════════════════════════════════════════
// Time header
// ═════════════════════════════════════════════════════════════════════════

class _TimeHeader extends StatelessWidget {
  const _TimeHeader({required this.schedule, required this.isNext});

  final AiringSchedule schedule;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Widget status;
    if (schedule.hasAired) {
      status = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            'Aired',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      );
    } else if (isNext) {
      status = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Up next · ${schedule.relativeLabel}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      );
    } else {
      status = Text(
        schedule.relativeLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      );
    }

    return Row(
      children: [
        Text(
          schedule.timeLabel,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isNext ? cs.primary : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 12),
        status,
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Card
// ═════════════════════════════════════════════════════════════════════════

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    super.key,
    required this.schedule,
    required this.isNext,
  });

  final AiringSchedule schedule;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final media = schedule.media;
    final score = media.scoreLabel;
    final format = media.formatLabel;
    final eps = media.episodes;
    final epsLabel = eps == null ? null : '$eps ${eps == 1 ? 'ep' : 'eps'}';
    final info = [?format, ?epsLabel].join(' · ');

    final tint = media.coverColor == null
        ? cs.primary
        : Color(media.coverColor!);
    final base = cs.surfaceContainerHigh;
    const radius = BorderRadius.all(Radius.circular(22));

    final heroTag = 'schedule-${schedule.id}';

    final card = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(tint.withValues(alpha: 0.24), base),
              base,
            ],
          ),
          border: Border.all(
            color: isNext ? cs.primary : tint.withValues(alpha: 0.35),
            width: isNext ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => openAnime(context, media, heroTag: heroTag),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _Poster(
                  media: media,
                  episode: schedule.episode,
                  heroTag: heroTag,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (score != null || info.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (score != null) ...[
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: _starColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                score,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _starColor,
                                ),
                              ),
                            ],
                            if (score != null && info.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Text(
                                  '·',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            if (info.isNotEmpty)
                              Flexible(
                                child: Text(
                                  info,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (media.genres.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final g in media.genres.take(3)) _GenreChip(g),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Dim what already aired so the upcoming ones stand out.
    return schedule.hasAired ? Opacity(opacity: 0.72, child: card) : card;
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.media,
    required this.episode,
    this.heroTag,
  });

  final AnimeMedia media;
  final int episode;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _posterWidth,
      child: AspectRatio(
        aspectRatio: kPosterAspect,
        child: Hero(
          tag: heroTag ?? 'schedule-${media.id}-$episode',
          transitionOnUserGestures: true,
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimeImage(
                    media.coverUrl,
                    tint: media.coverColor,
                    cacheWidth: 260,
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'EP $episode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
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

class _GenreChip extends StatelessWidget {
  const _GenreChip(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final color = genreColor(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: lightenColor(color),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Loading skeleton
// ═════════════════════════════════════════════════════════════════════════

class _ScheduleCardSkeleton extends StatelessWidget {
  const _ScheduleCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: _posterWidth,
            child: AspectRatio(
              aspectRatio: kPosterAspect,
              child: Skeleton(radius: 14),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Skeleton(width: 160, height: 15, radius: 6),
                SizedBox(height: 8),
                Skeleton(width: 90, height: 13, radius: 6),
                SizedBox(height: 10),
                Skeleton(width: 140, height: 18, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
