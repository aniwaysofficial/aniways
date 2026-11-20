import 'package:flutter/material.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/screens/search/search_filter.dart';

/// One season category card item for the search screen discover view.
class SeasonCategory {
  const SeasonCategory({
    required this.season,
    required this.year,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final AnimeSeason season;
  final int year;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  /// Cache and map key matching '${season.value}_$year' (e.g. 'FALL_2026').
  String get key => '${season.value}_$year';
}

/// Icon and accent color mappings for each of the 4 anime seasons.
(IconData icon, Color accentColor, String months) _seasonVisuals(
  AnimeSeason season,
) {
  return switch (season) {
    AnimeSeason.winter => (
      Icons.ac_unit_rounded,
      const Color(0xFF29B6F6), // Cool Cyan / Ice Blue
      'Jan – Mar',
    ),
    AnimeSeason.spring => (
      Icons.local_florist_rounded,
      const Color(0xFFEC407A), // Sakura Blossom Pink
      'Apr – Jun',
    ),
    AnimeSeason.summer => (
      Icons.wb_sunny_rounded,
      const Color(0xFFFFA726), // Summer Amber Gold
      'Jul – Sep',
    ),
    AnimeSeason.fall => (
      Icons.eco_rounded,
      const Color(0xFFFF7043), // Autumn Maple Orange
      'Oct – Dec',
    ),
  };
}

SeasonCategory _createSeasonCategory({
  required AnimeSeason season,
  required int year,
  String? statusSubtitle,
}) {
  final (icon, accentColor, months) = _seasonVisuals(season);
  return SeasonCategory(
    season: season,
    year: year,
    title: '${season.label} $year',
    subtitle: statusSubtitle ?? months,
    icon: icon,
    accentColor: accentColor,
  );
}

/// Generates a list of season categories starting from the upcoming/current
/// season and going backwards [yearsBack] years.
List<SeasonCategory> generateSeasonCategories({
  int yearsBack = 3,
  DateTime? now,
}) {
  final currentDate = now ?? DateTime.now();
  final (currSeasonStr, currYear) = AnilistService.seasonFor(currentDate);
  final currSeason = AnimeSeason.values.firstWhere(
    (s) => s.value == currSeasonStr,
    orElse: () => AnimeSeason.fall,
  );

  const cycle = [
    AnimeSeason.winter,
    AnimeSeason.spring,
    AnimeSeason.summer,
    AnimeSeason.fall,
  ];

  final currIndex = cycle.indexOf(currSeason);
  final nextSeason = cycle[(currIndex + 1) % 4];
  final nextYear = currIndex == 3 ? currYear + 1 : currYear;

  final items = <SeasonCategory>[];

  // 1. Upcoming season
  items.add(_createSeasonCategory(
    season: nextSeason,
    year: nextYear,
    statusSubtitle: 'Upcoming',
  ));

  // 2. Current season
  items.add(_createSeasonCategory(
    season: currSeason,
    year: currYear,
    statusSubtitle: 'This season',
  ));

  // 3. Past seasons going backwards
  var sIdx = currIndex - 1;
  var y = currYear;
  final totalPastSeasons = yearsBack * 4;

  for (var i = 0; i < totalPastSeasons; i++) {
    if (sIdx < 0) {
      sIdx = 3;
      y--;
    }
    final sn = cycle[sIdx];
    items.add(_createSeasonCategory(
      season: sn,
      year: y,
    ));
    sIdx--;
  }

  return items;
}

