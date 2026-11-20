import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

/// A One UI style page: a tall header with a large title that shrinks and
/// slides next to the back button as the content scrolls.
///
/// For a plain list of widgets. For lazy content (grids, infinite lists) use
/// [OneUiSliverHeader] as the first sliver of your own `CustomScrollView`.
class OneUiScrollView extends StatelessWidget {
  const OneUiScrollView({
    super.key,
    required this.title,
    required this.children,
    this.bottomPadding = 0,
    this.horizontalPadding = 0,
    this.expandedFraction = 0.27,
    this.actions,
    this.showBackButton = true,
  });

  final String title;
  final List<Widget> children;
  final double bottomPadding;

  /// Left/right padding around the content (the header is always full width).
  final double horizontalPadding;

  /// Expanded header height as a fraction of the screen height.
  final double expandedFraction;
  final List<Widget>? actions;

  /// Set to false when the page is embedded (for example in a split-view
  /// detail pane), where a back button would make no sense.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(800),
      slivers: [
        OneUiSliverHeader(
          title: title,
          actions: actions,
          showBackButton: showBackButton,
          expandedFraction: expandedFraction,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            bottomPadding,
          ),
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    );
  }
}

/// The One UI header as a sliver: big centred title with the back button
/// below it, both sliding into the toolbar as you scroll. The single source
/// of truth for this look, used by [OneUiScrollView] and by any screen that
/// needs lazy slivers below it.
class OneUiSliverHeader extends StatelessWidget {
  const OneUiSliverHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.expandedFraction = 0.27,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  /// Expanded header height as a fraction of the screen height.
  final double expandedFraction;

  /// Optional widget displayed at the bottom of the app bar (e.g. a pinned [TabBar]).
  final PreferredSizeWidget? bottom;

  static const double _expandedFontSize = 34;
  static const double _collapsedFontSize = 20;
  static const double _toolbarHeight = kToolbarHeight;
  static const double _sidePadding = 24;
  static const double _buttonSize = 48;
  static const double _backGap = 8;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    final expandedHeight = (screenHeight * expandedFraction + bottomHeight)
        .clamp(180.0 + bottomHeight, 300.0 + bottomHeight);

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      toolbarHeight: _toolbarHeight,
      bottom: bottom,
      automaticallyImplyLeading: false, // back button is drawn below
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      actions: actions, // stay in the top toolbar row
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = MediaQuery.paddingOf(context).top;
          final range = expandedHeight - _toolbarHeight - bottomHeight;
          // 1 = fully expanded, 0 = fully collapsed. Quantized to reduce layout churn.
          final rawT = range <= 0
              ? 0.0
              : ((constraints.maxHeight - top - _toolbarHeight - bottomHeight) /
                        range)
                    .clamp(0.0, 1.0);
          final t = (rawT * 30).roundToDouble() / 30.0;

          final fontSize = _lerp(_collapsedFontSize, _expandedFontSize, t);
          final fontWeight =
              FontWeight.lerp(FontWeight.w600, FontWeight.w700, t) ??
              FontWeight.w700;
          final letterSpacing = _lerp(-0.3, -0.5, t);

          // Back button: bottom-left of the expanded header (above bottom widget),
          // moves up into the toolbar row when collapsed.
          final backExpandedTop =
              top + expandedHeight - bottomHeight - _buttonSize - _backGap;
          final backCollapsedTop = top + (_toolbarHeight - _buttonSize) / 2;
          final backTop = _lerp(backCollapsedTop, backExpandedTop, t);

          // Title: centred in the free space between the status bar and the
          // back button when expanded; in the toolbar row when collapsed.
          final titleExpandedY = (top + backExpandedTop + 35) / 2;
          final titleCollapsedY = top + _toolbarHeight / 2;
          final titleY = _lerp(titleCollapsedY, titleExpandedY, t);

          return RepaintBoundary(
            child: Stack(
              children: [
                Positioned(
                  top: titleY - 24,
                  left: _sidePadding,
                  right: _sidePadding,
                  height: 48,
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        letterSpacing: letterSpacing,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                if (showBackButton && Navigator.of(context).canPop())
                  Positioned(top: backTop, left: 8, child: const BackButton()),
              ],
            ),
          );
        },
      ),
    );
  }
}
