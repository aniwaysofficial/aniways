import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aniways/providers/theme_provider.dart';

/// The few colours the UI actually needs from a cover.
class CoverPalette {
  const CoverPalette({
    required this.accent,
    required this.muted,
    required this.onAccent,
  });

  final Color accent; // vibrant, for glows, badges, buttons
  final Color muted; // dark muted, for backgrounds
  final Color onAccent; // readable text on [accent]

  /// Returns an accessible version of [accent] tuned for [isDark] theme mode.
  Color accentFor({required bool isDark, Color? fallback}) {
    return ensureAccessibleAccent(accent, isDark: isDark, fallback: fallback);
  }
}

/// Ensures [accent] is vibrant, colorful, and clearly readable in the given [isDark] mode.
///
/// In dark mode:
/// - Guarantees minimum lightness (0.58–0.74) so icons, badges, and glows never turn black
///   or muddy against dark backgrounds.
/// - If the colour is achromatic (pure black, dark grey, or near-white with no saturation),
///   it falls back to [fallback] rather than using a dead grey/black accent.
///
/// In light mode:
/// - Guarantees maximum lightness (0.30–0.48) so text and icons maintain strong
///   contrast against white/light surfaces.
Color ensureAccessibleAccent(
  Color accent, {
  required bool isDark,
  Color? fallback,
}) {
  final hsl = HSLColor.fromColor(accent);

  // If the color is essentially grayscale / black / white (saturation < 0.12),
  // a monochrome accent makes icons disappear or look dead.
  // Fall back to the theme's primary color if available.
  if (hsl.saturation < 0.12 && (hsl.lightness < 0.25 || hsl.lightness > 0.85)) {
    if (fallback != null) {
      final fallbackHsl = HSLColor.fromColor(fallback);
      if (fallbackHsl.saturation >= 0.12) {
        return ensureAccessibleAccent(
          fallback,
          isDark: isDark,
        );
      }
    }
  }

  if (isDark) {
    // In dark mode: ensure minimum lightness and vivid saturation.
    final targetLightness = hsl.lightness.clamp(0.58, 0.74);
    final targetSaturation = (hsl.saturation * 1.25).clamp(0.35, 1.0);
    return hsl
        .withLightness(targetLightness)
        .withSaturation(targetSaturation)
        .toColor();
  } else {
    // In light mode: ensure maximum lightness so it has strong contrast against light surfaces.
    final targetLightness = hsl.lightness.clamp(0.30, 0.48);
    final targetSaturation = (hsl.saturation * 1.15).clamp(0.40, 1.0);
    return hsl
        .withLightness(targetLightness)
        .withSaturation(targetSaturation)
        .toColor();
  }
}

/// Gives [builder] the anime cover's theme accent color based directly on
/// AniList's authoritative dominant color, tuned for accessibility in dark/light mode.
/// Builds synchronously with zero pop-in, zero color shifting, and instant frame-0 rendering.
class CoverPaletteBuilder extends StatelessWidget {
  const CoverPaletteBuilder({
    super.key,
    this.url,
    required this.fallback,
    required this.builder,
  });

  final String? url;
  final Color fallback;
  final Widget Function(BuildContext context, Color accent, CoverPalette? p)
  builder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider?>();
    final useCoverColor = themeProvider?.useCoverColorAccent ?? true;

    final primary = Theme.of(context).colorScheme.primary;
    final effectiveBaseColor = useCoverColor ? fallback : primary;

    final effectiveAccent = ensureAccessibleAccent(
      effectiveBaseColor,
      isDark: isDark,
      fallback: primary,
    );
    final onAccent =
        ThemeData.estimateBrightnessForColor(effectiveAccent) == Brightness.dark
            ? Colors.white
            : Colors.black;

    final palette = CoverPalette(
      accent: effectiveAccent,
      muted: effectiveAccent,
      onAccent: onAccent,
    );

    return builder(context, effectiveAccent, palette);
  }
}
