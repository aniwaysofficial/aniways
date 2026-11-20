import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/anime_preferences.dart';
import 'tables/anime_records.dart';
import 'tables/collection_entries.dart';
import 'tables/collections.dart';
import 'tables/episode_progress.dart';
import 'tables/episode_subscriptions.dart';
import 'tables/extension_repositories.dart';
import 'tables/installed_extensions.dart';
import 'tables/watch_history.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  AnimeRecords,
  WatchHistory,
  EpisodeProgress,
  Collections,
  CollectionEntries,
  AnimePreferences,
  EpisodeSubscriptions,
  InstalledExtensions,
  ExtensionRepositories,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  /// Constructor for unit testing with in-memory SQLite.
  AppDatabase.forTesting(super.e);

  static final AppDatabase instance = AppDatabase._();

  factory AppDatabase() => instance;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _seedDefaultCollections();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(episodeSubscriptions);
        }
        if (from < 3) {
          await m.createTable(installedExtensions);
          await m.createTable(extensionRepositories);
        }
      },
      beforeOpen: (details) async {
        // Enforce SQLite relational integrity and optimize performance
        try {
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA synchronous = NORMAL;');
        } catch (_) {}

        // Ensure performance indexes exist
        try {
          // Index for Continue Watching queries ordered by last watched timestamp
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_watch_history_last_watched '
            'ON watch_history(last_watched_at DESC);',
          );
          // Secondary index on collection_entries(anime_id) for status queries
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_collection_entries_anime_id '
            'ON collection_entries(anime_id);',
          );
          // Index for episode progress ordering and lookups
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_episode_progress_updated_at '
            'ON episode_progress(updated_at DESC);',
          );
        } catch (_) {}
      },
    );
  }

  Future<void> _seedDefaultCollections() async {
    final now = DateTime.now();
    final defaultCollections = [
      CollectionsCompanion.insert(
        id: 'favorites',
        name: 'Favorites',
        description: const Value('Your favorite anime series'),
        isSystem: const Value(true),
        iconName: const Value('favorite'),
        sortOrder: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CollectionsCompanion.insert(
        id: 'watching',
        name: 'Watching',
        description: const Value('Currently watching'),
        isSystem: const Value(true),
        iconName: const Value('play_arrow'),
        sortOrder: const Value(1),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CollectionsCompanion.insert(
        id: 'plan_to_watch',
        name: 'Plan to Watch',
        description: const Value('Saved to watch later'),
        isSystem: const Value(true),
        iconName: const Value('bookmark'),
        sortOrder: const Value(2),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CollectionsCompanion.insert(
        id: 'completed',
        name: 'Completed',
        description: const Value('Finished anime series'),
        isSystem: const Value(true),
        iconName: const Value('check_circle'),
        sortOrder: const Value(3),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CollectionsCompanion.insert(
        id: 'on_hold',
        name: 'On Hold',
        description: const Value('Temporarily paused'),
        isSystem: const Value(true),
        iconName: const Value('pause'),
        sortOrder: const Value(4),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CollectionsCompanion.insert(
        id: 'dropped',
        name: 'Dropped',
        description: const Value('Discontinued watching'),
        isSystem: const Value(true),
        iconName: const Value('cancel'),
        sortOrder: const Value(5),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ];

    await batch((b) {
      b.insertAll(collections, defaultCollections);
    });
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'aniways');
  }
}

