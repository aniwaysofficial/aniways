import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/navigation/main_navigation.dart'
    show MainNavigation, NavBarScope, kNavBarBottomMargin, kNavBarHeight;

/// Visual variant for [AniwaysSnackBar].
enum AniwaysSnackBarVariant {
  info,
  success,
  error,
}

/// A One UI styled floating snackbar designed for Aniways.
///
/// Features:
/// - Matches the active dynamic or preset theme colors with rounded pill styling.
/// - Automatically integrates with Flutter Scaffold's floating snackbar layout,
///   positioning cleanly above the nav bar pill or above the system gesture inset.
/// - Dynamically shifts upward in real-time when returning from child routes to
///   screens where the floating nav bar pill becomes visible.
/// - Constrains max width on wide tablet and desktop displays so it appears as a centered toast.
/// - Built-in haptic feedback and icon badges.
class AniwaysSnackBar {
  AniwaysSnackBar._();

  /// Calculates the floating bottom margin.
  ///
  /// The base margin sits 12px above the system gesture inset. Nav bar clearance
  /// is dynamically animated via [MainNavigation.navPillVisible] inside [create].
  /// If [hasBottomNavBar] is explicitly true, the full clearance is included.
  static double calculateBottomMargin(
    BuildContext context, {
    bool? hasBottomNavBar,
    double extraBottomMargin = 0.0,
  }) {
    final effectiveHasNavBar =
        hasBottomNavBar ?? NavBarScope.hasNavBar(context);
    if (effectiveHasNavBar) {
      return kNavBarHeight + kNavBarBottomMargin + 12.0 + extraBottomMargin;
    }
    return 12.0 + extraBottomMargin;
  }

  /// Calculates margins (left, right, bottom) taking wide displays into account.
  static EdgeInsets calculateMargin(
    BuildContext context, {
    bool? hasBottomNavBar,
    double extraBottomMargin = 0.0,
  }) {
    final bottom = calculateBottomMargin(
      context,
      hasBottomNavBar: hasBottomNavBar,
      extraBottomMargin: extraBottomMargin,
    );
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Centered pill on tablets/desktop
    if (screenWidth > 600) {
      final hMargin = (screenWidth - 460) / 2;
      return EdgeInsets.fromLTRB(hMargin, 0, hMargin, bottom);
    }

    return EdgeInsets.fromLTRB(16, 0, 16, bottom);
  }

  /// Creates a styled [SnackBar] ready to be passed to [ScaffoldMessenger].
  static SnackBar create(
    BuildContext context, {
    required String message,
    AniwaysSnackBarVariant variant = AniwaysSnackBarVariant.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool? hasBottomNavBar,
    double extraBottomMargin = 0.0,
    Color? customAccent,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color accentColor = customAccent ??
        switch (variant) {
          AniwaysSnackBarVariant.error => cs.error,
          AniwaysSnackBarVariant.success => cs.primary,
          AniwaysSnackBarVariant.info => cs.primary,
        };

    final isPureBlack = isDark &&
        (cs.surface == const Color(0xFF000000) ||
            theme.scaffoldBackgroundColor == const Color(0xFF000000));

    final Color bg = isPureBlack
        ? Color.alphaBlend(
            accentColor.withValues(
              alpha: variant == AniwaysSnackBarVariant.error ? 0.20 : 0.14,
            ),
            const Color(0xFF16161A),
          )
        : isDark
            ? Color.alphaBlend(
                accentColor.withValues(
                  alpha: variant == AniwaysSnackBarVariant.error ? 0.18 : 0.12,
                ),
                const Color(0xFF222226),
              )
            : Color.alphaBlend(
                accentColor.withValues(
                  alpha: variant == AniwaysSnackBarVariant.error ? 0.12 : 0.08,
                ),
                cs.surfaceContainerHighest,
              );

    final Color borderColor = Color.alphaBlend(
      accentColor.withValues(
        alpha: isDark
            ? (variant == AniwaysSnackBarVariant.error ? 0.45 : 0.35)
            : 0.28,
      ),
      cs.outlineVariant,
    ).withValues(alpha: isDark ? 0.50 : 0.40);

    final effectiveIcon = icon ??
        switch (variant) {
          AniwaysSnackBarVariant.error => Icons.error_outline_rounded,
          AniwaysSnackBarVariant.success => Icons.check_circle_rounded,
          AniwaysSnackBarVariant.info => null,
        };

    final effectiveDuration = duration ??
        (actionLabel != null
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 2600));

    final inheritedHasNavBar = NavBarScope.hasNavBar(context);

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.none,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        side: BorderSide.none,
      ),
      clipBehavior: Clip.none,
      margin: calculateMargin(
        context,
        hasBottomNavBar: false,
        extraBottomMargin: extraBottomMargin,
      ),
      padding: EdgeInsets.zero,
      duration: effectiveDuration,
      content: ValueListenableBuilder<bool>(
        valueListenable: MainNavigation.navPillVisible,
        builder: (ctx, pillVisible, child) {
          final isKeyboardOpen = MediaQuery.viewInsetsOf(ctx).bottom > 0;
          final effectivePillVisible =
              (hasBottomNavBar ?? (inheritedHasNavBar || pillVisible)) &&
                  !isKeyboardOpen;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 240),
            curve: Curves.fastOutSlowIn,
            padding: EdgeInsets.only(
              bottom: effectivePillVisible
                  ? (kNavBarHeight + kNavBarBottomMargin)
                  : 0.0,
            ),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (effectiveIcon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.20 : 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    effectiveIcon,
                    size: 17,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Displays an informational or standard message.
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool? hasBottomNavBar,
    double extraBottomMargin = 0.0,
    Color? customAccent,
  }) {
    HapticFeedback.lightImpact();
    final snackBar = create(
      context,
      message: message,
      variant: AniwaysSnackBarVariant.info,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      hasBottomNavBar: hasBottomNavBar,
      extraBottomMargin: extraBottomMargin,
      customAccent: customAccent,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Displays a success message.
  static void success(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool? hasBottomNavBar,
    double extraBottomMargin = 0.0,
    Color? customAccent,
  }) {
    HapticFeedback.lightImpact();
    final snackBar = create(
      context,
      message: message,
      variant: AniwaysSnackBarVariant.success,
      icon: icon ?? Icons.check_circle_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      hasBottomNavBar: hasBottomNavBar,
      extraBottomMargin: extraBottomMargin,
      customAccent: customAccent,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Displays an error or warning message.
  static void error(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool? hasBottomNavBar,
    double extraBottomMargin = 0.0,
    Color? customAccent,
  }) {
    HapticFeedback.mediumImpact();
    final snackBar = create(
      context,
      message: message,
      variant: AniwaysSnackBarVariant.error,
      icon: icon ?? Icons.error_outline_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      hasBottomNavBar: hasBottomNavBar,
      extraBottomMargin: extraBottomMargin,
      customAccent: customAccent,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Displays an info message.
  static void info(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool? hasBottomNavBar,
    double extraBottomMargin = 0.0,
    Color? customAccent,
  }) {
    HapticFeedback.lightImpact();
    final snackBar = create(
      context,
      message: message,
      variant: AniwaysSnackBarVariant.info,
      icon: icon ?? Icons.info_outline_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      hasBottomNavBar: hasBottomNavBar,
      extraBottomMargin: extraBottomMargin,
      customAccent: customAccent,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

/// Convenience top-level helper for showing a [AniwaysSnackBar].
void showAniwaysSnackBar(
  BuildContext context, {
  required String message,
  AniwaysSnackBarVariant variant = AniwaysSnackBarVariant.info,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
  bool? hasBottomNavBar,
  double extraBottomMargin = 0.0,
  Color? customAccent,
}) {
  switch (variant) {
    case AniwaysSnackBarVariant.success:
      AniwaysSnackBar.success(
        context,
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        hasBottomNavBar: hasBottomNavBar,
        extraBottomMargin: extraBottomMargin,
        customAccent: customAccent,
      );
    case AniwaysSnackBarVariant.error:
      AniwaysSnackBar.error(
        context,
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        hasBottomNavBar: hasBottomNavBar,
        extraBottomMargin: extraBottomMargin,
        customAccent: customAccent,
      );
    case AniwaysSnackBarVariant.info:
      AniwaysSnackBar.show(
        context,
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        hasBottomNavBar: hasBottomNavBar,
        extraBottomMargin: extraBottomMargin,
        customAccent: customAccent,
      );
  }
}

