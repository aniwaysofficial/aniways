import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:math' as math;

import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/providers/anime_lists.dart';
import 'package:aniways/providers/home_provider.dart';
import 'package:aniways/core/theme/genre_colors.dart';
import 'package:aniways/core/helpers.dart';

const double _posterWidth = 188; // phone (stacked) layout
const double _heroTopGap = 35; // space between status bar and poster
const double _heroBottomGap = 18; // space under the info block
// The blurred backdrop is kept within the carousel height so the fade-out
// completes smoothly above the browse shortcuts, preventing any seam or overlap.
const double _backdropExtra = 0;
const double _posterInfoGap = 16;
const double _infoHeight = 125; // title (2 lines) + info line + genre pills

// Wide layout (tablet / desktop): poster on the left, text on the right.
const double _wideTopGap = 44;
const double _wideBottomGap = 80;

bool _isWide(BuildContext context) => context.hasSideNav;

bool _showArrows(BuildContext context) => _isWide(context) && isDesktop();

/// Poster width: fixed on phones, grows with the page area on bigger screens.
double _posterWidthFor(BuildContext context) => switch (context.layoutSize) {
  WindowSize.compact => _posterWidth,
  WindowSize.medium => 205,
  WindowSize.expanded => 235,
  WindowSize.large => 265,
};

double _posterHeightFor(BuildContext context) =>
    _posterWidthFor(context) / kPosterAspect;

double _bottomGapFor(BuildContext context) =>
    _isWide(context) ? _wideBottomGap : _heroBottomGap;

/// Total hero height including the area behind the status bar.
double _heroHeight(BuildContext context) {
  final top = MediaQuery.paddingOf(context).top;
  final posterH = _posterHeightFor(context);
  final height = _isWide(context)
      ? top + _wideTopGap + posterH + _wideBottomGap
      : top +
            _heroTopGap +
            posterH +
            _posterInfoGap +
            _infoHeight +
            _heroBottomGap;
  // Whole pixels only: a fractional height leaves a faint seam on the
  // bottom edge.
  return height.ceilToDouble();
}

/// Windowed dots: at most 5 visible, active one is a pill, edge dots shrink
/// when there are more slides beyond them.
class _PagerDots extends StatelessWidget {
  const _PagerDots({required this.current, required this.count});

  final ValueNotifier<int> current;
  final int count;

  static const int _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: current,
        builder: (context, index, _) {
          final visible = count < _maxVisible ? count : _maxVisible;
          final start = (index - visible ~/ 2).clamp(0, count - visible).toInt();

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < visible; i++)
                _dot(
                  active: start + i == index,
                  // Smaller edge dot hints that more slides continue that way.
                  small:
                      (i == 0 && start > 0) ||
                      (i == visible - 1 && start + visible < count),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _dot({required bool active, required bool small}) {
    final size = small ? 4.0 : 6.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 18 : size,
      height: active ? 6 : size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.95 : 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Hero carousel: full-bleed, starts behind the status bar. The background is
/// the current anime's artwork, blurred; on top sit the sharp poster and info.
class FeaturedCarousel extends StatelessWidget {
  const FeaturedCarousel({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final HomeSectionState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    final Widget child;
    if (state.items.isNotEmpty) {
      child = _CarouselPager(key: const ValueKey('pager'), items: state.items);
    } else if (state.hasError) {
      child = Padding(
        key: const ValueKey('error'),
        padding: EdgeInsets.fromLTRB(16, top + 16, 16, 24),
        child: ErrorCard(message: describeError(state.error), onRetry: onRetry),
      );
    } else if (!state.isLoading) {
      child = SizedBox(key: const ValueKey('empty'), height: top);
    } else {
      child = const _HeroSkeleton(key: ValueKey('skeleton'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      // Clip.none: the hero's backdrop deliberately overflows its bottom edge,
      // and the default layout would clip it.
      layoutBuilder: (current, previous) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}

class _CarouselPager extends StatefulWidget {
  const _CarouselPager({super.key, required this.items});

  final List<AnimeMedia> items;

  @override
  State<_CarouselPager> createState() => _CarouselPagerState();
}

class _CarouselPagerState extends State<_CarouselPager> {
  static const _autoplayDelay = Duration(seconds: 6);

  // Start far from 0 so the pager can be swiped endlessly in both
  // directions; the real index is always `page % items.length`.
  late final PageController _controller = PageController(
    initialPage: widget.items.length * 1000,
  );
  final ValueNotifier<int> _current = ValueNotifier(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Autoplay will be scheduled in didChangeDependencies based on TickerMode.
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      _precacheCarousel();
    }
    if (TickerMode.valuesOf(context).enabled) {
      if (_timer == null || !_timer!.isActive) {
        _scheduleNext();
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _precacheCarousel() {
    for (final item in widget.items) {
      final url = item.coverUrl;
      if (url != null && url.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(
            url,
            maxWidth: 450,
            cacheManager: animeImageCache,
          ),
          context,
        ).catchError((_) {});
        precacheImage(
          CachedNetworkImageProvider(
            url,
            maxWidth: 140,
            cacheManager: animeImageCache,
          ),
          context,
        ).catchError((_) {});
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _current.dispose();
    super.dispose();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = null;
    if (!mounted || widget.items.length < 2) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    _timer = Timer(_autoplayDelay, _advance);
  }

  bool get _isOnScreen {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    return bottom > 0 && top < MediaQuery.sizeOf(context).height;
  }

  void _advance() {
    if (!mounted) return;
    // Stop autoplay completely if tab or route is not active.
    if (!TickerMode.valuesOf(context).enabled) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    // Skip while the user is dragging or the carousel has been scrolled out of view.
    if (!_controller.hasClients ||
        _controller.position.isScrollingNotifier.value ||
        !_isOnScreen) {
      _scheduleNext();
      return;
    }
    _controller
        .nextPage(
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
          if (mounted && TickerMode.valuesOf(context).enabled) {
            _scheduleNext();
          }
        });
  }

  /// Arrow buttons (wide layouts): one page back / forward.
  void _step(int direction) {
    if (!_controller.hasClients) return;
    _timer?.cancel();
    _timer = null;
    const duration = Duration(milliseconds: 450);
    const curve = Curves.easeInOutCubic;
    final done = direction > 0
        ? _controller.nextPage(duration: duration, curve: curve)
        : _controller.previousPage(duration: duration, curve: curve);
    done.whenComplete(() {
      if (mounted && TickerMode.valuesOf(context).enabled) {
        _scheduleNext();
      }
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _timer?.cancel(); // user took over
      _timer = null;
    } else if (n is ScrollEndNotification) {
      _scheduleNext();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final top = MediaQuery.paddingOf(context).top;
    final pageBg = Theme.of(context).scaffoldBackgroundColor;
    final wide = _isWide(context);
    // Arrows only on big screens; tablets (medium) just swipe.
    final showArrows = _showArrows(context);
    final bottomGap = _bottomGapFor(context);
    final topGap = wide ? _wideTopGap : _heroTopGap;
    final position = Scrollable.maybeOf(context)?.position;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The hero is always dark, so keep status bar icons light.
      value: SystemUiOverlayStyle.light,
      child: SizedBox(
        // Layout height is just the foreground (poster + text); the backdrop
        // below overflows it on purpose and is painted behind what follows.
        height: _heroHeight(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Blurred backdrop + gradient, separate from the pager ────
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: -_backdropExtra,
              child: _PinnedTop(
                position: position,
                child: RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _current,
                        builder: (context, current, _) => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: _Backdrop(
                            key: ValueKey(current),
                            anime: items[current],
                          ),
                        ),
                      ),
                      // Unified seamless gradient: darkens status bar at top, preserves vibrant
                      // poster art in the middle, and provides a deep, smooth, continuous transition
                      // into page background at the bottom.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.22, 0.48, 0.70, 0.88, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.30),
                              Colors.transparent,
                              pageBg.withValues(alpha: 0.35),
                              pageBg.withValues(alpha: 0.85),
                              pageBg,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Thin opaque strip in the page colour over the backdrop's bottom
            // edge, ensuring zero raster seam or gap between the gradient and
            // the background.
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 3,
              child: ColoredBox(color: pageBg),
            ),

            // ── Pages: poster + info ────────────────────────────────────
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: PageView.builder(
                  controller: _controller,
                  allowImplicitScrolling: true,
                  onPageChanged: (page) => _current.value = page % items.length,
                  itemBuilder: (context, page) {
                    final index = page % items.length;
                    return Padding(
                      padding: EdgeInsets.only(
                        top: top + topGap,
                        bottom: bottomGap,
                      ),
                      child: wide
                          ? _HeroPageWide(
                              anime: items[index],
                              rank: index + 1,
                              page: page,
                            )
                          : _HeroPage(
                              anime: items[index],
                              rank: index + 1,
                              page: page,
                            ),
                    );
                  },
                ),
              ),
            ),

            // Position indicator, in the gap under the info block.
            if (items.length > 1)
              Positioned(
                left: wide ? 84.0 : 0.0,
                right: 0,
                bottom: bottomGap - 3,
                height: 6,
                child: IgnorePointer(
                  child: Center(
                    child: _PagerDots(current: _current, count: items.length),
                  ),
                ),
              ),

            // Arrows for mouse users on wide layouts (swiping isn't obvious).
            if (showArrows && items.length > 1)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: top + _wideTopGap,
                    bottom: bottomGap,
                    left: 12 + (wide ? 84.0 : 0.0),
                    right: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PagerArrow(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _step(-1),
                      ),
                      _PagerArrow(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => _step(1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keeps its bottom edge in place and grows upward while the page is pulled
/// down past the top, so the backdrop stays pinned to the top of the screen.
class _PinnedTop extends StatelessWidget {
  const _PinnedTop({required this.position, required this.child});

  final ScrollPosition? position;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final position = this.position;
    if (position == null) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return ListenableBuilder(
          listenable: position,
          builder: (context, _) {
            final over = (position.hasPixels && position.hasContentDimensions)
                ? math.max(0.0, position.minScrollExtent - position.pixels)
                : (position.hasPixels && position.pixels < 0.0)
                ? -position.pixels
                : 0.0;
            return OverflowBox(
              alignment: Alignment.bottomCenter,
              minHeight: height + over,
              maxHeight: height + over,
              child: child,
            );
          },
        );
      },
    );
  }
}

class _PagerArrow extends StatelessWidget {
  const _PagerArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 28),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        fixedSize: const Size(44, 44),
      ),
    );
  }
}

/// Blurred, full-bleed artwork for one anime.
class _Backdrop extends StatelessWidget {
  const _Backdrop({super.key, required this.anime});

  final AnimeMedia anime;

  @override
  Widget build(BuildContext context) {
    // ClipRect: the blur otherwise bleeds outside the hero and paints over
    // the content below it.
    return RepaintBoundary(
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 16,
            sigmaY: 16,
            tileMode: TileMode.clamp,
          ),
          child: Transform.scale(
            scale: 1.15,
            alignment: Alignment.topCenter,
            child: SizedBox.expand(
              child: AnimeImage(
                anime.coverUrl,
                alignment: Alignment.topCenter,
                tint: anime.coverColor,
                cacheWidth: 140,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Page
// ═════════════════════════════════════════════════════════════════════════

class _HeroPage extends StatefulWidget {
  const _HeroPage({
    required this.anime,
    required this.rank,
    required this.page,
  });

  final AnimeMedia anime;
  final int rank;
  final int page;

  @override
  State<_HeroPage> createState() => _HeroPageState();
}

class _HeroPageState extends State<_HeroPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final anime = widget.anime;
    final rank = widget.rank;
    final page = widget.page;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final score = anime.scoreLabel;
    // "Ep 6 · in 6d 16h" -> "Ep 6 airs in 6d 16h": the countdown is the time
    // until that episode comes out.
    final airing = anime.nextAiring?.label.replaceFirst(' · in ', ' in ');
    final episodes = anime.episodes == null
        ? null
        : '${anime.episodes} ${anime.episodes == 1 ? 'Ep' : 'Eps'}';
    final genres = anime.genres.take(3).toList();
    final format = anime.formatLabel;
    // "TV · Ep 6 in 13d 16h" as one quiet line.
    final info = <String?>[
      format,
      episodes,
      airing,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');

    final heroTag = 'carousel-$page-${anime.id}';

    // StackFit.expand: otherwise the column shrinks to its widest child and
    // short titles end up left-aligned instead of centred.
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Sharp poster, rank top-left and score bottom-left.
                Container(
                  width: _posterWidthFor(context),
                  height: _posterHeightFor(context),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kPosterRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: heroTag,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(kPosterRadius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimeImage(
                              anime.coverUrl,
                              tint: anime.coverColor,
                              cacheWidth: 450,
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: _Chip('#$rank', highlight: true),
                            ),
                            if (score != null)
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: ScoreBadge(
                                  score,
                                  tint: anime.coverColor != null
                                      ? Color(anime.coverColor!)
                                      : cs.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: _posterInfoGap),

              // Info, centred under the poster.
              SizedBox(
                height: _infoHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (info.isNotEmpty)
                      Text(
                        info,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    if (genres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final genre in genres)
                            _Chip(genre, tint: genreColor(genre)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Ripple over the whole page.
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              splashColor: cs.primary.withValues(alpha: 0.15),
              onTap: () =>
                  openAnime(context, anime, heroTag: heroTag),
            ),
          ),
        ),
      ],
    ),
  );
  }
}

String _infoLine(AnimeMedia anime) {
  final airing = anime.nextAiring?.label.replaceFirst(' · in ', ' in ');
  final eps = anime.episodes;
  final episodes = eps == null ? null : '$eps ${eps == 1 ? 'Ep' : 'Eps'}';
  return <String?>[
    anime.formatLabel,
    episodes,
    airing,
  ].where((e) => e != null && e.isNotEmpty).join(' · ');
}

/// Tablet / desktop page: poster on the left, text on the right, centred up to
/// the max content width. Left/right gutters leave room for the arrow buttons.
class _HeroPageWide extends StatefulWidget {
  const _HeroPageWide({
    required this.anime,
    required this.rank,
    required this.page,
  });

  final AnimeMedia anime;
  final int rank;
  final int page;

  @override
  State<_HeroPageWide> createState() => _HeroPageWideState();
}

class _HeroPageWideState extends State<_HeroPageWide>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final anime = widget.anime;
    final rank = widget.rank;
    final page = widget.page;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final score = anime.scoreLabel;
    final genres = anime.genres.take(4).toList();
    final info = _infoLine(anime);
    final inset = pageInset(context, gutter: _showArrows(context) ? 72 : 24);
    final big = context.layoutSize.atLeast(WindowSize.expanded);
    final isWide = context.hasSideNav;
    final railOffset = isWide ? 84.0 : 0.0;
    final heroTag = 'carousel-wide-$page-${anime.id}';

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(inset + railOffset, 0, inset, 0),
            child: Row(
              children: [
                Container(
                  width: _posterWidthFor(context),
                  height: _posterHeightFor(context),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kPosterRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: heroTag,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(kPosterRadius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimeImage(
                              anime.coverUrl,
                              tint: anime.coverColor,
                              cacheWidth: 550,
                            ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: _Chip('#$rank', highlight: true),
                          ),
                          if (score != null)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: ScoreBadge(
                                score,
                                tint: anime.coverColor != null
                                    ? Color(anime.coverColor!)
                                    : cs.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (big
                                  ? theme.textTheme.headlineMedium
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                                letterSpacing: -0.3,
                              ),
                    ),
                    if (info.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        info,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    if (genres.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final genre in genres)
                            _Chip(genre, tint: genreColor(genre)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Ripple over the whole page.
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              splashColor: cs.primary.withValues(alpha: 0.15),
              onTap: () =>
                  openAnime(context, anime, heroTag: heroTag),
            ),
          ),
        ),
      ],
    ),
  );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.highlight = false, this.tint});

  final String label;
  final bool highlight;

  /// Colours the pill (tinted background, light text of the same hue).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tint != null
            ? tint!.withValues(alpha: 0.38)
            : highlight
            ? cs.primary
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(9),
        border: tint != null
            ? Border.all(color: tint!.withValues(alpha: 0.7), width: 0.8)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint != null
              ? lightenColor(tint!)
              : highlight
              ? cs.onPrimary
              : Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Mask for the backdrop: fully visible behind the text, then an eased
/// (smoothstep) fade to transparent over the extra space below it. Shared by
/// the real hero and the loading skeleton so both look the same.
Shader _backdropFade(Rect rect, double bottomGap) {
  final solid = ((rect.height - bottomGap + 4) / rect.height)
      .clamp(0.0, 0.7);
  // Many stops: a plain two-stop ramp has a visible hard start and end.
  const steps = 16;
  const end = 0.98;
  final stops = <double>[0];
  final colors = <Color>[Colors.black];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final eased = t * t * (3 - 2 * t);
    stops.add(solid + (end - solid) * t);
    colors.add(Colors.black.withValues(alpha: 1 - eased));
  }
  stops.add(1);
  colors.add(Colors.transparent);
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: stops,
    colors: colors,
  ).createShader(rect);
}

// ═════════════════════════════════════════════════════════════════════════
// Loading skeleton
// ═════════════════════════════════════════════════════════════════════════

/// Loading placeholder shaped like the real hero: same height, same faded
/// backdrop, a poster block and text bars, so nothing jumps when data arrives.
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    if (_isWide(context)) return const _WideHeroSkeleton();

    final cs = Theme.of(context).colorScheme;
    final pageBg = Theme.of(context).scaffoldBackgroundColor;
    final top = MediaQuery.paddingOf(context).top;

    Widget bar(double width, double height, [double radius = 8]) =>
        Skeleton(width: width, height: height, radius: radius);

    return SizedBox(
      height: _heroHeight(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Same backdrop + fade as the real hero, in a neutral tone.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: -_backdropExtra,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => _backdropFade(rect, _heroBottomGap),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.onSurface.withValues(alpha: 0.14),
                      cs.onSurface.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Same edge strip as the real hero.
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 3,
            child: ColoredBox(color: pageBg),
          ),

          // Positioned.fill: otherwise the column shrinks to the poster's
          // width and sits at the left instead of the centre.
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: top + _heroTopGap,
                bottom: _heroBottomGap,
              ),
              child: Column(
                children: [
                  Skeleton(
                    width: _posterWidthFor(context),
                    height: _posterHeightFor(context),
                    radius: kPosterRadius,
                  ),
                  const SizedBox(height: _posterInfoGap),
                  SizedBox(
                    height: _infoHeight,
                    child: Column(
                      children: [
                        bar(230, 20),
                        const SizedBox(height: 8),
                        bar(120, 12),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            bar(64, 22, 9),
                            const SizedBox(width: 6),
                            bar(76, 22, 9),
                            const SizedBox(width: 6),
                            bar(70, 22, 9),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wide-layout loading placeholder: faded backdrop, poster block on the left,
/// text bars on the right.
class _WideHeroSkeleton extends StatelessWidget {
  const _WideHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pageBg = Theme.of(context).scaffoldBackgroundColor;
    final top = MediaQuery.paddingOf(context).top;
    final inset = pageInset(context, gutter: _showArrows(context) ? 72 : 24);
    final isWide = context.hasSideNav;
    final railOffset = isWide ? 84.0 : 0.0;

    Widget bar(double width, double height, [double radius = 8]) =>
        Skeleton(width: width, height: height, radius: radius);

    return SizedBox(
      height: _heroHeight(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: -_backdropExtra,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => _backdropFade(rect, _wideBottomGap),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.onSurface.withValues(alpha: 0.14),
                      cs.onSurface.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 3,
            child: ColoredBox(color: pageBg),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                inset + railOffset,
                top + _wideTopGap,
                inset,
                _wideBottomGap,
              ),
              child: Row(
                children: [
                  Skeleton(
                    width: _posterWidthFor(context),
                    height: _posterHeightFor(context),
                    radius: kPosterRadius,
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(300, 28),
                        const SizedBox(height: 10),
                        bar(180, 14),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            bar(70, 24, 9),
                            const SizedBox(width: 8),
                            bar(84, 24, 9),
                            const SizedBox(width: 8),
                            bar(76, 24, 9),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
