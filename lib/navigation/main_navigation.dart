import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, SystemChannels;
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/update/update_service.dart';
import 'package:aniways/core/widgets/update_bottom_sheet.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import 'package:aniways/screens/home_screen.dart';
import 'package:aniways/screens/search/search_filter.dart';
import 'package:aniways/screens/search/search_results_screen.dart';
import 'package:aniways/screens/search_screen.dart';
import 'package:aniways/screens/saved_screen.dart';
import 'package:aniways/screens/settings_screen.dart';
import 'package:aniways/core/widgets/app_logo.dart';

// ── Nav bar metrics: single source of truth for the floating pill ──────────
const double kNavBarItemHeight = 42;
const double kNavBarInnerPadding = 5; // applied on all sides
const double kNavBarBottomMargin = 24;
const double kNavBarHorizontalMargin = 52;

const double kNavBarHeight = kNavBarItemHeight + kNavBarInnerPadding * 2; // 48
const double kRailWidth = 84;

/// Bottom padding scrollable content needs so nothing hides behind the pill.
/// Wide layouts have a side rail instead, so only the system inset remains.
double navBarClearance(BuildContext context, {double extra = 16}) {
  final bottom = MediaQuery.viewPaddingOf(context).bottom;
  if (context.hasSideNav) return bottom + extra;
  return kNavBarHeight + kNavBarBottomMargin + bottom + extra;
}

/// Marker interface for screens that manage their own full-bleed layout
/// behind the side navigation rail on wide screens (e.g. [AnimeDetailsScreen]).
abstract class FullBleedScreen {}

/// Dynamically applies [kRailWidth] padding on the left when the side navigation
/// rail is visible ([context.hasSideNav] is true). Automatically responds to
/// device rotation without hardcoding padding at push-time.
class _RailAdaptivePadding extends StatelessWidget {
  const _RailAdaptivePadding({
    required this.child,
    this.isFullBleed = false,
  });

  final Widget child;
  final bool isFullBleed;

  @override
  Widget build(BuildContext context) {
    if (!context.hasSideNav || isFullBleed) return child;
    return Padding(
      padding: const EdgeInsets.only(left: kRailWidth),
      child: child,
    );
  }
}

/// Navigator observer that tracks full-page routes inside a tab navigator,
/// allowing the floating navigation pill to hide when a sub-screen is pushed
/// and reappear when popped back to root, and tracking the active route's
/// navigation rail theme.
class _TabNavObserver extends NavigatorObserver {
  _TabNavObserver();

  final List<PageRoute> _pageStack = [];

  PageRoute? get currentPage => _pageStack.lastOrNull;
  bool get canPop => _pageStack.length > 1;

  void _notify() {
    _MainNavigationState._activeState?._updateNavPill();
    _MainNavigationState._activeState?._updateRailTheme();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _pageStack.add(route);
      if (previousRoute != null) {
        _notify();
      }
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      _pageStack.remove(route);
      MainNavigation.removeRouteRailTheme(route);
      _notify();
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is PageRoute) {
      _pageStack.remove(route);
      MainNavigation.removeRouteRailTheme(route);
      _notify();
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute is PageRoute) {
      final idx = _pageStack.indexOf(oldRoute);
      if (idx != -1) {
        if (newRoute is PageRoute) {
          _pageStack[idx] = newRoute;
        } else {
          _pageStack.removeAt(idx);
        }
      } else if (newRoute is PageRoute) {
        _pageStack.add(newRoute);
      }
      MainNavigation.removeRouteRailTheme(oldRoute);
    } else if (newRoute is PageRoute) {
      _pageStack.add(newRoute);
    }
    _notify();
  }
}

/// Opens [screen] from within the active tab's navigation stack.
///
/// Automatically applies dynamic side-rail padding on wide screens, keeps the
/// route persistent across screen rotations, and smoothly animates the floating
/// pill in and out on compact screens.
Future<T?> pushFullScreen<T>(
  BuildContext context,
  Widget screen, {
  bool fade = false,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

  final isFullBleed = screen is FullBleedScreen;
  final pageWidget = _RailAdaptivePadding(
    isFullBleed: isFullBleed,
    child: screen,
  );

  NavigatorState nav;
  try {
    nav = Navigator.of(context, rootNavigator: false);
  } catch (_) {
    final activeIndex = _MainNavigationState._activeState?._index ?? 0;
    nav = _MainNavigationState._activeState?._navKeys[activeIndex].currentState ??
        Navigator.of(context, rootNavigator: true);
  }

  if (fade) {
    return nav.push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, _, _) => pageWidget,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
      ),
    );
  }
  return nav.push<T>(MaterialPageRoute(builder: (_) => pageWidget));
}

// ── Tabs ───────────────────────────────────────────────────────────────────

class _TabSpec {
  const _TabSpec({
    required this.icon,
    required this.inactiveIcon,
    required this.title,
    required this.builder,
  });

  final IconData icon;
  final IconData inactiveIcon;
  final String title;
  final WidgetBuilder builder;
}

final List<_TabSpec> _specs = [
  _TabSpec(
    icon: Icons.home_rounded,
    inactiveIcon: Icons.home_outlined,
    title: 'Home',
    builder: (_) => const HomeScreen(),
  ),
  _TabSpec(
    icon: Icons.search_rounded,
    inactiveIcon: Icons.search_outlined,
    title: 'Search',
    builder: (_) => const SearchScreen(),
  ),
  _TabSpec(
    icon: Icons.video_library_rounded,
    inactiveIcon: Icons.video_library_outlined,
    title: 'Library',
    builder: (_) => const SavedScreen(),
  ),
  _TabSpec(
    icon: Icons.settings_rounded,
    inactiveIcon: Icons.settings_outlined,
    title: 'Settings',
    builder: (_) => const SettingsScreen(),
  ),
];

final List<NavigationRailDestination> _railDestinations = [
  for (final t in _specs)
    NavigationRailDestination(
      icon: Icon(t.inactiveIcon),
      selectedIcon: Icon(t.icon),
      label: Text(t.title),
      padding: const EdgeInsets.symmetric(vertical: 2),
    ),
];

/// Root navigation shell.
///
/// * Compact (phones): [PersistentTabView] with the floating Style2 pill.
/// * Wide (tablets, desktop): a left [NavigationRail] (extended with labels on
///   large windows) next to the content. Every tab has its own [Navigator] so
///   screens opened from a tab keep the rail visible, and tab state survives
///   switching tabs.
///
/// The selected tab is remembered when the window is resized across the
/// breakpoint (e.g. rotating a tablet or resizing a desktop window).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Opens search results directly for a [query], [genre], or full [filter],
  /// scrolling to [targetIndex] in the results, without tab jumping or flashing.
  static void switchToSearch(
    BuildContext context, {
    String? query,
    String? genre,
    AnimeSearchFilter? filter,
    int? targetIndex,
  }) {
    final target =
        filter ?? (genre != null ? AnimeSearchFilter(genre: genre) : null);

    pushFullScreen(
      context,
      SearchResultsScreen(
        initialQuery: query,
        initialFilter: target,
        initialTargetIndex: targetIndex,
      ),
      fade: false,
    );
  }

  /// Switches to the tab at [tabIndex] (0: Home, 1: Search, 2: Library, 3: Settings).
  static void switchToTab(int tabIndex) {
    final state = _MainNavigationState._activeState;
    if (state != null && tabIndex >= 0 && tabIndex < _specs.length) {
      state._select(tabIndex);
    }
  }

  /// Map of Route to custom rail ThemeData override.
  static final Map<Route, ThemeData> _routeRailThemes = {};

  /// Current active rail theme for each tab (keyed by tab index).
  static final ValueNotifier<Map<int, ThemeData?>> tabRailThemes =
      ValueNotifier<Map<int, ThemeData?>>({});

  /// Sets a custom rail theme for a specific [route].
  static void setRouteRailTheme(Route route, ThemeData? theme) {
    if (theme != null) {
      _routeRailThemes[route] = theme;
    } else {
      _routeRailThemes.remove(route);
    }
    _MainNavigationState._activeState?._updateRailTheme();
  }

  /// Removes the custom rail theme for a specific [route].
  static void removeRouteRailTheme(Route route) {
    if (_routeRailThemes.remove(route) != null) {
      _MainNavigationState._activeState?._updateRailTheme();
    }
  }

  /// Deprecated compatibility stubs
  @Deprecated('Use setRouteRailTheme instead')
  static final ValueNotifier<Map<int, List<ThemeData>>> tabRailThemeStacks =
      ValueNotifier<Map<int, List<ThemeData>>>({});

  @Deprecated('Use setRouteRailTheme instead')
  static void pushTabRailTheme(int tabIndex, ThemeData theme) {}

  @Deprecated('Use removeRouteRailTheme instead')
  static void popTabRailTheme(int tabIndex) {}

  @Deprecated('Use setRouteRailTheme instead')
  static void updateCurrentTabRailTheme(int tabIndex, ThemeData theme) {}

  /// When true, suppresses the navigation rail even in wide mode (e.g. while playing video).
  static final ValueNotifier<bool> hideNavRail = ValueNotifier<bool>(false);

  /// Whether the mobile bottom navigation pill is currently visible on screen.
  static final ValueNotifier<bool> navPillVisible = ValueNotifier<bool>(false);

  /// Index of the currently selected tab in wide layout.
  static int get activeTabIndex =>
      _MainNavigationState._activeState?._index ?? 0;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static _MainNavigationState? _activeState;

  final _navKeys = List.generate(
    _specs.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<_TabNavObserver> _observers = List.generate(
    _specs.length,
    (_) => _TabNavObserver(),
  );

  late final List<HeroController> _heroControllers = List.generate(
    _specs.length,
    (_) => MaterialApp.createMaterialHeroController(),
  );

  /// Tabs opened at least once; the rest aren't built until first visited.
  final _visited = <int>{0};
  int _index = 0;

  bool get _canPop => _observers[_index].canPop;

  void _updateNavPill() {
    if (!mounted) return;
    final isWide = context.hasSideNav;
    final show = !isWide && !_canPop;
    if (MainNavigation.navPillVisible.value != show) {
      MainNavigation.navPillVisible.value = show;
    }
  }

  void _updateRailTheme() {
    if (!mounted) return;
    final Map<int, ThemeData?> updated = {};
    for (var i = 0; i < _observers.length; i++) {
      final topPage = _observers[i].currentPage;
      if (topPage != null &&
          MainNavigation._routeRailThemes.containsKey(topPage)) {
        updated[i] = MainNavigation._routeRailThemes[topPage];
      } else {
        updated[i] = null;
      }
    }
    MainNavigation.tabRailThemes.value = updated;
  }

  @override
  void initState() {
    super.initState();
    _activeState = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNavPill();
      _updateRailTheme();
      _checkStartupUpdate();
    });
  }

  Future<void> _checkStartupUpdate() async {
    try {
      final updateService = UpdateService.instance;
      final shouldCheck = await updateService.shouldAutoCheck();
      if (!shouldCheck) return;

      final res = await updateService.checkForUpdate();
      if (res.hasUpdate && res.release != null && mounted) {
        UpdateBottomSheet.show(context, res.release!);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in _heroControllers) {
      c.dispose();
    }
    if (_activeState == this) _activeState = null;
    MainNavigation.navPillVisible.value = false;
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) {
      // Tapping the current tab again returns to its first screen.
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
      _updateNavPill();
      _updateRailTheme();
      return;
    }
    setState(() {
      _index = i;
      _visited.add(i);
    });
    _updateNavPill();
    _updateRailTheme();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = cs.primary;
    final isWide = context.hasSideNav;

    final isPureBlack =
        isDark &&
        (cs.surface == const Color(0xFF000000) ||
            theme.scaffoldBackgroundColor == const Color(0xFF000000));

    final navBg = isPureBlack
        ? Color.alphaBlend(
            primary.withValues(alpha: 0.10),
            const Color(0xFF202024),
          )
        : Color.alphaBlend(
            primary.withValues(alpha: isDark ? 0.22 : 0.14),
            isDark ? const Color(0xFF1E1E22) : const Color(0xFFE4E4E8),
          );

    final borderColor = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.32 : 0.24),
      cs.outlineVariant,
    ).withValues(alpha: isDark ? 0.35 : 0.45);

    return PopScope(
      canPop: _index == 0 && !_canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != 0 && !_canPop) {
          _select(0);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            body: ValueListenableBuilder<bool>(
              valueListenable: MainNavigation.hideNavRail,
              builder: (context, hideRail, _) {
                final showRail = isWide && !hideRail;

                return Stack(
                  children: [
                    // ── Content Area: Persistent Tab Views ───────────────────────
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final contentWidth = showRail
                              ? math.max(0.0, box.maxWidth - kRailWidth)
                              : box.maxWidth;

                          return ContentArea(
                            width: contentWidth,
                            child: IndexedStack(
                              index: _index,
                              children: [
                                for (var i = 0; i < _specs.length; i++)
                                  if (_visited.contains(i))
                                    TickerMode(
                                      enabled: _index == i,
                                      child: HeroControllerScope(
                                        controller: _heroControllers[i],
                                        child: NavigatorPopHandler(
                                          enabled: _index == i,
                                          onPopWithResult: (_) {
                                            _navKeys[i].currentState?.maybePop();
                                          },
                                          child: ValueListenableBuilder<bool>(
                                            valueListenable:
                                                MainNavigation.navPillVisible,
                                            builder:
                                                (context, hasNavBar, child) {
                                              return NavBarScope(
                                                hasBottomNavBar: hasNavBar,
                                                child: child!,
                                              );
                                            },
                                            child: Navigator(
                                              key: _navKeys[i],
                                              observers: [_observers[i]],
                                              onGenerateRoute: (settings) =>
                                                  MaterialPageRoute(
                                                settings: settings,
                                                builder: (ctx) {
                                                  final page = _specs[i].builder(ctx);
                                                  // Tab 0 (Home) manages its full-bleed carousel backdrop itself.
                                                  if (i == 0) return page;
                                                  return _RailAdaptivePadding(
                                                    child: page,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Frosted Glass Navigation Rail (Wide mode) ────────────────
                    if (showRail)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: kRailWidth,
                        child: ValueListenableBuilder<Map<int, ThemeData?>>(
                          valueListenable: MainNavigation.tabRailThemes,
                          builder: (context, themes, _) {
                            final activeTheme =
                                themes[_index] ?? Theme.of(context);
                            final effectiveCs = activeTheme.colorScheme;
                            final isRailDark = activeTheme.brightness == Brightness.dark;

                            return AnimatedTheme(
                              data: activeTheme,
                              duration: const Duration(milliseconds: 250),
                              child: ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    decoration: BoxDecoration(
                                      color: isRailDark
                                          ? effectiveCs.surface.withValues(alpha: 0.30)
                                          : effectiveCs.surface.withValues(alpha: 0.35),
                                      border: Border(
                                        right: BorderSide(
                                          color: effectiveCs.outlineVariant.withValues(
                                            alpha: isRailDark ? 0.20 : 0.35,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          physics: const ClampingScrollPhysics(),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: constraints.maxHeight,
                                            ),
                                            child: IntrinsicHeight(
                                              child: NavigationRail(
                                                extended: false,
                                                minWidth: kRailWidth,
                                                minExtendedWidth: 220,
                                                groupAlignment: -0.2,
                                                backgroundColor: Colors.transparent,
                                                indicatorColor: effectiveCs.primary,
                                                labelType: NavigationRailLabelType.all,
                                                selectedIconTheme: IconThemeData(
                                                  color: effectiveCs.onPrimary,
                                                ),
                                                unselectedIconTheme: IconThemeData(
                                                  color: effectiveCs.onSurfaceVariant,
                                                ),
                                                selectedLabelTextStyle: TextStyle(
                                                  color: effectiveCs.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                unselectedLabelTextStyle: TextStyle(
                                                  color: effectiveCs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                leading: Padding(
                                                  padding: const EdgeInsets.only(
                                                    bottom: 20,
                                                  ),
                                                  child: Transform.translate(
                                                    offset: const Offset(0, -10),
                                                    child: AppLogo(
                                                      size: 58,
                                                      color: effectiveCs.primary,
                                                    ),
                                                  ),
                                                ),
                                                selectedIndex: _index,
                                                onDestinationSelected: _select,
                                                destinations: _railDestinations,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Frosted Glass Floating Pill (Compact mode) ───────────────
          // Rendered on top of Scaffold in the outer Stack so touch events
          // on the navigation tabs always take precedence without being blocked
          // by floating snackbars.
          if (!isWide)
            Positioned(
              left: math.max(
                kNavBarHorizontalMargin,
                (MediaQuery.sizeOf(context).width - 380) / 2,
              ),
              right: math.max(
                kNavBarHorizontalMargin,
                (MediaQuery.sizeOf(context).width - 380) / 2,
              ),
              bottom: kNavBarBottomMargin +
                  MediaQuery.viewPaddingOf(context).bottom,
              child: ValueListenableBuilder<bool>(
                valueListenable: MainNavigation.navPillVisible,
                builder: (context, showBottomPill, child) {
                  return AnimatedSlide(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.fastOutSlowIn,
                    offset: showBottomPill ? Offset.zero : const Offset(0, 1.6),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: showBottomPill ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !showBottomPill,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Style2PillNavBar(
                  navBarConfig: NavBarConfig(
                    selectedIndex: _index,
                    items: [
                      for (int i = 0; i < _specs.length; i++)
                        ItemConfig(
                          icon: Icon(_specs[i].icon),
                          inactiveIcon: Icon(_specs[i].inactiveIcon),
                          title: _specs[i].title,
                          iconSize: 22,
                          activeForegroundColor: cs.onPrimary,
                          inactiveForegroundColor: cs.onSurfaceVariant,
                          activeColorSecondary: cs.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                    onItemSelected: _select,
                  ),
                  decoration: BoxDecoration(
                    color: navBg.withValues(
                      alpha: isDark ? 0.70 : 0.76,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(
                          alpha: isDark ? 0.18 : 0.10,
                        ),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: borderColor, width: 0.9),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact, snug floating pill navigation bar implementing Style2 with
/// fluid Apple-style interactive drag gestures and smooth physics.
class Style2PillNavBar extends StatefulWidget {
  const Style2PillNavBar({
    required this.navBarConfig,
    required this.decoration,
    super.key,
  });

  final NavBarConfig navBarConfig;
  final Decoration decoration;

  @override
  State<Style2PillNavBar> createState() => _Style2PillNavBarState();
}

class _Style2PillNavBarState extends State<Style2PillNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late CurvedAnimation _curvedAnimation;
  late Tween<double> _animTween;

  late final ValueNotifier<double> _currentT;
  int _targetIndex = 0;
  bool _isDragging = false;
  double _dragAnchor = 0.0;
  int _lastHapticIndex = 0;

  @override
  void initState() {
    super.initState();
    final initialT = widget.navBarConfig.selectedIndex.toDouble();
    _currentT = ValueNotifier<double>(initialT);
    _targetIndex = widget.navBarConfig.selectedIndex;
    _lastHapticIndex = widget.navBarConfig.selectedIndex;
    _animTween = Tween<double>(begin: initialT, end: initialT);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _curvedAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.fastOutSlowIn,
    )..addListener(() {
        _currentT.value = _animTween.evaluate(_curvedAnimation);
      });
  }

  @override
  void didUpdateWidget(Style2PillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navBarConfig.selectedIndex !=
        oldWidget.navBarConfig.selectedIndex) {
      if (!_isDragging && _targetIndex != widget.navBarConfig.selectedIndex) {
        _targetIndex = widget.navBarConfig.selectedIndex;
        _animateTo(widget.navBarConfig.selectedIndex.toDouble());
      }
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _animController.dispose();
    _currentT.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    if (!mounted) return;
    _animController.stop();
    final startT = _currentT.value;
    if ((startT - target).abs() < 0.001) {
      _currentT.value = target;
      return;
    }
    final distance = (startT - target).abs();
    final durationMs = (180 + (distance * 100).clamp(0, 100)).toInt();
    _animController.duration = Duration(milliseconds: durationMs);

    _animTween = Tween<double>(begin: startT, end: target);
    _animController.forward(from: 0.0);
  }

  void _selectTab(int index) {
    if (index < 0 || index >= widget.navBarConfig.items.length) return;
    HapticFeedback.selectionClick();
    _targetIndex = index;
    _animateTo(index.toDouble());
    widget.navBarConfig.onItemSelected(index);
  }

  void _onDragStart(
    DragStartDetails details,
    double wu,
    double ws,
    int count,
  ) {
    if (count <= 1) return;
    _animController.stop();
    _isDragging = true;
    final touchX = details.localPosition.dx;
    final clampedT = _currentT.value.clamp(0.0, (count - 1).toDouble());
    final pillLeft = clampedT * wu;
    final pillCenter = pillLeft + ws / 2;

    _dragAnchor = touchX - pillCenter;
    _lastHapticIndex = clampedT.round().clamp(0, count - 1);
  }

  void _onDragUpdate(DragUpdateDetails details, double wu, double ws, int count) {
    if (count <= 1 || !_isDragging) return;

    final rawCenter = details.localPosition.dx - _dragAnchor;
    final minCenter = ws / 2;
    final maxCenter = (count - 1) * wu + ws / 2;
    final desiredCenter = rawCenter.clamp(minCenter, maxCenter);

    // Keep anchor synced to avoid dead zone when reversing direction at boundaries
    _dragAnchor = details.localPosition.dx - desiredCenter;

    final double newT = ((desiredCenter - minCenter) / wu).clamp(
      0.0,
      (count - 1).toDouble(),
    );

    _currentT.value = newT;

    final hapticIdx = newT.round().clamp(0, count - 1);
    if (hapticIdx != _lastHapticIndex) {
      _lastHapticIndex = hapticIdx;
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails details, int count) {
    if (count <= 1 || !_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    int targetIndex;
    if (velocity > 350) {
      targetIndex = (_currentT.value.floor() + 1).clamp(0, count - 1);
    } else if (velocity < -350) {
      targetIndex = (_currentT.value.ceil() - 1).clamp(0, count - 1);
    } else {
      targetIndex = _currentT.value.round().clamp(0, count - 1);
    }

    _targetIndex = targetIndex;
    _animateTo(targetIndex.toDouble());

    if (targetIndex != widget.navBarConfig.selectedIndex) {
      HapticFeedback.selectionClick();
      widget.navBarConfig.onItemSelected(targetIndex);
    }
  }

  void _onDragCancel(int count) {
    if (!_isDragging) return;
    _isDragging = false;
    _targetIndex = widget.navBarConfig.selectedIndex;
    _animateTo(widget.navBarConfig.selectedIndex.toDouble());
  }

  void _onTapUp(
    TapUpDetails details,
    double availableWidth,
    double wu,
    double ws,
    int count,
  ) {
    final x = details.localPosition.dx;
    final t = _currentT.value;
    for (int i = 0; i < count; i++) {
      final left = _getItemLeft(i, t, wu, ws, count);
      final width = _getItemWidth(i, t, wu, ws, count);
      if (x >= left && x <= left + width) {
        _selectTab(i);
        return;
      }
    }
    final fallback = (x / (availableWidth / count)).floor().clamp(0, count - 1);
    _selectTab(fallback);
  }

  double _getItemLeft(int index, double t, double wu, double ws, int count) {
    final clampedT = t.clamp(0.0, (count - 1).toDouble());
    final k = clampedT.floor();
    if (k >= count - 1) {
      return index < count - 1 ? index * wu : (count - 1) * wu;
    }
    final alpha = clampedT - k;

    if (index < k) {
      return index * wu;
    } else if (index == k) {
      return k * wu;
    } else if (index == k + 1) {
      return k * wu + ws - alpha * (ws - wu);
    } else {
      return (index - 1) * wu + ws;
    }
  }

  double _getItemWidth(int index, double t, double wu, double ws, int count) {
    final clampedT = t.clamp(0.0, (count - 1).toDouble());
    final dist = (clampedT - index).abs();
    final active = dist >= 1.0 ? 0.0 : 1.0 - dist;
    return wu + active * (ws - wu);
  }

  double _getItemActiveFraction(int index, double t, int count) {
    final clampedT = t.clamp(0.0, (count - 1).toDouble());
    final dist = (clampedT - index).abs();
    if (dist >= 1.0) return 0.0;
    return 1.0 - dist;
  }

  Widget _buildItem(ItemConfig item, double activeFraction) {
    final color = Color.lerp(
      item.inactiveForegroundColor,
      item.activeForegroundColor,
      activeFraction,
    ) ?? item.activeForegroundColor;

    final hasText = item.title != null && activeFraction > 0.001;

    return Semantics(
      button: true,
      selected: activeFraction >= 0.5,
      label: item.title,
      excludeSemantics: true,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(
                size: item.iconSize,
                color: color,
              ),
              child: activeFraction >= 0.5 ? item.icon : item.inactiveIcon,
            ),
            if (hasText)
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: activeFraction.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: activeFraction.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.title!,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: item.textStyle.apply(
                          color: item.activeForegroundColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boxDec = widget.decoration is BoxDecoration
        ? widget.decoration as BoxDecoration
        : null;
    final borderRadius = boxDec?.borderRadius ?? BorderRadius.circular(50);
    final shadow = boxDec?.boxShadow;
    final innerDecoration = BoxDecoration(
      color: boxDec?.color,
      gradient: boxDec?.gradient,
      border: boxDec?.border,
      borderRadius: borderRadius,
    );

    final color = boxDec?.color;
    final isTranslucent = color == null ||
        color.a < 0.98 ||
        boxDec?.gradient != null;

    final barBody = Container(
      decoration: innerDecoration,
      padding: const EdgeInsets.all(kNavBarInnerPadding),
      child: LayoutBuilder(
                    builder: (context, constraints) {
                      final count = widget.navBarConfig.items.length;
                      if (count == 0) return const SizedBox.shrink();

                      final availableWidth = constraints.maxWidth;
                      const selectedRatio = 1.8;
                      final wu = availableWidth / (count - 1 + selectedRatio);
                      final ws = wu * selectedRatio;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (d) => _onDragStart(d, wu, ws, count),
                        onHorizontalDragUpdate: (d) => _onDragUpdate(d, wu, ws, count),
                        onHorizontalDragEnd: (d) => _onDragEnd(d, count),
                        onHorizontalDragCancel: () => _onDragCancel(count),
                        onTapUp: (d) => _onTapUp(d, availableWidth, wu, ws, count),
                        child: SizedBox(
                          height: kNavBarItemHeight,
                          width: availableWidth,
                          child: ValueListenableBuilder<double>(
                            valueListenable: _currentT,
                            builder: (context, currentT, _) {
                              final clampedT = currentT.clamp(0.0, (count - 1).toDouble());
                              final k = clampedT.floor();
                              final nextK = (k + 1).clamp(0, count - 1);
                              final alpha = (clampedT - k).clamp(0.0, 1.0);

                              final pillColor = Color.lerp(
                                widget.navBarConfig.items[k].activeBackgroundColor,
                                widget.navBarConfig.items[nextK].activeBackgroundColor,
                                alpha,
                              ) ?? widget.navBarConfig.selectedItem.activeBackgroundColor;

                              final pillLeft = clampedT * wu;

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Sliding indicator pill
                                  Positioned(
                                    left: pillLeft,
                                    top: 0,
                                    bottom: 0,
                                    width: ws,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: pillColor,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                  ),

                                  // Tab items (icons & labels) aligned over the pill
                                  for (int i = 0; i < count; i++)
                                    Positioned(
                                      left: _getItemLeft(i, currentT, wu, ws, count),
                                      top: 0,
                                      bottom: 0,
                                      width: _getItemWidth(i, currentT, wu, ws, count),
                                      child: _buildItem(
                                        widget.navBarConfig.items[i],
                                        _getItemActiveFraction(i, currentT, count),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: shadow,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: isTranslucent
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: barBody,
                    )
                  : barBody,
            ),
          ),
        ),
      ),
    );
  }
}

/// Scope that informs descendants whether the floating bottom navigation bar
/// is actively present on screen.
class NavBarScope extends InheritedWidget {
  const NavBarScope({
    super.key,
    required this.hasBottomNavBar,
    required super.child,
  });

  final bool hasBottomNavBar;

  /// Returns true if the floating bottom navigation bar is visible on [context].
  static bool hasNavBar(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<NavBarScope>();
    if (scope != null) return scope.hasBottomNavBar;

    // Fallback: check live global notifier
    return MainNavigation.navPillVisible.value;
  }

  @override
  bool updateShouldNotify(NavBarScope oldWidget) =>
      hasBottomNavBar != oldWidget.hasBottomNavBar;
}
