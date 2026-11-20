import 'package:flutter/material.dart';

import 'package:aniways/core/helpers.dart';

// ═══════════════════════════════════════════════════════════════════════
// WINDOW SIZE CLASSES  (Material 3: 600 / 840 / 1200)
// ═══════════════════════════════════════════════════════════════════════

/// How much room the app window has. Every screen asks this instead of
/// checking raw widths, so the breakpoints live in one place.
///
/// | class      | width        | typical device                      |
/// |------------|--------------|-------------------------------------|
/// | compact    | < 600        | phones, small windows               |
/// | medium     | 600 – 839    | tablets (portrait), foldables       |
/// | expanded   | 840 – 1199   | tablets (landscape), small desktop  |
/// | large      | ≥ 1200       | desktop windows                     |
enum WindowSize {
  compact,
  medium,
  expanded,
  large;

  static WindowSize ofWidth(double width) {
    if (width < 600) return WindowSize.compact;
    if (width < 840) return WindowSize.medium;
    if (width < 1200) return WindowSize.expanded;
    return WindowSize.large;
  }

  /// Size class of the window [context] lives in (not the page area).
  static WindowSize of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == WindowSize.compact;

  /// True from tablets up: side rail instead of the bottom pill, grids
  /// instead of single-column lists.
  bool get isWide => this != WindowSize.compact;

  /// True when [other] or anything bigger.
  bool atLeast(WindowSize other) => index >= other.index;
}

/// Set by the wide navigation shell around the page area, so screens know how
/// much room they really have (the window minus the side rail).
class ContentArea extends InheritedWidget {
  const ContentArea({super.key, required this.width, required super.child});

  final double width;

  static double? maybeWidthOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContentArea>()?.width;

  @override
  bool updateShouldNotify(ContentArea oldWidget) => width != oldWidget.width;
}

extension ResponsiveContext on BuildContext {
  /// Size class of the whole window. The navigation shell uses this.
  WindowSize get windowSize => WindowSize.of(this);

  /// Width a screen can actually use: the window minus the side rail when
  /// there is one.
  double get contentWidth =>
      ContentArea.maybeWidthOf(this) ?? MediaQuery.sizeOf(this).width;

  /// Size class of the space a screen can use. **Screens should use this**
  /// (not [windowSize]) to choose between phone and wide layouts.
  WindowSize get layoutSize => WindowSize.ofWidth(contentWidth);

  /// True when the side navigation rail is shown (landscape on tablets, or
  /// desktop). On phones and tablets in portrait, the bottom pill nav is used.
  bool get hasSideNav {
    if (isDesktop()) return !windowSize.isCompact;
    final isTablet = MediaQuery.sizeOf(this).shortestSide >= 600;
    if (!isTablet) return false;
    final isPortrait = MediaQuery.orientationOf(this) == Orientation.portrait;
    return !isPortrait;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LAYOUT HELPERS
// ═══════════════════════════════════════════════════════════════════════

/// Widest the page content is allowed to get before it is centred.
const double kMaxContentWidth = 1200;

/// Horizontal padding that keeps content within [maxWidth], centred, with a
/// minimum [gutter] on each side. Use it as the side padding of a screen or
/// sliver:
///
/// ```dart
/// SliverPadding(padding: EdgeInsets.symmetric(horizontal: pageInset(context)))
/// ```
double pageInset(
  BuildContext context, {
  double gutter = 16,
  double maxWidth = kMaxContentWidth,
}) {
  final width = context.contentWidth;
  final extra = (width - maxWidth) / 2;
  return extra > gutter ? extra : gutter;
}

/// How many columns of at least [minTileWidth] fit into [width]
/// (clamped to 1..[maxColumns]).
int gridColumns(
  double width, {
  double minTileWidth = 320,
  int maxColumns = 4,
  double spacing = 12,
}) {
  final n = ((width + spacing) / (minTileWidth + spacing)).floor();
  return n.clamp(1, maxColumns);
}

/// Centres [child] and limits it to [maxWidth]. For non-sliver screens.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
