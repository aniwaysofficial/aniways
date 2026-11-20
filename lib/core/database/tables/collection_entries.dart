import 'package:drift/drift.dart';
import 'anime_records.dart';
import 'collections.dart';

/// Maps an anime to a collection, optionally storing user ratings or notes.
class CollectionEntries extends Table {
  TextColumn get collectionId => text().references(Collections, #id)();
  IntColumn get animeId => integer().references(AnimeRecords, #id)();
  RealColumn get userScore => real().nullable()();
  TextColumn get userNotes => text().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {collectionId, animeId};
}

