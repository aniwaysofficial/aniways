import 'package:flutter/material.dart';

const _genreColors = <String, Color>{
  'Action': Color(0xFFEF5350),
  'Adventure': Color(0xFFFFA726),
  'Comedy': Color(0xFFFFCA28),
  'Drama': Color(0xFFAB47BC),
  'Ecchi': Color(0xFFEC407A),
  'Fantasy': Color(0xFF7E57C2),
  'Horror': Color(0xFFB71C1C),
  'Mahou Shoujo': Color(0xFFF06292),
  'Mecha': Color(0xFF78909C),
  'Music': Color(0xFF26C6DA),
  'Mystery': Color(0xFF5C6BC0),
  'Psychological': Color(0xFF8D6E63),
  'Romance': Color(0xFFFF4081),
  'Sci-Fi': Color(0xFF29B6F6),
  'Slice of Life': Color(0xFF66BB6A),
  'Sports': Color(0xFF26A69A),
  'Supernatural': Color(0xFF9575CD),
  'Thriller': Color(0xFFD84315),
};

/// Fixed colour per known genre; unknown ones get a stable hue from the name.
Color genreColor(String genre) {
  final known = _genreColors[genre];
  if (known != null) return known;
  final hue = (genre.codeUnits.fold<int>(0, (a, b) => a * 31 + b) % 360)
      .toDouble();
  return HSLColor.fromAHSL(1, hue, 0.6, 0.55).toColor();
}

/// Lighter shade of [c] so text stays readable on its own tinted background.
Color lightenColor(Color c) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + 0.32).clamp(0.0, 0.92)).toColor();
}

const _genreIcons = <String, IconData>{
  'Action': Icons.local_fire_department_rounded,
  'Adventure': Icons.explore_rounded,
  'Comedy': Icons.sentiment_very_satisfied_rounded,
  'Drama': Icons.theater_comedy_rounded,
  'Ecchi': Icons.favorite_border_rounded,
  'Fantasy': Icons.auto_awesome_rounded,
  'Hentai': Icons.lock_outline_rounded,
  'Horror': Icons.nightlight_round,
  'Mahou Shoujo': Icons.star_rounded,
  'Mecha': Icons.smart_toy_rounded,
  'Music': Icons.music_note_rounded,
  'Mystery': Icons.search_rounded,
  'Psychological': Icons.psychology_rounded,
  'Romance': Icons.favorite_rounded,
  'Sci-Fi': Icons.rocket_launch_rounded,
  'Slice of Life': Icons.coffee_rounded,
  'Sports': Icons.sports_soccer_rounded,
  'Supernatural': Icons.visibility_rounded,
  'Thriller': Icons.warning_amber_rounded,
};

/// Icon representing a genre.
IconData genreIcon(String genre) =>
    _genreIcons[genre] ?? Icons.category_rounded;

