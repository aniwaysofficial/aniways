import 'package:drift/drift.dart';
import 'anime_records.dart';

/// Tracks exact playback progress and completion for individual episodes.
class EpisodeProgress extends Table {
  IntColumn get animeId => integer().references(AnimeRecords, #id)();
  IntColumn get episodeNumber => integer()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  RealColumn get progressPercent => real().withDefault(const Constant(0.0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {animeId, episodeNumber};
}

