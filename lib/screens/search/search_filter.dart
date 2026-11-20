import 'package:flutter/foundation.dart';

/// Sort options supported by AniList search.
enum AnimeSort {
  popularity('POPULARITY_DESC', 'Popularity'),
  score('SCORE_DESC', 'Top rated'),
  trending('TRENDING_DESC', 'Trending'),
  startDate('START_DATE_DESC', 'Newest'),
  title('TITLE_ROMAJI', 'Title'),
  searchMatch('SEARCH_MATCH', 'Best match');

  const AnimeSort(this.value, this.label);
  final String value;
  final String label;
}

/// Anime formats supported by AniList.
enum AnimeFormat {
  tv('TV', 'TV Show'),
  movie('MOVIE', 'Movie'),
  tvShort('TV_SHORT', 'TV Short'),
  ova('OVA', 'OVA'),
  ona('ONA', 'ONA'),
  special('SPECIAL', 'Special'),
  music('MUSIC', 'Music');

  const AnimeFormat(this.value, this.label);
  final String value;
  final String label;
}

/// Airing statuses supported by AniList.
enum AnimeStatus {
  releasing('RELEASING', 'Airing'),
  finished('FINISHED', 'Finished'),
  notYetReleased('NOT_YET_RELEASED', 'Upcoming'),
  cancelled('CANCELLED', 'Cancelled');

  const AnimeStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Anime release seasons.
enum AnimeSeason {
  winter('WINTER', 'Winter'),
  spring('SPRING', 'Spring'),
  summer('SUMMER', 'Summer'),
  fall('FALL', 'Fall');

  const AnimeSeason(this.value, this.label);
  final String value;
  final String label;
}

/// Age rating / adult content filter options.
enum AdultFilter {
  all('All'),
  safeOnly('Safe only'),
  adultOnly('18+ only');

  const AdultFilter(this.label);
  final String label;

  /// Translates to AniList GraphQL argument:
  /// - `all`: null (returns both safe and adult)
  /// - `safeOnly`: false (strictly non-adult)
  /// - `adultOnly`: true (strictly 18+ adult)
  bool? get isAdult => switch (this) {
    AdultFilter.all => null,
    AdultFilter.safeOnly => false,
    AdultFilter.adultOnly => true,
  };
}

/// Complete filter configuration for anime searches.
@immutable
class AnimeSearchFilter {
  const AnimeSearchFilter({
    this.sort,
    this.format,
    this.status,
    this.genre,
    this.season,
    this.year,
    this.adultFilter,
  });

  final AnimeSort? sort;
  final AnimeFormat? format;
  final AnimeStatus? status;
  final String? genre;
  final AnimeSeason? season;
  final int? year;
  final AdultFilter? adultFilter;

  static const AnimeSearchFilter empty = AnimeSearchFilter();

  bool get isDefault =>
      sort == null &&
      format == null &&
      status == null &&
      genre == null &&
      season == null &&
      year == null &&
      (adultFilter == null || adultFilter == AdultFilter.all);

  int get activeFilterCount {
    var count = 0;
    if (sort != null) count++;
    if (format != null) count++;
    if (status != null) count++;
    if (genre != null) count++;
    if (season != null) count++;
    if (year != null) count++;
    if (adultFilter != null && adultFilter != AdultFilter.all) count++;
    return count;
  }

  AnimeSearchFilter copyWith({
    AnimeSort? Function()? sort,
    AnimeFormat? Function()? format,
    AnimeStatus? Function()? status,
    String? Function()? genre,
    AnimeSeason? Function()? season,
    int? Function()? year,
    AdultFilter? Function()? adultFilter,
  }) {
    return AnimeSearchFilter(
      sort: sort != null ? sort() : this.sort,
      format: format != null ? format() : this.format,
      status: status != null ? status() : this.status,
      genre: genre != null ? genre() : this.genre,
      season: season != null ? season() : this.season,
      year: year != null ? year() : this.year,
      adultFilter: adultFilter != null ? adultFilter() : this.adultFilter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeSearchFilter &&
          runtimeType == other.runtimeType &&
          sort == other.sort &&
          format == other.format &&
          status == other.status &&
          genre == other.genre &&
          season == other.season &&
          year == other.year &&
          adultFilter == other.adultFilter;

  @override
  int get hashCode =>
      Object.hash(sort, format, status, genre, season, year, adultFilter);
}

