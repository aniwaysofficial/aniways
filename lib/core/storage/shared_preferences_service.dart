import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aniways/core/theme/theme_presets.dart';

/// The three theme modes the user can choose from.
enum AppThemeMode { light, dark, auto }

/// The display modes for episode listings in the watch screen.
enum EpisodeViewMode {
  list,
  cards,
  compact;

  static EpisodeViewMode fromString(String? value) {
    return EpisodeViewMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EpisodeViewMode.list,
    );
  }
}

/// Singleton wrapper around [SharedPreferences] for type-safe access
/// to all persisted user settings.
///
/// Must call [init] once before use (typically in `main()`).
class SharedPreferencesService {
  SharedPreferencesService._internal();
  static final SharedPreferencesService _instance =
      SharedPreferencesService._internal();
  factory SharedPreferencesService() => _instance;

  SharedPreferences? _prefs;

  /// Initialise the underlying [SharedPreferences] instance.
  /// Call this once at app startup, before any reads.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // Known Flutter multi-engine/hot-restart race condition with shared_preferences_android.
      // Retry after a brief delay.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {}
    }
  }

  // ── Keys ────────────────────────────────────────────────────────────
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDynamicTheme = 'dynamic_theme';
  static const String _keyPureBlack = 'pure_black';
  static const String _keyUseCoverColorAccent = 'use_cover_color_accent';
  static const String _keyColorPreset = 'color_preset';
  static const String _keyCustomColor = 'custom_color';
  static const String _keyPaletteStyle = 'palette_style';
  static const String _keyContrastLevel = 'contrast_level';
  static const String _keyDefaultAudioTrack = 'default_audio_track';
  static const String _keyStreamingQuality = 'streaming_quality';
  static const String _keySubtitleLanguage = 'subtitle_language';
  static const String _keySubtitleFontSize = 'subtitle_font_size';
  static const String _keySubtitleTextColor = 'subtitle_text_color';
  static const String _keySubtitleOutlineStyle = 'subtitle_outline_style';
  static const String _keyAutoPlay = 'auto_play';
  static const String _keyAutoNextEpisode = 'auto_next_episode';
  static const String _keyAutoNextDuration = 'auto_next_duration';
  static const String _keyAutoSkipIntro = 'auto_skip_intro';
  static const String _keyAutoSkipOutro = 'auto_skip_outro';
  static const String _keyDoubleTapSeekDuration = 'double_tap_seek_duration';
  static const String _keyEnableSwipeGestures = 'enable_swipe_gestures';
  static const String _keyEnableLongPressSpeedBoost = 'enable_long_press_speed_boost';
  static const String _keyDefaultAspectRatio = 'default_aspect_ratio';
  static const String _keyDefaultPlaybackSpeed = 'default_playback_speed';
  static const String _keyEpisodeViewMode = 'episode_view_mode';
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keyMaxImageCacheMb = 'max_image_cache_mb';
  static const String _keyBackupDirectoryPath = 'backup_directory_path';
  static const String _keyBackupTreeUri = 'backup_tree_uri';
  static const String _keyAutoBackupFrequency = 'auto_backup_frequency';
  static const String _keyMaxAutoBackups = 'max_auto_backups';
  static const String _keyLastAutoBackupTime = 'last_auto_backup_time';
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyOnboardingFavoriteGenres = 'onboarding_favorite_genres';
  static const String _keyOnboardingFavoriteAnimeIds = 'onboarding_favorite_anime_ids';
  static const String _keyShowHomeRecommendations = 'show_home_recommendations';
  static const String _keyDismissedAnimePicksBanner = 'dismissed_anime_picks_banner';
  static const String _keyEnableAdultContent = 'enable_adult_content';
  static const String _keyBlurAdultCovers = 'blur_adult_covers';
  static const String _keyIncludeAdultInHome = 'include_adult_in_home';
  static const String _keyNotificationEnabled = 'notification_enabled';
  static const String _keyNotificationMinimumProviders = 'notification_min_providers';
  static const String _keyNotificationPreferredAudio = 'notification_preferred_audio';
  static const String _keyNotificationAutoSubscribeWatching = 'notification_auto_subscribe_watching';

  // ════════════════════════════════════════════════════════════════════
  // APP THEME
  // ════════════════════════════════════════════════════════════════════

  /// Current theme mode. Default: [AppThemeMode.auto].
  AppThemeMode get appTheme {
    final value = _prefs?.getString(_keyThemeMode) ?? 'auto';
    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.auto,
    );
  }

  Future<bool> setAppTheme(AppThemeMode theme) async {
    return await _prefs?.setString(_keyThemeMode, theme.name) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // DYNAMIC THEME
  // ════════════════════════════════════════════════════════════════════

  /// Whether to use the device's dynamic/wallpaper colours. Default: `false`.
  bool get dynamicTheme => _prefs?.getBool(_keyDynamicTheme) ?? false;

  Future<bool> setDynamicTheme(bool value) async {
    return await _prefs?.setBool(_keyDynamicTheme, value) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // PURE BLACK (OLED)
  // ════════════════════════════════════════════════════════════════════

  /// Whether to use pure-black surfaces in dark mode. Default: `false`.
  bool get pureBlack => _prefs?.getBool(_keyPureBlack) ?? false;

  Future<bool> setPureBlack(bool value) async {
    return await _prefs?.setBool(_keyPureBlack, value) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // COVER COLOR ACCENT
  // ════════════════════════════════════════════════════════════════════

  /// Whether to use the anime cover's color as the accent in details and watch screens.
  /// Default: `true`.
  bool get useCoverColorAccent =>
      _prefs?.getBool(_keyUseCoverColorAccent) ?? true;

  Future<bool> setUseCoverColorAccent(bool value) async {
    return await _prefs?.setBool(_keyUseCoverColorAccent, value) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // COLOUR PRESET
  // ════════════════════════════════════════════════════════════════════

  /// Selected colour preset. Default: [AppColorPreset.sakuraPink].
  AppColorPreset get colorPreset {
    final value = _prefs?.getString(_keyColorPreset) ?? 'sakuraPink';
    return AppColorPreset.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppColorPreset.sakuraPink,
    );
  }

  Future<bool> setColorPreset(AppColorPreset preset) async {
    return await _prefs?.setString(_keyColorPreset, preset.name) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // CUSTOM COLOUR
  // ════════════════════════════════════════════════════════════════════

  static const Color defaultCustomColor = Color(0xFF6750A4);

  /// Seed colour used by [AppColorPreset.custom].
  Color get customColor {
    final value = _prefs?.getInt(_keyCustomColor);
    return value == null ? defaultCustomColor : Color(value);
  }

  Future<bool> setCustomColor(Color color) async {
    return await _prefs?.setInt(_keyCustomColor, color.toARGB32()) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // PALETTE STYLE
  // ════════════════════════════════════════════════════════════════════

  /// User override for how palettes are generated from their seed.
  /// `null` (default) means each preset keeps its own style.
  DynamicSchemeVariant? get paletteStyle {
    final name = _prefs?.getString(_keyPaletteStyle);
    if (name == null) return null;
    for (final v in DynamicSchemeVariant.values) {
      if (v.name == name) return v;
    }
    return null;
  }

  Future<bool> setPaletteStyle(DynamicSchemeVariant? style) async {
    if (style == null) {
      return await _prefs?.remove(_keyPaletteStyle) ?? false;
    }
    return await _prefs?.setString(_keyPaletteStyle, style.name) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // CONTRAST LEVEL
  // ════════════════════════════════════════════════════════════════════

  /// 0.0 standard, 0.5 medium, 1.0 high. Default: `0.0`.
  double get contrastLevel => _prefs?.getDouble(_keyContrastLevel) ?? 0.0;

  Future<bool> setContrastLevel(double level) async {
    return await _prefs?.setDouble(_keyContrastLevel, level) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // DEFAULT AUDIO TRACK
  // ════════════════════════════════════════════════════════════════════

  /// Preferred default audio track: 'sub' (Subtitled) or 'dub' (Dubbed).
  /// Default: 'sub'.
  String get defaultAudioTrack =>
      _prefs?.getString(_keyDefaultAudioTrack) ?? 'sub';

  Future<bool> setDefaultAudioTrack(String track) async {
    return await _prefs?.setString(_keyDefaultAudioTrack, track) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // STREAMING QUALITY
  // ════════════════════════════════════════════════════════════════════

  /// Preferred streaming quality: 'auto', '360p', '480p', '720p', '1080p'.
  /// Default: 'auto'.
  String get streamingQuality =>
      _prefs?.getString(_keyStreamingQuality) ?? 'auto';

  Future<bool> setStreamingQuality(String quality) async {
    return await _prefs?.setString(_keyStreamingQuality, quality) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // SUBTITLES & STYLING
  // ════════════════════════════════════════════════════════════════════

  /// Preferred subtitle language code (e.g., 'en', 'ja', 'es', 'fr'). Default: 'en'.
  String get subtitleLanguage =>
      _prefs?.getString(_keySubtitleLanguage) ?? 'en';

  Future<bool> setSubtitleLanguage(String language) async {
    return await _prefs?.setString(_keySubtitleLanguage, language) ?? false;
  }

  /// Subtitle font size in sp: 14.0 (Small), 18.0 (Normal), 22.0 (Large), 26.0 (Extra Large).
  /// Default: 18.0.
  double get subtitleFontSize =>
      _prefs?.getDouble(_keySubtitleFontSize) ?? 18.0;

  Future<bool> setSubtitleFontSize(double size) async {
    return await _prefs?.setDouble(_keySubtitleFontSize, size) ?? false;
  }

  /// Subtitle text color: 'white', 'yellow', 'cyan'. Default: 'white'.
  String get subtitleTextColor =>
      _prefs?.getString(_keySubtitleTextColor) ?? 'white';

  Future<bool> setSubtitleTextColor(String color) async {
    return await _prefs?.setString(_keySubtitleTextColor, color) ?? false;
  }

  /// Subtitle outline / background style: 'outline', 'background', 'none'. Default: 'outline'.
  String get subtitleOutlineStyle =>
      _prefs?.getString(_keySubtitleOutlineStyle) ?? 'outline';

  Future<bool> setSubtitleOutlineStyle(String style) async {
    return await _prefs?.setString(_keySubtitleOutlineStyle, style) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // PLAYBACK AUTOMATION
  // ════════════════════════════════════════════════════════════════════

  /// Whether videos auto-play when opened. Default: `true`.
  bool get autoPlay => _prefs?.getBool(_keyAutoPlay) ?? true;

  Future<bool> setAutoPlay(bool value) async {
    return await _prefs?.setBool(_keyAutoPlay, value) ?? false;
  }

  /// Whether to automatically play the next episode. Default: `true`.
  bool get autoNextEpisode => _prefs?.getBool(_keyAutoNextEpisode) ?? true;

  Future<bool> setAutoNextEpisode(bool value) async {
    return await _prefs?.setBool(_keyAutoNextEpisode, value) ?? false;
  }

  /// Countdown seconds before auto-playing next episode: 0 (immediate), 3, 5, 10. Default: 5.
  int get autoNextDuration => _prefs?.getInt(_keyAutoNextDuration) ?? 5;

  Future<bool> setAutoNextDuration(int seconds) async {
    return await _prefs?.setInt(_keyAutoNextDuration, seconds) ?? false;
  }

  /// Whether to auto-skip intro sequences. Default: `false`.
  bool get autoSkipIntro => _prefs?.getBool(_keyAutoSkipIntro) ?? false;

  Future<bool> setAutoSkipIntro(bool value) async {
    return await _prefs?.setBool(_keyAutoSkipIntro, value) ?? false;
  }

  /// Whether to auto-skip outro sequences. Default: `false`.
  bool get autoSkipOutro => _prefs?.getBool(_keyAutoSkipOutro) ?? false;

  Future<bool> setAutoSkipOutro(bool value) async {
    return await _prefs?.setBool(_keyAutoSkipOutro, value) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // PLAYER CONTROLS & GESTURES
  // ════════════════════════════════════════════════════════════════════

  /// Double-tap seek step in seconds: 5, 10, 15, 30. Default: 10.
  int get doubleTapSeekDuration =>
      _prefs?.getInt(_keyDoubleTapSeekDuration) ?? 10;

  Future<bool> setDoubleTapSeekDuration(int seconds) async {
    return await _prefs?.setInt(_keyDoubleTapSeekDuration, seconds) ?? false;
  }

  /// Whether vertical swipe gestures for volume & brightness are enabled. Default: `true`.
  bool get enableSwipeGestures =>
      _prefs?.getBool(_keyEnableSwipeGestures) ?? true;

  Future<bool> setEnableSwipeGestures(bool value) async {
    return await _prefs?.setBool(_keyEnableSwipeGestures, value) ?? false;
  }

  /// Whether long-press for 2x speed boost is enabled. Default: `true`.
  bool get enableLongPressSpeedBoost =>
      _prefs?.getBool(_keyEnableLongPressSpeedBoost) ?? true;

  Future<bool> setEnableLongPressSpeedBoost(bool value) async {
    return await _prefs?.setBool(_keyEnableLongPressSpeedBoost, value) ?? false;
  }

  /// Default aspect ratio mode: 'fit', 'zoom', 'stretch', 'ratio4x3'. Default: 'fit'.
  String get defaultAspectRatio =>
      _prefs?.getString(_keyDefaultAspectRatio) ?? 'fit';

  Future<bool> setDefaultAspectRatio(String ratio) async {
    return await _prefs?.setString(_keyDefaultAspectRatio, ratio) ?? false;
  }

  /// Default video playback speed: 0.75, 1.0, 1.25, 1.5, 2.0. Default: 1.0.
  double get defaultPlaybackSpeed =>
      _prefs?.getDouble(_keyDefaultPlaybackSpeed) ?? 1.0;

  Future<bool> setDefaultPlaybackSpeed(double speed) async {
    return await _prefs?.setDouble(_keyDefaultPlaybackSpeed, speed) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // EPISODE VIEW MODE
  // ════════════════════════════════════════════════════════════════════

  /// Display mode for episode listings: 'list', 'cards', or 'compact'.
  /// Default: [EpisodeViewMode.list].
  EpisodeViewMode get episodeViewMode {
    final value = _prefs?.getString(_keyEpisodeViewMode);
    return EpisodeViewMode.fromString(value);
  }

  Future<bool> setEpisodeViewMode(EpisodeViewMode mode) async {
    return await _prefs?.setString(_keyEpisodeViewMode, mode.name) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // RECENT SEARCHES
  // ════════════════════════════════════════════════════════════════════

  /// List of recent search queries, newest first.
  List<String> get recentSearches =>
      _prefs?.getStringList(_keyRecentSearches) ?? const [];

  Future<bool> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    final list = List<String>.from(recentSearches);
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > 20) list.removeRange(20, list.length);
    return await _prefs?.setStringList(_keyRecentSearches, list) ?? false;
  }

  Future<bool> removeRecentSearch(String query) async {
    final list = List<String>.from(recentSearches)..remove(query);
    return await _prefs?.setStringList(_keyRecentSearches, list) ?? false;
  }

  Future<bool> clearRecentSearches() async {
    return await _prefs?.remove(_keyRecentSearches) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // STORAGE & CACHE PREFERENCES
  // ════════════════════════════════════════════════════════════════════

  /// Maximum image cache limit in megabytes: 100, 250, 500, 1000. Default: 250.
  int get maxImageCacheMb => _prefs?.getInt(_keyMaxImageCacheMb) ?? 250;

  Future<bool> setMaxImageCacheMb(int mb) async {
    return await _prefs?.setInt(_keyMaxImageCacheMb, mb) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // AUTOMATIC BACKUP PREFERENCES
  // ════════════════════════════════════════════════════════════════════

  /// Custom folder path for backups chosen by user (null if using default).
  String? get backupDirectoryPath => _prefs?.getString(_keyBackupDirectoryPath);

  Future<bool> setBackupDirectoryPath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await _prefs?.remove(_keyBackupTreeUri);
      return await _prefs?.remove(_keyBackupDirectoryPath) ?? false;
    }
    return await _prefs?.setString(_keyBackupDirectoryPath, path.trim()) ?? false;
  }

  /// Persisted Android SAF tree URI for backups chosen by user (null if using default).
  String? get backupTreeUri => _prefs?.getString(_keyBackupTreeUri);

  Future<bool> setBackupTreeUri(String? uri) async {
    if (uri == null || uri.trim().isEmpty) {
      return await _prefs?.remove(_keyBackupTreeUri) ?? false;
    }
    return await _prefs?.setString(_keyBackupTreeUri, uri.trim()) ?? false;
  }

  /// Automatic backup frequency: 'off', 'daily', 'weekly'. Default: 'off'.
  String get autoBackupFrequency =>
      _prefs?.getString(_keyAutoBackupFrequency) ?? 'off';

  Future<bool> setAutoBackupFrequency(String freq) async {
    return await _prefs?.setString(_keyAutoBackupFrequency, freq) ?? false;
  }

  /// Maximum number of automatic backups to retain: 3, 5, 10. Default: 5.
  int get maxAutoBackups => _prefs?.getInt(_keyMaxAutoBackups) ?? 5;

  Future<bool> setMaxAutoBackups(int max) async {
    return await _prefs?.setInt(_keyMaxAutoBackups, max) ?? false;
  }

  /// Last automatic backup ISO8601 string.
  String? get lastAutoBackupTime => _prefs?.getString(_keyLastAutoBackupTime);

  Future<bool> setLastAutoBackupTime(String time) async {
    return await _prefs?.setString(_keyLastAutoBackupTime, time) ?? false;
  }

  // ════════════════════════════════════════════════════════════════════
  // ONBOARDING & PERSONALIZATION
  // ════════════════════════════════════════════════════════════════════

  /// Whether the user has completed the initial onboarding wizard. Default: `false`.
  bool get hasCompletedOnboarding =>
      _prefs?.getBool(_keyHasCompletedOnboarding) ?? false;

  Future<bool> setHasCompletedOnboarding(bool completed) async {
    return await _prefs?.setBool(_keyHasCompletedOnboarding, completed) ?? false;
  }

  /// Preferred genres selected during onboarding or in preferences.
  List<String> get onboardingFavoriteGenres =>
      _prefs?.getStringList(_keyOnboardingFavoriteGenres) ?? [];

  Future<bool> setOnboardingFavoriteGenres(List<String> genres) async {
    return await _prefs?.setStringList(_keyOnboardingFavoriteGenres, genres) ??
        false;
  }

  /// Notifier triggered whenever recommendations settings change.
  static final ValueNotifier<int> recommendationsChangedNotifier =
      ValueNotifier<int>(0);

  /// IDs of favorite anime series/movies selected during onboarding.
  List<int> get onboardingFavoriteAnimeIds =>
      (_prefs?.getStringList(_keyOnboardingFavoriteAnimeIds) ?? [])
          .map((e) => int.tryParse(e) ?? 0)
          .where((id) => id > 0)
          .toList();

  Future<bool> setOnboardingFavoriteAnimeIds(List<int> ids) async {
    final res = await _prefs?.setStringList(
          _keyOnboardingFavoriteAnimeIds,
          ids.map((e) => e.toString()).toList(),
        ) ??
        false;
    recommendationsChangedNotifier.value++;
    return res;
  }

  // ════════════════════════════════════════════════════════════════════
  // RECOMMENDATIONS
  // ════════════════════════════════════════════════════════════════════

  /// Whether to display personalized recommendations on the home feed.
  /// Default: `true`.
  bool get showHomeRecommendations =>
      _prefs?.getBool(_keyShowHomeRecommendations) ?? true;

  Future<bool> setShowHomeRecommendations(bool value) async {
    final res =
        await _prefs?.setBool(_keyShowHomeRecommendations, value) ?? false;
    recommendationsChangedNotifier.value++;
    return res;
  }

  /// Whether the user dismissed the "Anime You Love" prompt card on the home feed.
  /// Default: `false`.
  bool get dismissedAnimePicksBanner =>
      _prefs?.getBool(_keyDismissedAnimePicksBanner) ?? false;

  Future<bool> setDismissedAnimePicksBanner(bool value) async {
    final res =
        await _prefs?.setBool(_keyDismissedAnimePicksBanner, value) ?? false;
    recommendationsChangedNotifier.value++;
    return res;
  }

  // ════════════════════════════════════════════════════════════════════
  // CONTENT & MATURITY (18+)
  // ════════════════════════════════════════════════════════════════════

  bool get enableAdultContent =>
      _prefs?.getBool(_keyEnableAdultContent) ?? false;

  Future<void> setEnableAdultContent(bool value) async {
    await _prefs?.setBool(_keyEnableAdultContent, value);
  }

  bool get blurAdultCovers =>
      _prefs?.getBool(_keyBlurAdultCovers) ?? true;

  Future<void> setBlurAdultCovers(bool value) async {
    await _prefs?.setBool(_keyBlurAdultCovers, value);
  }

  bool get includeAdultInHome =>
      _prefs?.getBool(_keyIncludeAdultInHome) ?? false;

  Future<void> setIncludeAdultInHome(bool value) async {
    await _prefs?.setBool(_keyIncludeAdultInHome, value);
  }

  // ════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════

  bool get notificationEnabled =>
      _prefs?.getBool(_keyNotificationEnabled) ?? false;

  Future<void> setNotificationEnabled(bool value) async {
    await _prefs?.setBool(_keyNotificationEnabled, value);
  }

  int get notificationMinimumProviders =>
      _prefs?.getInt(_keyNotificationMinimumProviders) ?? 2;

  Future<void> setNotificationMinimumProviders(int value) async {
    await _prefs?.setInt(_keyNotificationMinimumProviders, value);
  }

  String get notificationPreferredAudio =>
      _prefs?.getString(_keyNotificationPreferredAudio) ?? 'either';

  Future<void> setNotificationPreferredAudio(String value) async {
    await _prefs?.setString(_keyNotificationPreferredAudio, value);
  }

  bool get notificationAutoSubscribeWatching =>
      _prefs?.getBool(_keyNotificationAutoSubscribeWatching) ?? false;

  Future<void> setNotificationAutoSubscribeWatching(bool value) async {
    await _prefs?.setBool(_keyNotificationAutoSubscribeWatching, value);
  }

  // ════════════════════════════════════════════════════════════════════
  // BACKUP & RESTORE SERIALIZATION
  // ════════════════════════════════════════════════════════════════════

  /// Serializes all user settings into a JSON-compatible map for backup.
  Map<String, dynamic> exportSettings() {
    return {
      'theme_mode': appTheme.name,
      'dynamic_theme': dynamicTheme,
      'pure_black': pureBlack,
      'use_cover_color_accent': useCoverColorAccent,
      'color_preset': colorPreset.name,
      'custom_color': customColor.toARGB32(),
      'palette_style': paletteStyle?.name,
      'contrast_level': contrastLevel,
      'default_audio_track': defaultAudioTrack,
      'streaming_quality': streamingQuality,
      'subtitle_language': subtitleLanguage,
      'subtitle_font_size': subtitleFontSize,
      'subtitle_text_color': subtitleTextColor,
      'subtitle_outline_style': subtitleOutlineStyle,
      'auto_play': autoPlay,
      'auto_next_episode': autoNextEpisode,
      'auto_next_duration': autoNextDuration,
      'auto_skip_intro': autoSkipIntro,
      'auto_skip_outro': autoSkipOutro,
      'double_tap_seek_duration': doubleTapSeekDuration,
      'enable_swipe_gestures': enableSwipeGestures,
      'enable_long_press_speed_boost': enableLongPressSpeedBoost,
      'default_aspect_ratio': defaultAspectRatio,
      'default_playback_speed': defaultPlaybackSpeed,
      'episode_view_mode': episodeViewMode.name,
      'show_home_recommendations': showHomeRecommendations,
      'dismissed_anime_picks_banner': dismissedAnimePicksBanner,
      'enable_adult_content': enableAdultContent,
      'blur_adult_covers': blurAdultCovers,
      'include_adult_in_home': includeAdultInHome,
      'notification_enabled': notificationEnabled,
      'notification_min_providers': notificationMinimumProviders,
      'notification_preferred_audio': notificationPreferredAudio,
      'notification_auto_subscribe_watching': notificationAutoSubscribeWatching,
    };
  }

  /// Restores user settings from a previously exported backup map.
  Future<void> importSettings(Map<String, dynamic> data) async {
    // ── Appearance & Theme ──
    if (data.containsKey('theme_mode')) {
      final raw = data['theme_mode']?.toString();
      final mode = AppThemeMode.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AppThemeMode.auto,
      );
      await setAppTheme(mode);
    }
    if (data.containsKey('dynamic_theme')) {
      await setDynamicTheme(data['dynamic_theme'] == true);
    }
    if (data.containsKey('pure_black')) {
      await setPureBlack(data['pure_black'] == true);
    }
    if (data.containsKey('use_cover_color_accent')) {
      await setUseCoverColorAccent(data['use_cover_color_accent'] == true);
    }
    if (data.containsKey('color_preset')) {
      final raw = data['color_preset']?.toString();
      final preset = AppColorPreset.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AppColorPreset.sakuraPink,
      );
      await setColorPreset(preset);
    }
    if (data.containsKey('custom_color')) {
      final val = data['custom_color'];
      if (val is num) {
        await setCustomColor(Color(val.toInt()));
      }
    }
    if (data.containsKey('palette_style')) {
      final raw = data['palette_style']?.toString();
      if (raw == null || raw == 'null') {
        await setPaletteStyle(null);
      } else {
        final style = DynamicSchemeVariant.values
            .where((v) => v.name == raw)
            .firstOrNull;
        await setPaletteStyle(style);
      }
    }
    if (data.containsKey('contrast_level')) {
      final val = data['contrast_level'];
      if (val is num) {
        await setContrastLevel(val.toDouble());
      }
    }

    // ── Playback Preferences ──
    if (data.containsKey('default_audio_track')) {
      await setDefaultAudioTrack(data['default_audio_track']?.toString() ?? 'sub');
    }
    if (data.containsKey('streaming_quality')) {
      await setStreamingQuality(data['streaming_quality']?.toString() ?? 'auto');
    }
    if (data.containsKey('subtitle_language')) {
      await setSubtitleLanguage(data['subtitle_language']?.toString() ?? 'en');
    }
    if (data.containsKey('subtitle_font_size')) {
      final size = (data['subtitle_font_size'] as num?)?.toDouble() ?? 18.0;
      await setSubtitleFontSize(size);
    }
    if (data.containsKey('subtitle_text_color')) {
      await setSubtitleTextColor(data['subtitle_text_color']?.toString() ?? 'white');
    }
    if (data.containsKey('subtitle_outline_style')) {
      await setSubtitleOutlineStyle(data['subtitle_outline_style']?.toString() ?? 'outline');
    }
    if (data.containsKey('auto_play')) {
      await setAutoPlay(data['auto_play'] == true);
    }
    if (data.containsKey('auto_next_episode')) {
      await setAutoNextEpisode(data['auto_next_episode'] == true);
    }
    if (data.containsKey('auto_next_duration')) {
      final dur = (data['auto_next_duration'] as num?)?.toInt() ?? 5;
      await setAutoNextDuration(dur);
    }
    if (data.containsKey('auto_skip_intro')) {
      await setAutoSkipIntro(data['auto_skip_intro'] == true);
    }
    if (data.containsKey('auto_skip_outro')) {
      await setAutoSkipOutro(data['auto_skip_outro'] == true);
    }
    if (data.containsKey('double_tap_seek_duration')) {
      final seek = (data['double_tap_seek_duration'] as num?)?.toInt() ?? 10;
      await setDoubleTapSeekDuration(seek);
    }
    if (data.containsKey('enable_swipe_gestures')) {
      await setEnableSwipeGestures(data['enable_swipe_gestures'] != false);
    }
    if (data.containsKey('enable_long_press_speed_boost')) {
      await setEnableLongPressSpeedBoost(data['enable_long_press_speed_boost'] != false);
    }
    if (data.containsKey('default_aspect_ratio')) {
      await setDefaultAspectRatio(data['default_aspect_ratio']?.toString() ?? 'fit');
    }
    if (data.containsKey('default_playback_speed')) {
      final spd = (data['default_playback_speed'] as num?)?.toDouble() ?? 1.0;
      await setDefaultPlaybackSpeed(spd);
    }
    if (data.containsKey('episode_view_mode')) {
      final mode = EpisodeViewMode.fromString(
        data['episode_view_mode']?.toString(),
      );
      await setEpisodeViewMode(mode);
    }
    if (data.containsKey('show_home_recommendations')) {
      await setShowHomeRecommendations(
        data['show_home_recommendations'] != false,
      );
    }
    if (data.containsKey('dismissed_anime_picks_banner')) {
      await setDismissedAnimePicksBanner(
        data['dismissed_anime_picks_banner'] == true,
      );
    }

    // ── Content & Maturity ──
    if (data.containsKey('enable_adult_content')) {
      await setEnableAdultContent(data['enable_adult_content'] == true);
    }
    if (data.containsKey('blur_adult_covers')) {
      await setBlurAdultCovers(data['blur_adult_covers'] != false);
    }
    if (data.containsKey('include_adult_in_home')) {
      await setIncludeAdultInHome(data['include_adult_in_home'] == true);
    }

    // ── Notifications ──
    if (data.containsKey('notification_enabled')) {
      await setNotificationEnabled(data['notification_enabled'] != false);
    }
    if (data.containsKey('notification_min_providers')) {
      final val = (data['notification_min_providers'] as num?)?.toInt() ?? 2;
      await setNotificationMinimumProviders(val);
    }
    if (data.containsKey('notification_preferred_audio')) {
      await setNotificationPreferredAudio(
        data['notification_preferred_audio']?.toString() ?? 'either',
      );
    }
    if (data.containsKey('notification_auto_subscribe_watching')) {
      await setNotificationAutoSubscribeWatching(
        data['notification_auto_subscribe_watching'] != false,
      );
    }
  }

  /// Resets all user settings back to their factory default values.
  Future<void> resetSettingsToDefault() async {
    await _prefs?.remove(_keyThemeMode);
    await _prefs?.remove(_keyDynamicTheme);
    await _prefs?.remove(_keyPureBlack);
    await _prefs?.remove(_keyUseCoverColorAccent);
    await _prefs?.remove(_keyColorPreset);
    await _prefs?.remove(_keyCustomColor);
    await _prefs?.remove(_keyPaletteStyle);
    await _prefs?.remove(_keyContrastLevel);
    await _prefs?.remove(_keyDefaultAudioTrack);
    await _prefs?.remove(_keyStreamingQuality);
    await _prefs?.remove(_keySubtitleLanguage);
    await _prefs?.remove(_keySubtitleFontSize);
    await _prefs?.remove(_keySubtitleTextColor);
    await _prefs?.remove(_keySubtitleOutlineStyle);
    await _prefs?.remove(_keyAutoPlay);
    await _prefs?.remove(_keyAutoNextEpisode);
    await _prefs?.remove(_keyAutoNextDuration);
    await _prefs?.remove(_keyAutoSkipIntro);
    await _prefs?.remove(_keyAutoSkipOutro);
    await _prefs?.remove(_keyDoubleTapSeekDuration);
    await _prefs?.remove(_keyEnableSwipeGestures);
    await _prefs?.remove(_keyEnableLongPressSpeedBoost);
    await _prefs?.remove(_keyDefaultAspectRatio);
    await _prefs?.remove(_keyDefaultPlaybackSpeed);
    await _prefs?.remove(_keyEpisodeViewMode);
    await _prefs?.remove(_keyShowHomeRecommendations);
    await _prefs?.remove(_keyDismissedAnimePicksBanner);
    await _prefs?.remove(_keyEnableAdultContent);
    await _prefs?.remove(_keyBlurAdultCovers);
    await _prefs?.remove(_keyIncludeAdultInHome);
    await _prefs?.remove(_keyNotificationEnabled);
    await _prefs?.remove(_keyNotificationMinimumProviders);
    await _prefs?.remove(_keyNotificationPreferredAudio);
    await _prefs?.remove(_keyNotificationAutoSubscribeWatching);
  }
}
