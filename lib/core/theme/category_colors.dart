import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Accent colours for settings categories (icons + their tinted boxes).
///
/// - Themes whose scheme is naturally multi-hued (seeded presets, wallpaper
///   dynamic colour) derive them from the scheme, so they follow the theme.
/// - Sakura forces primary/secondary/tertiary to pink shades, so it uses the
///   [fixed] palette to keep categories distinguishable.
///
/// Read with `CategoryColors.of(context)`.
@immutable
class CategoryColors extends ThemeExtension<CategoryColors> {
  const CategoryColors({
    required this.appearance,
    required this.playback,
    required this.accounts,
    required this.downloads,
    required this.backup,
  });

  final Color appearance;
  final Color playback;
  final Color accounts;
  final Color downloads;
  final Color backup;

  /// Used by Sakura (and as a safe fallback if the extension is missing).
  static const fixed = CategoryColors(
    appearance: Color(0xFF8E6CFF), // violet
    playback: Color(0xFFFF5252), // coral red
    accounts: Color(0xFF3D8BFF), // blue
    downloads: Color(0xFFFF9800), // orange
    backup: Color(0xFF1DB98A), // green-teal
  );

  /// Derives the palette from a scheme. Downloads has no matching role, so it
  /// uses orange harmonized toward the scheme's primary (the standard M3
  /// approach for custom semantic colours).
  factory CategoryColors.fromScheme(
    ColorScheme scheme, {
    bool monochrome = false,
  }) {
    return CategoryColors(
      appearance: scheme.primary,
      playback: monochrome
          ? scheme.outline
          : const Color(0xFFFF5252).harmonizeWith(scheme.primary),
      accounts: scheme.secondary,
      backup: scheme.tertiary,
      downloads: monochrome
          ? scheme.outline
          : const Color(0xFFFF9800).harmonizeWith(scheme.primary),
    );
  }

  static CategoryColors of(BuildContext context) =>
      Theme.of(context).extension<CategoryColors>() ?? fixed;

  @override
  CategoryColors copyWith({
    Color? appearance,
    Color? playback,
    Color? accounts,
    Color? downloads,
    Color? backup,
  }) {
    return CategoryColors(
      appearance: appearance ?? this.appearance,
      playback: playback ?? this.playback,
      accounts: accounts ?? this.accounts,
      downloads: downloads ?? this.downloads,
      backup: backup ?? this.backup,
    );
  }

  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) {
    if (other is! CategoryColors) return this;
    return CategoryColors(
      appearance: Color.lerp(appearance, other.appearance, t)!,
      playback: Color.lerp(playback, other.playback, t)!,
      accounts: Color.lerp(accounts, other.accounts, t)!,
      downloads: Color.lerp(downloads, other.downloads, t)!,
      backup: Color.lerp(backup, other.backup, t)!,
    );
  }
}
