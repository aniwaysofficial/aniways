import 'package:drift/drift.dart';
import 'anime_records.dart';

/// Stores user playback preferences specific to a single anime.
class AnimePreferences extends Table {
  IntColumn get animeId => integer().references(AnimeRecords, #id)();
  TextColumn get preferredProvider => text().nullable()();
  TextColumn get preferredAudio => text().nullable()();
  TextColumn get preferredServer => text().nullable()();
  TextColumn get preferredSubtitleTrack => text().nullable()();
  RealColumn get customPlaybackSpeed => real().nullable()();
  TextColumn get preferredQuality => text().nullable()();

  @override
  Set<Column> get primaryKey => {animeId};
}

