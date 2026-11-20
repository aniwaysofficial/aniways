import 'package:flutter/material.dart';
import 'package:aniways/core/constants.dart';

/// The app logo, adapting to light / dark theme and dynamic color.
/// Pass [color] to override and tint with a specific color (e.g. on containers or rails).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 36,
    this.color,
    this.monochrome = false,
  });

  final double size;
  final Color? color;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (color != null || monochrome) {
      final tint = color ?? theme.colorScheme.primary;
      return Image.asset(
        AppConstants.logoMonochrome,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: tint,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stack) =>
            Icon(Icons.play_circle_filled_rounded, size: size * 0.9, color: tint),
      );
    }

    final asset = isDark ? AppConstants.logoDark : AppConstants.logoLight;
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Icon(
        Icons.play_circle_filled_rounded,
        size: size * 0.9,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
