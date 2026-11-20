import 'package:flutter/material.dart';
import 'package:aniways/core/theme/theme_presets.dart';
import 'package:aniways/core/theme/category_colors.dart';

/// Centralised theme builder for the app.
///
/// Every preset goes through the same path:
///
/// 1. `ColorScheme.fromSeed` derives a full M3 tonal palette (every surface
///    container tone is populated).
/// 2. Sakura Pink overlays its hand-picked brand colours on top of that.
/// 3. When dynamic colour is active and the device supports it (Android 12+),
///    the wallpaper accent colours are overlaid instead.
/// 4. Optional pure-black (AMOLED) surfaces are applied in dark mode.
class AppTheme {
  AppTheme._();

  // ── Brand Colours ────────────────────────────────────────────────────
  static const Color primaryPink = Color(0xFFFF1493); // hot pink
  static const Color accentPink = Color(0xFFFF5CA8); // lighter companion
  static const Color deepPink = Color(0xFFC71585); // deeper magenta-pink

  // ── Scheme building ─────────────────────────────────────────────────

  static ColorScheme _buildScheme({
    required AppColorPreset preset,
    required Brightness brightness,
    ColorScheme? dynamicScheme,
    Color? customSeed,
    DynamicSchemeVariant? styleOverride,
    double contrastLevel = 0.0,
  }) {
    final seedColor =
        dynamicScheme?.primary ??
        (preset == AppColorPreset.custom
            ? (customSeed ?? preset.seedColor)
            : preset.seedColor);

    // Wallpaper colours always use the standard variant, Mono always stays
    // grey, and everything else honours the user's palette-style choice.
    final variant = dynamicScheme != null
        ? DynamicSchemeVariant.tonalSpot
        : preset.variant == DynamicSchemeVariant.monochrome
        ? DynamicSchemeVariant.monochrome
        : (styleOverride ?? preset.variant);

    final seeded = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: variant,
      contrastLevel: contrastLevel,
    );

    // Overlay wallpaper accents onto the fully-seeded scheme so surfaces
    // are always populated even when the dynamic scheme has gaps. The OS
    // fixes those accents at standard contrast, so when the user asks for
    // more contrast we skip the overlay and keep the re-seeded scheme
    // (built from the wallpaper's primary) instead.
    if (dynamicScheme != null && contrastLevel == 0.0) {
      return seeded.copyWith(
        primary: dynamicScheme.primary,
        onPrimary: dynamicScheme.onPrimary,
        primaryContainer: dynamicScheme.primaryContainer,
        onPrimaryContainer: dynamicScheme.onPrimaryContainer,
        secondary: dynamicScheme.secondary,
        onSecondary: dynamicScheme.onSecondary,
        secondaryContainer: dynamicScheme.secondaryContainer,
        onSecondaryContainer: dynamicScheme.onSecondaryContainer,
        tertiary: dynamicScheme.tertiary,
        onTertiary: dynamicScheme.onTertiary,
        tertiaryContainer: dynamicScheme.tertiaryContainer,
        onTertiaryContainer: dynamicScheme.onTertiaryContainer,
        error: dynamicScheme.error,
        onError: dynamicScheme.onError,
        errorContainer: dynamicScheme.errorContainer,
        onErrorContainer: dynamicScheme.onErrorContainer,
      );
    }

    // Sakura keeps its hand-picked brand colours.
    if (dynamicScheme == null && preset == AppColorPreset.sakuraPink) {
      return seeded.copyWith(
        primary: preset.seedColor,
        onPrimary: Colors.white,
        secondary: preset.accentColor,
        onSecondary: Colors.white,
        tertiary: deepPink,
        onTertiary: Colors.white,
      );
    }

    return seeded;
  }

  static ThemeData _buildThemeFromScheme(
    ColorScheme scheme,
    CategoryColors categories,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
        actionTextColor: scheme.primary,
      ),
      extensions: [categories],
    );
  }

  /// Pure-black surfaces. `surfaceContainerHighest` is intentionally left
  /// alone so the nav pill and cards still stand out against the black.
  static ColorScheme _applyPureBlack(ColorScheme scheme) {
    return scheme.copyWith(
      surface: const Color(0xFF000000),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF121212),
      surfaceContainerHigh: const Color(0xFF1A1A1A),
    );
  }

  static ThemeData _generate({
    required ColorScheme? dynamicColorScheme,
    required bool useDynamic,
    required AppColorPreset preset,
    required Brightness brightness,
    bool pureBlack = false,
    Color? customColor,
    DynamicSchemeVariant? paletteStyle,
    double contrastLevel = 0.0,
  }) {
    // Dynamic colour is on if the switch is on OR the Dynamic preset is picked.
    final wantsDynamic = useDynamic || preset == AppColorPreset.dynamic;
    final dynamicScheme = wantsDynamic ? dynamicColorScheme : null;

    // Dynamic preset on a device without support → fall back to Sakura.
    final effective =
        (preset == AppColorPreset.dynamic && dynamicScheme == null)
        ? AppColorPreset.sakuraPink
        : preset;

    var scheme = _buildScheme(
      preset: effective,
      brightness: brightness,
      dynamicScheme: dynamicScheme,
      customSeed: customColor,
      styleOverride: paletteStyle,
      contrastLevel: contrastLevel,
    );
    if (pureBlack && brightness == Brightness.dark) {
      scheme = _applyPureBlack(scheme);
    }
    final useFixedAccents =
        dynamicScheme == null && effective == AppColorPreset.sakuraPink;

    final categories = useFixedAccents
        ? CategoryColors.fixed
        : CategoryColors.fromScheme(
            scheme,
            monochrome: effective.variant == DynamicSchemeVariant.monochrome,
          );

    return _buildThemeFromScheme(scheme, categories);
  }

  // ── Public API ──────────────────────────────────────────────────────

  static ThemeData generateLightTheme({
    required ColorScheme? dynamicColorScheme,
    required bool useDynamic,
    required AppColorPreset preset,
    Color? customColor,
    DynamicSchemeVariant? paletteStyle,
    double contrastLevel = 0.0,
  }) {
    return _generate(
      dynamicColorScheme: dynamicColorScheme,
      useDynamic: useDynamic,
      preset: preset,
      brightness: Brightness.light,
      customColor: customColor,
      paletteStyle: paletteStyle,
      contrastLevel: contrastLevel,
    );
  }

  static ThemeData generateDarkTheme({
    required ColorScheme? dynamicColorScheme,
    required bool useDynamic,
    required bool pureBlack,
    required AppColorPreset preset,
    Color? customColor,
    DynamicSchemeVariant? paletteStyle,
    double contrastLevel = 0.0,
  }) {
    return _generate(
      dynamicColorScheme: dynamicColorScheme,
      useDynamic: useDynamic,
      preset: preset,
      brightness: Brightness.dark,
      pureBlack: pureBlack,
      customColor: customColor,
      paletteStyle: paletteStyle,
      contrastLevel: contrastLevel,
    );
  }

  /// Scheme for a preset, built through the same path as the real theme.
  /// Used by the appearance screen's palette previews.
  static ColorScheme previewScheme({
    required AppColorPreset preset,
    required Brightness brightness,
    ColorScheme? dynamicScheme,
    Color? customSeed,
    DynamicSchemeVariant? styleOverride,
    double contrastLevel = 0.0,
  }) {
    return _buildScheme(
      preset: preset,
      brightness: brightness,
      dynamicScheme: dynamicScheme,
      customSeed: customSeed,
      styleOverride: styleOverride,
      contrastLevel: contrastLevel,
    );
  }
}
