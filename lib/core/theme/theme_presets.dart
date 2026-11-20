import 'package:flutter/material.dart';

/// All available colour presets for the app theme.
///
/// [dynamic] uses the system wallpaper colours via the `dynamic_color`
/// package. Its [seedColor] is only a placeholder; the theme falls back to
/// Sakura when the device doesn't support dynamic colour.
///
/// [variant] controls how `ColorScheme.fromSeed` derives the palette. The
/// default (tonalSpot) mutes the seed, so Mono uses `monochrome` to stay grey.
/// Try `DynamicSchemeVariant.vibrant` on any preset that looks duller than
/// its swatch.
///
/// [custom] takes its seed from the user's picked colour; its [seedColor]
/// is only a placeholder. It is last in the list on purpose, so indexes saved
/// for the other presets don't shift.
enum AppColorPreset {
  sakuraPink(
    'Sakura',
    Color(0xFFFF1493),
    Color(0xFFFF5CA8),
    variant: DynamicSchemeVariant.vibrant,
  ),
  dynamic('Dynamic', Color(0xFF6750A4), Color(0xFF625B71)),
  catppuccin('Catppuccin', Color(0xFFCBA6F7), Color(0xFFF5C2E7)),
  greenApple('Green Apple', Color(0xFF4CAF50), Color(0xFF8BC34A)),
  midnightDusk('Midnight Dusk', Color(0xFFF02475), Color(0xFF7A1FA0)),
  nord('Nord', Color(0xFF88C0D0), Color(0xFF81A1C1)),
  strawberryDaiquiri('Strawberry', Color(0xFFED4A65), Color(0xFFFF6B81)),
  tako('Tako', Color(0xFFF3B375), Color(0xFF73D3C5)),
  tealTurquoise('Teal', Color(0xFF009688), Color(0xFF00BCD4)),
  tidalWave('Tidal Wave', Color(0xFF1565C0), Color(0xFF42A5F5)),
  yinYang('Yin & Yang', Color(0xFF607D8B), Color(0xFF90A4AE)),
  yotsuba('Yotsuba', Color(0xFFE45A28), Color(0xFFFF7043)),
  monochrome(
    'Mono',
    Color(0xFF757575),
    Color(0xFF9E9E9E),
    variant: DynamicSchemeVariant.monochrome,
  ),
  custom('Custom', Color(0xFF6750A4), Color(0xFF625B71));

  const AppColorPreset(
    this.label,
    this.seedColor,
    this.accentColor, {
    this.variant = DynamicSchemeVariant.tonalSpot,
  });

  final String label;
  final Color seedColor;
  final Color accentColor;
  final DynamicSchemeVariant variant;
}
