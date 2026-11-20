import 'package:flutter/material.dart';

/// Single source of truth for supported subtitle and audio languages.
class PlaybackLanguage {
  final String code;
  final String name;
  final String nativeOrRegion;

  const PlaybackLanguage({
    required this.code,
    required this.name,
    required this.nativeOrRegion,
  });

  /// Full label formatted as `Name (Native)` (e.g. `Spanish (Español)`).
  String get displayName =>
      code == 'en' ? name : '$name ($nativeOrRegion)';

  /// Extended description for settings/onboarding options.
  String get description =>
      code == 'en' ? '$name ($nativeOrRegion)' : '$name subtitles';

  static const List<PlaybackLanguage> all = [
    PlaybackLanguage(
      code: 'en',
      name: 'English',
      nativeOrRegion: 'United States / Global',
    ),
    PlaybackLanguage(
      code: 'es',
      name: 'Spanish',
      nativeOrRegion: 'Español',
    ),
    PlaybackLanguage(
      code: 'fr',
      name: 'French',
      nativeOrRegion: 'Français',
    ),
    PlaybackLanguage(
      code: 'de',
      name: 'German',
      nativeOrRegion: 'Deutsch',
    ),
    PlaybackLanguage(
      code: 'it',
      name: 'Italian',
      nativeOrRegion: 'Italiano',
    ),
    PlaybackLanguage(
      code: 'pt',
      name: 'Portuguese',
      nativeOrRegion: 'Português',
    ),
    PlaybackLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeOrRegion: 'العربية',
    ),
    PlaybackLanguage(
      code: 'ja',
      name: 'Japanese',
      nativeOrRegion: '日本語',
    ),
  ];

  /// Formats language code to human-readable label.
  static String format(String code) {
    for (final l in all) {
      if (l.code == code) return l.displayName;
    }
    return code.toUpperCase();
  }
}

/// Single source of truth for streaming resolution & quality preferences.
class PlaybackQuality {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const PlaybackQuality({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  static const List<PlaybackQuality> all = [
    PlaybackQuality(
      value: 'auto',
      title: 'Auto',
      subtitle: 'Adapts automatically to network connection',
      icon: Icons.network_check_rounded,
    ),
    PlaybackQuality(
      value: '1080p',
      title: '1080p (FHD)',
      subtitle: 'Maximum detail and sharpness',
      icon: Icons.high_quality_rounded,
    ),
    PlaybackQuality(
      value: '720p',
      title: '720p (HD)',
      subtitle: 'Great balance of quality and data',
      icon: Icons.hd_rounded,
    ),
    PlaybackQuality(
      value: '480p',
      title: '480p (SD)',
      subtitle: 'Standard definition, lower buffering',
      icon: Icons.sd_rounded,
    ),
    PlaybackQuality(
      value: '360p',
      title: '360p (Data Saver)',
      subtitle: 'Saves mobile data',
      icon: Icons.data_saver_on_rounded,
    ),
  ];

  /// Formats quality key to display string.
  static String format(String q) {
    for (final item in all) {
      if (item.value == q) {
        return item.value == 'auto' ? 'Auto (Adaptive)' : item.title;
      }
    }
    return 'Auto (Adaptive)';
  }
}

