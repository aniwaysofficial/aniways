import 'package:drift/drift.dart';

/// Caches anime metadata locally so saved items, history, and collections
/// can be rendered instantly offline without AniList network calls.
class AnimeRecords extends Table {
  IntColumn get id => integer()();
  IntColumn get malId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get romajiTitle => text().nullable()();
  TextColumn get englishTitle => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get bannerUrl => text().nullable()();
  IntColumn get coverColor => integer().nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get status => text().nullable()();
  IntColumn get totalEpisodes => integer().nullable()();
  IntColumn get averageScore => integer().nullable()();
  TextColumn get genres => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

