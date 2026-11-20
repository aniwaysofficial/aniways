import 'package:drift/drift.dart';
import 'anime_records.dart';

/// Tracks anime-level watch history, latest episode, and timestamp for
/// "Continue Watching" ordering.
class WatchHistory extends Table {
  IntColumn get animeId => integer().references(AnimeRecords, #id)();
  IntColumn get episodeNumber => integer()();
  TextColumn get episodeTitle => text().nullable()();
  TextColumn get episodeThumbnail => text().nullable()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  RealColumn get progressPercent => real().withDefault(const Constant(0.0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get providerId => text().nullable()();
  TextColumn get audio => text().withDefault(const Constant('sub'))();
  TextColumn get server => text().nullable()();
  DateTimeColumn get lastWatchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {animeId};
}

