import 'package:flutter/material.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/theme_presets.dart';

/// Manages theme state and persists user preferences.
///
/// Listens to [SharedPreferencesService] for saved values and exposes
/// reactive getters that [Consumer<ThemeProvider>] widgets can watch.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadFromPrefs();
  }

  // ── State ───────────────────────────────────────────────────────────
  AppThemeMode _appTheme = AppThemeMode.auto;
  bool _dynamicTheme = false;
  bool _pureBlack = false;
  bool _useCoverColorAccent = true;
  AppColorPreset _colorPreset = AppColorPreset.sakuraPink;
  Color _customColor = SharedPreferencesService.defaultCustomColor;
  DynamicSchemeVariant? _paletteStyle; // null = each preset's own style
  double _contrastLevel = 0.0; // 0 standard, 0.5 medium, 1 high

  // ── Getters ─────────────────────────────────────────────────────────
  AppThemeMode get appTheme => _appTheme;
  bool get dynamicTheme => _dynamicTheme;
  bool get pureBlack => _pureBlack;
  bool get useCoverColorAccent => _useCoverColorAccent;
  AppColorPreset get colorPreset => _colorPreset;
  Color get customColor => _customColor;
  DynamicSchemeVariant? get paletteStyle => _paletteStyle;
  double get contrastLevel => _contrastLevel;

  /// Converts [AppThemeMode] into Flutter's [ThemeMode].
  ThemeMode get themeMode => switch (_appTheme) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.auto => ThemeMode.system,
  };

  // ── Setters (persist & notify) ──────────────────────────────────────

  Future<void> setAppTheme(AppThemeMode theme) async {
    _appTheme = theme;
    await SharedPreferencesService().setAppTheme(theme);
    notifyListeners();
  }

  Future<void> setDynamicTheme(bool value) async {
    _dynamicTheme = value;
    await SharedPreferencesService().setDynamicTheme(value);

    // Keep the preset selector in sync with the toggle.
    if (value) {
      _colorPreset = AppColorPreset.dynamic;
      await SharedPreferencesService().setColorPreset(AppColorPreset.dynamic);
    } else if (_colorPreset == AppColorPreset.dynamic) {
      _colorPreset = AppColorPreset.sakuraPink;
      await SharedPreferencesService().setColorPreset(
        AppColorPreset.sakuraPink,
      );
    }
    notifyListeners();
  }

  Future<void> setPureBlack(bool value) async {
    _pureBlack = value;
    await SharedPreferencesService().setPureBlack(value);
    notifyListeners();
  }

  Future<void> setUseCoverColorAccent(bool value) async {
    if (_useCoverColorAccent == value) return;
    _useCoverColorAccent = value;
    await SharedPreferencesService().setUseCoverColorAccent(value);
    notifyListeners();
  }

  Future<void> setColorPreset(AppColorPreset preset) async {
    _colorPreset = preset;
    await SharedPreferencesService().setColorPreset(preset);

    // Auto-toggle dynamic theme based on preset choice.
    final isDynamic = preset == AppColorPreset.dynamic;
    if (_dynamicTheme != isDynamic) {
      _dynamicTheme = isDynamic;
      await SharedPreferencesService().setDynamicTheme(isDynamic);
    }
    notifyListeners();
  }

  /// Seed colour for [AppColorPreset.custom].
  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    await SharedPreferencesService().setCustomColor(color);
    notifyListeners();
  }

  /// Overrides how palettes are generated. `null` = each preset's own style.
  Future<void> setPaletteStyle(DynamicSchemeVariant? style) async {
    _paletteStyle = style;
    await SharedPreferencesService().setPaletteStyle(style);
    notifyListeners();
  }

  /// 0.0 standard, 0.5 medium, 1.0 high.
  Future<void> setContrastLevel(double level) async {
    _contrastLevel = level;
    await SharedPreferencesService().setContrastLevel(level);
    notifyListeners();
  }

  /// Reloads theme state from disk. Useful after a full settings reset.
  Future<void> reload() async => _loadFromPrefs();

  // ── Private ─────────────────────────────────────────────────────────

  void _loadFromPrefs() {
    final prefs = SharedPreferencesService();
    _appTheme = prefs.appTheme;
    _dynamicTheme = prefs.dynamicTheme;
    _pureBlack = prefs.pureBlack;
    _useCoverColorAccent = prefs.useCoverColorAccent;
    _colorPreset = prefs.colorPreset;
    _customColor = prefs.customColor;
    _paletteStyle = prefs.paletteStyle;
    _contrastLevel = prefs.contrastLevel;
    notifyListeners();
  }
}
