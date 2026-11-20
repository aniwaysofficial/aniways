import 'dart:math' as math;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/app_theme.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/theme/theme_presets.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/providers/theme_provider.dart';
import 'package:aniways/core/theme/custom_color_sheet.dart';
import 'package:aniways/screens/settings/settings_components.dart';

/// Widest the settings column gets on tablets and desktop. It stays on the
/// left, like on a phone.
const double _maxContentWidth = 560;

/// Widest a group of preview thumbnails gets, so they stay about phone-sized
/// instead of growing with the screen.
const double _maxPreviewsWidth = 440;

/// Available width (inside the tile) at which palette styles switch from a
/// 3x2 grid to a single row.
const double _styleRowBreakpoint = 560;

/// Widest the single-row palette styles get.
const double _maxStyleRowWidth = 720;

/// Side padding for the narrower parts (Theme mode): 16 on the left, and on
/// wide areas enough on the right to stop at [_maxContentWidth]. It measures
/// the space it is actually given, so it also works inside a split-view pane.
class _SidePadded extends StatelessWidget {
  const _SidePadded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final right = constraints.maxWidth - 16 - _maxContentWidth;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, right > 16 ? right : 16, 0),
          child: child,
        );
      },
    );
  }
}

/// Screen for customizing the app's theme mode, colors, and AMOLED mode.
///
/// Set [embedded] when it is shown inside another screen (the split-view
/// detail pane on wide layouts): the back button is hidden.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final cat = CategoryColors.of(context);
    final p = context.watch<ThemeProvider>();

    final isSystemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isCurrentlyDark =
        p.appTheme == AppThemeMode.dark ||
        (p.appTheme == AppThemeMode.auto && isSystemDark);

    // Dynamic colour is active if the switch is on OR the Dynamic preset is
    // picked (same rule AppTheme uses). The UI treats them as one thing.
    final dynamicActive =
        p.dynamicTheme || p.colorPreset == AppColorPreset.dynamic;
    final selectedPreset = dynamicActive
        ? AppColorPreset.dynamic
        : p.colorPreset;

    // Palette style doesn't apply to wallpaper colours or Mono.
    final isMono = !dynamicActive && p.colorPreset == AppColorPreset.monochrome;
    final styleLocked = dynamicActive || isMono;
    final styleSubtitle = dynamicActive
        ? 'Wallpaper colors use their own style'
        : isMono
        ? 'Mono always stays grey'
        : 'How the palette is built from its seed color';

    return Scaffold(
      // Horizontal padding is applied per section so the palette carousel
      // can scroll edge to edge.
      body: OneUiScrollView(
        title: 'Appearance',
        showBackButton: !embedded,
        // This screen sits above the nav bar, so no pill clearance needed.
        bottomPadding: MediaQuery.viewPaddingOf(context).bottom + 16,
        children: [
          // ── Theme mode ─────────────────────────────────────────────
          const _SidePadded(child: SettingsSectionHeader('Theme mode')),
          _SidePadded(
            child: _ThemeModeSelector(
              selected: p.appTheme,
              onSelected: p.setAppTheme,
              pureBlack: p.pureBlack,
            ),
          ),
          const SizedBox(height: 24),

          // ── Options ────────────────────────────────────────────────
          const SettingsSectionHeader('Options'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.wallpaper_rounded,
                  color: cat.appearance,
                  title: 'Dynamic color',
                  subtitle: 'Use colors from your wallpaper (Android 12+)',
                  value: dynamicActive,
                  isFirst: true,
                  isLast: false,
                  onChanged: (value) {
                    p.setDynamicTheme(value);
                    // Turning dynamic off while the Dynamic preset is selected
                    // would leave it "on", so move to the default preset.
                    if (!value && p.colorPreset == AppColorPreset.dynamic) {
                      p.setColorPreset(AppColorPreset.sakuraPink);
                    }
                  },
                ),
                const SizedBox(height: 2),
                SettingsSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  color: cat.accounts,
                  title: 'Pure black',
                  subtitle: isCurrentlyDark
                      ? 'Enable for true black theme'
                      : 'Switch to a dark theme to use pure black',
                  value: p.pureBlack,
                  isFirst: false,
                  isLast: false,
                  onChanged: isCurrentlyDark ? p.setPureBlack : null,
                ),
                const SizedBox(height: 2),
                SettingsSwitchTile(
                  icon: Icons.palette_outlined,
                  color: cat.backup,
                  title: 'Cover color accent',
                  subtitle: 'Use anime cover colors in info and watch screens',
                  value: p.useCoverColorAccent,
                  isFirst: false,
                  isLast: true,
                  onChanged: p.setUseCoverColorAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Color palette ──────────────────────────────────────────
          const _SidePadded(child: SettingsSectionHeader('Color palette')),
          _PaletteCarousel(
            selected: selectedPreset,
            customColor: p.customColor,
            styleOverride: p.paletteStyle,
            contrastLevel: p.contrastLevel,
            onSelected: (preset) async {
              if (preset == AppColorPreset.custom) {
                // Custom always opens the picker; Cancel leaves things as-is.
                final picked = await showCustomColorSheet(
                  context,
                  initial: p.customColor,
                );
                if (picked == null) return;
                p.setCustomColor(picked);
              }
              if (preset == AppColorPreset.dynamic) {
                p.setDynamicTheme(true);
              } else if (p.dynamicTheme) {
                // Picking a fixed palette means leaving dynamic colour,
                // otherwise the tap would appear to do nothing.
                p.setDynamicTheme(false);
              }
              p.setColorPreset(preset);
            },
          ),
          const SizedBox(height: 24),

          // ── Fine-tuning ────────────────────────────────────────────
          const SettingsSectionHeader('Fine-tuning'),
          _FineTuning(
            preset: selectedPreset,
            customColor: p.customColor,
            contrastLevel: p.contrastLevel,
            onContrastChanged: p.setContrastLevel,
            paletteStyle: p.paletteStyle,
            onPaletteStyleChanged: p.setPaletteStyle,
            styleLocked: styleLocked,
            styleSubtitle: styleSubtitle,
            contrastColor: cat.downloads,
            styleColor: cat.backup,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Building blocks
// ═════════════════════════════════════════════════════════════════════════

/// Caps the width of a group of preview thumbnails, keeping it on the left.
class _PreviewsWidth extends StatelessWidget {
  const _PreviewsWidth({
    required this.child,
    this.maxWidth = _maxPreviewsWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Mini app preview (shared by theme mode + palette)
// ═════════════════════════════════════════════════════════════════════════

/// A tiny fake app screen painted with [scheme]. Drawn at a fixed logical
/// size and scaled to fit, so it looks identical at any thumbnail size.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.scheme});

  final ColorScheme scheme;

  static const double _w = 100;
  static const double _h = 132;

  @override
  Widget build(BuildContext context) {
    final s = scheme;

    Widget bar(Color color, double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height),
      ),
    );

    Widget pill(Color color) => Container(
      width: 26,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
    );

    Widget row() => Container(
      height: 14,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: s.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: s.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          bar(s.onSurfaceVariant.withValues(alpha: 0.5), 30, 3),
        ],
      ),
    );

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _w,
        height: _h,
        child: ColoredBox(
          color: s.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(s.onSurface.withValues(alpha: 0.75), 34, 5),
                    const SizedBox(height: 8),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.all(6),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: s.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: bar(
                        s.onPrimaryContainer.withValues(alpha: 0.7),
                        22,
                        4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        pill(s.secondaryContainer),
                        const SizedBox(width: 4),
                        pill(s.tertiaryContainer),
                      ],
                    ),
                    const SizedBox(height: 6),
                    row(),
                    row(),
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: s.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 13,
                      color: s.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.background});

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 13, color: Colors.white),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Theme mode: mini preview thumbnails
// ═════════════════════════════════════════════════════════════════════════

class _DiagonalClipper extends CustomClipper<Path> {
  /// Keeps the bottom-right triangle (the "dark" half of System).
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.selected,
    required this.onSelected,
    required this.pureBlack,
  });

  final AppThemeMode selected;
  final ValueChanged<AppThemeMode> onSelected;
  final bool pureBlack;

  static const _modes = [
    (mode: AppThemeMode.auto, label: 'System'),
    (mode: AppThemeMode.light, label: 'Light'),
    (mode: AppThemeMode.dark, label: 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Previews follow the current accent so they match the real theme.
    final light = ColorScheme.fromSeed(
      seedColor: cs.primary,
      brightness: Brightness.light,
    );
    var dark = ColorScheme.fromSeed(
      seedColor: cs.primary,
      brightness: Brightness.dark,
    );
    if (pureBlack) {
      dark = dark.copyWith(
        surface: const Color(0xFF000000),
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF121212),
        surfaceContainerHigh: const Color(0xFF1A1A1A),
      );
    }

    Widget previewFor(AppThemeMode mode) {
      if (mode == AppThemeMode.light) return _MiniScreen(scheme: light);
      if (mode == AppThemeMode.dark) return _MiniScreen(scheme: dark);
      return Stack(
        fit: StackFit.expand,
        children: [
          _MiniScreen(scheme: light),
          ClipPath(
            clipper: _DiagonalClipper(),
            child: _MiniScreen(scheme: dark),
          ),
        ],
      );
    }

    return _PreviewsWidth(
      child: Row(
        children: [
          for (var i = 0; i < _modes.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _ThemeModeTile(
                label: _modes[i].label,
                isSelected: selected == _modes[i].mode,
                onTap: () => onSelected(_modes[i].mode),
                preview: previewFor(_modes[i].mode),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.preview,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label theme',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio: _MiniScreen._w / _MiniScreen._h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: preview,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Color palette: horizontal carousel of mini app previews
// ═════════════════════════════════════════════════════════════════════════

class _PaletteCarousel extends StatefulWidget {
  const _PaletteCarousel({
    required this.selected,
    required this.onSelected,
    required this.customColor,
    required this.styleOverride,
    required this.contrastLevel,
  });

  final AppColorPreset selected;
  final ValueChanged<AppColorPreset> onSelected;
  final Color customColor;
  final DynamicSchemeVariant? styleOverride;
  final double contrastLevel;

  @override
  State<_PaletteCarousel> createState() => _PaletteCarouselState();
}

class _PaletteCarouselState extends State<_PaletteCarousel> {
  static const double _cardWidth = 114;
  static const double _gap = 12;
  static const double _height = 184;

  /// Sakura first, then the rest in declaration order.
  static final _ordered = <AppColorPreset>[
    AppColorPreset.sakuraPink,
    ...AppColorPreset.values.where((p) => p != AppColorPreset.sakuraPink),
  ];

  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    // Open with the selected palette in view.
    final index = _ordered.indexOf(widget.selected);
    final offset = math.max(0.0, index * (_cardWidth + _gap) - 16);
    _controller = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Real scheme for a preset, built through the same path as the app theme.
  ColorScheme _schemeFor(
    AppColorPreset preset,
    Brightness brightness,
    ColorScheme? dynamicScheme,
  ) {
    var effective = preset;
    ColorScheme? wallpaper;
    if (preset == AppColorPreset.dynamic) {
      if (dynamicScheme != null) {
        wallpaper = dynamicScheme;
      } else {
        // No wallpaper colours (unsupported device) → the app falls back to
        // Sakura, so the preview does too.
        effective = AppColorPreset.sakuraPink;
      }
    }
    return AppTheme.previewScheme(
      preset: effective,
      brightness: brightness,
      dynamicScheme: wallpaper,
      customSeed: widget.customColor,
      styleOverride: widget.styleOverride,
      contrastLevel: widget.contrastLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final dynamicScheme = brightness == Brightness.dark
            ? darkDynamic
            : lightDynamic;

        return SizedBox(
          height: _height,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: kSettingsHorizontalPadding,
            itemCount: _ordered.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, index) {
              final preset = _ordered[index];
              return _PaletteCard(
                width: _cardWidth,
                preset: preset,
                scheme: _schemeFor(preset, brightness, dynamicScheme),
                isSelected: preset == widget.selected,
                onTap: () => widget.onSelected(preset),
              );
            },
          ),
        );
      },
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.width,
    required this.preset,
    required this.scheme,
    required this.isSelected,
    required this.onTap,
  });

  final double width;
  final AppColorPreset preset;
  final ColorScheme scheme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDynamic = preset == AppColorPreset.dynamic;
    final isCustom = preset == AppColorPreset.custom;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${preset.label} palette',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: 2,
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: _MiniScreen._w / _MiniScreen._h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _MiniScreen(scheme: scheme),
                        if (isDynamic || isCustom)
                          Positioned(
                            left: 6,
                            top: 6,
                            child: _Badge(
                              icon: isDynamic
                                  ? Icons.wallpaper_rounded
                                  : Icons.colorize_rounded,
                              background: const Color(0x73000000),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Flexible(
                    child: Text(
                      preset.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Fine-tuning controls
// ═════════════════════════════════════════════════════════════════════════

/// Grouped tile with a header (icon, title, subtitle) and a control below.
/// Matches the shape language of [SettingsSwitchTile].
class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isFirst,
    required this.isLast,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: settingsTileBorderRadius(
          isFirst: isFirst,
          isLast: isLast,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SettingsTileIcon(icon: icon, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Fine-tuning: contrast + palette style (live previews)
// ═════════════════════════════════════════════════════════════════════════

class _FineTuning extends StatelessWidget {
  const _FineTuning({
    required this.preset,
    required this.customColor,
    required this.contrastLevel,
    required this.onContrastChanged,
    required this.paletteStyle,
    required this.onPaletteStyleChanged,
    required this.styleLocked,
    required this.styleSubtitle,
    required this.contrastColor,
    required this.styleColor,
  });

  final AppColorPreset preset;
  final Color customColor;
  final double contrastLevel;
  final ValueChanged<double> onContrastChanged;
  final DynamicSchemeVariant? paletteStyle;
  final ValueChanged<DynamicSchemeVariant?> onPaletteStyleChanged;
  final bool styleLocked;
  final String styleSubtitle;
  final Color contrastColor;
  final Color styleColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final wallpaper = brightness == Brightness.dark
            ? darkDynamic
            : lightDynamic;

        // Same path as the real theme, so every preview is what you'd get.
        ColorScheme schemeFor(DynamicSchemeVariant? style, double contrast) {
          var effective = preset;
          ColorScheme? dyn;
          if (preset == AppColorPreset.dynamic) {
            if (wallpaper != null) {
              dyn = wallpaper;
            } else {
              effective = AppColorPreset.sakuraPink;
            }
          }
          return AppTheme.previewScheme(
            preset: effective,
            brightness: brightness,
            dynamicScheme: dyn,
            customSeed: customColor,
            styleOverride: style,
            contrastLevel: contrast,
          );
        }

        return Padding(
          padding: kSettingsHorizontalPadding,
          child: Column(
            children: [
              _ControlTile(
                icon: Icons.contrast_rounded,
                color: contrastColor,
                title: 'Contrast',
                subtitle: 'Make text and controls stand out more',
                isFirst: true,
                isLast: false,
                child: _ContrastSelector(
                  value: contrastLevel,
                  onChanged: onContrastChanged,
                  schemeFor: (contrast) => schemeFor(paletteStyle, contrast),
                ),
              ),
              const SizedBox(height: 2),
              _ControlTile(
                icon: Icons.auto_awesome_rounded,
                color: styleColor,
                title: 'Palette style',
                subtitle: styleSubtitle,
                isFirst: false,
                isLast: true,
                child: _PaletteStyleSelector(
                  selected: paletteStyle,
                  enabled: !styleLocked,
                  onChanged: onPaletteStyleChanged,
                  schemeFor: (style) => schemeFor(style, contrastLevel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A framed preview with a label underneath. Selected gets a ring + check.
class _PreviewOption extends StatelessWidget {
  const _PreviewOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.aspectRatio,
    required this.child,
    this.enabled = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double aspectRatio;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: 2,
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: child,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: cs.primary,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contrast ────────────────────────────────────────────────────────────

class _ContrastSelector extends StatelessWidget {
  const _ContrastSelector({
    required this.value,
    required this.onChanged,
    required this.schemeFor,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ColorScheme Function(double contrast) schemeFor;

  static const _levels = [(0.0, 'Standard'), (0.5, 'Medium'), (1.0, 'High')];

  @override
  Widget build(BuildContext context) {
    // Snap to the nearest level in case a stored value is off-grid.
    final nearest = _levels
        .map((l) => l.$1)
        .reduce((a, b) => (a - value).abs() <= (b - value).abs() ? a : b);

    return _PreviewsWidth(
      child: Row(
        children: [
          for (var i = 0; i < _levels.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _PreviewOption(
                label: _levels[i].$2,
                isSelected: _levels[i].$1 == nearest,
                onTap: () => onChanged(_levels[i].$1),
                aspectRatio: _ContrastPreview._w / _ContrastPreview._h,
                child: _ContrastPreview(scheme: schemeFor(_levels[i].$1)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Aa" sample with a filled and an outlined control, drawn with [scheme].
class _ContrastPreview extends StatelessWidget {
  const _ContrastPreview({required this.scheme});

  final ColorScheme scheme;

  static const double _w = 100;
  static const double _h = 88;

  @override
  Widget build(BuildContext context) {
    final s = scheme;

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _w,
        height: _h,
        child: ColoredBox(
          color: s.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aa',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: s.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sample text',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.1,
                    color: s.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        'OK',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: s.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 30,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: s.outline, width: 1.2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Palette style ───────────────────────────────────────────────────────

class _PaletteStyleSelector extends StatelessWidget {
  const _PaletteStyleSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
    required this.schemeFor,
  });

  final DynamicSchemeVariant? selected;
  final bool enabled;
  final ValueChanged<DynamicSchemeVariant?> onChanged;
  final ColorScheme Function(DynamicSchemeVariant? style) schemeFor;

  /// `null` means "Auto": each preset keeps its own style.
  static const _styles = <(DynamicSchemeVariant?, String)>[
    (null, 'Auto'),
    (DynamicSchemeVariant.tonalSpot, 'Tonal'),
    (DynamicSchemeVariant.vibrant, 'Vibrant'),
    (DynamicSchemeVariant.expressive, 'Expressive'),
    (DynamicSchemeVariant.fidelity, 'Fidelity'),
    (DynamicSchemeVariant.neutral, 'Neutral'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget tile(int index) {
      final style = _styles[index];
      return Expanded(
        child: _PreviewOption(
          label: style.$2,
          isSelected: selected == style.$1,
          enabled: enabled,
          onTap: () => onChanged(style.$1),
          aspectRatio: 1.5,
          child: _PaletteSwatch(scheme: schemeFor(style.$1)),
        ),
      );
    }

    // Wide layouts get a single row; phones and narrow panes keep the 3x2 grid.
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleRow = constraints.maxWidth >= _styleRowBreakpoint;
        final columns = singleRow ? _styles.length : 3;

        return _PreviewsWidth(
          maxWidth: singleRow ? _maxStyleRowWidth : _maxPreviewsWidth,
          child: Column(
            children: [
              for (var r = 0; r < _styles.length; r += columns) ...[
                if (r > 0) const SizedBox(height: 12),
                Row(
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: 10),
                      if (r + c < _styles.length)
                        tile(r + c)
                      else
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 2x2 mosaic of the palette's key roles.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final s = scheme;

    Widget block(Color color, {int flex = 1}) => Expanded(
      flex: flex,
      child: ColoredBox(color: color, child: const SizedBox.expand()),
    );

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              block(s.primary, flex: 3),
              block(s.primaryContainer, flex: 2),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(children: [block(s.secondary), block(s.tertiary)]),
        ),
      ],
    );
  }
}
