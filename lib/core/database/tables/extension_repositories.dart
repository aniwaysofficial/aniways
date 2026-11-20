import 'package:drift/drift.dart';

/// Stores configured remote extension repositories (e.g. GitHub repos).
class ExtensionRepositories extends Table {
  /// Unique repository ID (e.g. "aniways-official")
  TextColumn get id => text()();

  /// Repository display name
  TextColumn get name => text()();

  /// HTTPS URL pointing to the repository's index.json
  TextColumn get url => text()();

  /// Whether this repository is active for update checks & browsing
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  /// When the repository catalog was last fetched
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

