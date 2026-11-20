import 'package:drift/drift.dart';

/// Stores metadata and local status for installed streaming extensions.
class InstalledExtensions extends Table {
  /// Unique identifier of the extension (e.g. "gogoanime", "anikoto")
  TextColumn get id => text()();

  /// User-friendly display name (e.g. "Gogoanime")
  TextColumn get name => text()();

  /// Semantic version string (e.g. "1.0.2")
  TextColumn get version => text()();

  /// Integer version code for easy update comparison
  IntColumn get versionCode => integer()();

  /// Author or maintainer of the extension
  TextColumn get author =>
      text().withDefault(const Constant('Aniways Community'))();

  /// Remote URL or local asset path to extension icon
  TextColumn get iconUrl => text().nullable()();

  /// Short summary of the provider
  TextColumn get description => text().nullable()();

  /// JSON array of supported audio streams, e.g. '["sub", "dub"]'
  TextColumn get audio => text().withDefault(const Constant('["sub"]'))();

  /// Primary language code (e.g. "en")
  TextColumn get lang => text().withDefault(const Constant('en'))();

  /// Base web URL of the target streaming site
  TextColumn get baseUrl => text().nullable()();

  /// Whether the user has toggled this provider active for playback
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  /// Order preference for multi-provider fallback (lower = higher priority)
  IntColumn get priorityIndex => integer().withDefault(const Constant(0))();

  /// Absolute local file path where the .js bundle is saved
  TextColumn get localScriptPath => text()();

  /// Remote repository URL from which this extension was installed
  TextColumn get repoUrl => text().nullable()();

  /// Timestamp when first installed
  DateTimeColumn get installedAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamp when last updated
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

