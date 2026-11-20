import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Bouncing scroll with a capped fling speed, so a hard flick doesn't send
/// the list flying.
class AppScrollPhysics extends BouncingScrollPhysics {
  const AppScrollPhysics({super.parent});

  @override
  AppScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      AppScrollPhysics(parent: buildParent(ancestor));

  /// Hard cap on how fast a flick can be.
  @override
  double get maxFlingVelocity => 3000;

  /// Fraction of the release velocity that carries into the glide.
  /// Lower = shorter glide. 1.0 is stock iOS behavior.
  static const double _flingDamping = 0.8;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Only damp normal gliding. While overscrolled, the bounce-back spring
    // keeps its original velocity so it doesn't feel mushy.
    final v = position.outOfRange ? velocity : velocity * _flingDamping;
    return super.createBallisticSimulation(position, v);
  }
}

/// App-wide scroll behavior. Set it once on the app:
///
/// ```dart
/// MaterialApp(scrollBehavior: const AppScrollBehavior(), ...)
/// ```
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  /// Lets lists and carousels be dragged with a mouse or trackpad too (by
  /// default Flutter only allows touch on desktop).
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  /// AlwaysScrollable keeps pull-to-refresh working on short content.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const AppScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  /// The bounce replaces the Android glow/stretch indicator.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
