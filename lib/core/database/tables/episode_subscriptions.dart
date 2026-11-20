import 'package:drift/drift.dart';

/// Tracks anime series subscribed for new episode release notifications.
class EpisodeSubscriptions extends Table {
  /// AniList Media ID
  IntColumn get animeId => integer()();

  /// Preferred title for notification headers
  TextColumn get animeTitle => text()();

  /// Artwork URL for notification icons
  TextColumn get coverUrl => text().nullable()();

  /// The next episode number scheduled to air
  IntColumn get nextEpisodeNumber => integer()();

  /// The broadcast timestamp from AniList (Japan TV broadcast)
  DateTimeColumn get nextAiringAt => dateTime()();

  /// The last episode number that was verified and notified
  IntColumn get lastNotifiedEpisode =>
      integer().withDefault(const Constant(0))();

  /// Whether the user actively wants notifications for this anime
  BoolColumn get isSubscribed => boolean().withDefault(const Constant(true))();

  /// The last time provider availability was checked
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();

  /// Number of retry checks performed since airingAt
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {animeId};
}

