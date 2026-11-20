import 'dart:math' as math;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:provider/provider.dart';

import 'package:aniways/core/theme/app_theme.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/theme/theme_presets.dart';
import 'package:aniways/providers/theme_provider.dart';
import 'package:aniways/screens/onboarding/widgets/onboarding_card_scaffold.dart';

/// Step 1: Theme mode and palette. Mirrors the Appearance settings screen
/// (same previews, same palette carousel). Changes apply live.
///
/// NOTE: the preview widgets below are copies of the private ones in
/// appearance_screen.dart. If you move `_MiniScreen`, `_ThemeModeSelector`
/// and `_PaletteCarousel` into a shared file, both screens can use them.
class ThemeSetupCard extends StatelessWidget {
  const ThemeSetupCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cat = CategoryColors.of(context);
    final p = context.watch<ThemeProvider>();

    final isSystemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isCurrentlyDark =
        p.appTheme == AppThemeMode.dark ||
        (p.appTheme == AppThemeMode.auto && isSystemDark);

    final dynamicActive =
        p.dynamicTheme || p.colorPreset == AppColorPreset.dynamic;
    final selectedPreset = dynamicActive
        ? AppColorPreset.dynamic
        : p.colorPreset;

    return OnboardingPage(
      title: 'Make it yours',
      subtitle:
          'Pick a look. Changes apply as you tap, and you can change '
          'them any time in Settings.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingSection(
            title: 'Theme mode',
            child: _ThemeModeSelector(
              selected: p.appTheme,
              pureBlack: p.pureBlack,
              onSelected: (m) {
                HapticFeedback.selectionClick();
                p.setAppTheme(m);
              },
            ),
          ),
          OnboardingSection(
            title: 'Color palette',
            child: _PaletteCarousel(
              selected: selectedPreset,
              customColor: p.customColor,
              styleOverride: p.paletteStyle,
              contrastLevel: p.contrastLevel,
              onSelected: (preset) {
                HapticFeedback.selectionClick();
                if (preset == AppColorPreset.dynamic) {
                  p.setDynamicTheme(true);
                } else if (p.dynamicTheme) {
                  p.setDynamicTheme(false);
                }
                p.setColorPreset(preset);
              },
            ),
          ),
          OnboardingSection(
            title: 'Options',
            child: OnboardingGroup(
              tiles: [
                OnboardingTile(
                  icon: Icons.dark_mode_rounded,
                  color: cat.accounts,
                  title: 'Pure black',
                  subtitle: isCurrentlyDark
                      ? 'True black background, saves battery on AMOLED'
                      : 'Switch to a dark theme to use pure black',
                  onTap: isCurrentlyDark
                      ? () {
                          HapticFeedback.selectionClick();
                          p.setPureBlack(!p.pureBlack);
                        }
                      : null,
                  trailing: Switch.adaptive(
                    value: p.pureBlack,
                    onChanged: isCurrentlyDark
                        ? (v) {
                            HapticFeedback.selectionClick();
                            p.setPureBlack(v);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Mini app preview
// ═════════════════════════════════════════════════════════════════════════

class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.scheme});

  final ColorScheme scheme;

  static const double w = 100;
  static const double h = 132;

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
        width: w,
        height: h,
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
// Theme mode
// ═════════════════════════════════════════════════════════════════════════

class _DiagonalClipper extends CustomClipper<Path> {
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

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
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
                aspectRatio: _MiniScreen.w / _MiniScreen.h,
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
// Palette carousel
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

  /// Sakura first. The custom-color picker is left for Settings.
  static final _ordered = <AppColorPreset>[
    AppColorPreset.sakuraPink,
    ...AppColorPreset.values.where(
      (p) => p != AppColorPreset.sakuraPink && p != AppColorPreset.custom,
    ),
  ];

  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final index = _ordered.indexOf(widget.selected);
    final offset = math.max(0.0, index * (_cardWidth + _gap) - 16);
    _controller = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                  aspectRatio: _MiniScreen.w / _MiniScreen.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _MiniScreen(scheme: scheme),
                        if (isDynamic)
                          const Positioned(
                            left: 6,
                            top: 6,
                            child: _Badge(
                              icon: Icons.wallpaper_rounded,
                              background: Color(0x73000000),
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
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
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
