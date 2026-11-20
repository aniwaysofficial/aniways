import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/core/database/repositories/subscription_repository.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/models/collection_status.dart';

class CollectionRepository {
  CollectionRepository._internal() {
    _initFavoritesCache();
  }
  static final CollectionRepository instance = CollectionRepository._internal();
  factory CollectionRepository() => instance;

  final AppDatabase _db = AppDatabase.instance;

  static String get favoritesId => CollectionStatus.favorites.id;
  static final List<String> statusCollectionIds =
      CollectionStatus.watchStatuses.map((s) => s.id).toList(growable: false);

  /// In-memory cache of all favorite anime IDs, kept live via a single database stream.
  final ValueNotifier<Set<int>> favoritesNotifier = ValueNotifier<Set<int>>({});
  StreamSubscription<List<CollectionEntry>>? _favoritesSub;

  void _initFavoritesCache() {
    _favoritesSub ??= (_db.select(_db.collectionEntries)
          ..where((t) => t.collectionId.equals(favoritesId)))
        .watch()
        .listen((entries) {
      favoritesNotifier.value = entries.map((e) => e.animeId).toSet();
    });
  }

  /// Instant, synchronous in-memory favorite check ($O(1)$) with zero SQLite query latency.
  bool isFavoriteSync(int animeId) {
    if (_favoritesSub == null) _initFavoritesCache();
    return favoritesNotifier.value.contains(animeId);
  }

  /// Checks if an anime is in the favorites list.
  Future<bool> isFavorite(int animeId) async {
    final entry = await (_db.select(_db.collectionEntries)
          ..where((t) =>
              t.collectionId.equals(favoritesId) &
              t.animeId.equals(animeId)))
        .getSingleOrNull();
    return entry != null;
  }

  /// Live reactive stream of whether an anime is favorite.
  Stream<bool> watchIsFavorite(int animeId) {
    return (_db.select(_db.collectionEntries)
          ..where((t) =>
              t.collectionId.equals(favoritesId) &
              t.animeId.equals(animeId)))
        .watchSingleOrNull()
        .map((entry) => entry != null);
  }

  /// Toggles favorite status for an anime. Returns true if added, false if removed.
  Future<bool> toggleFavorite(AnimeMedia anime) async {
    final isFav = await isFavorite(anime.id);

    if (isFav) {
      await (_db.delete(_db.collectionEntries)
            ..where((t) =>
                t.collectionId.equals(favoritesId) &
                t.animeId.equals(anime.id)))
          .go();
      return false;
    } else {
      await _db.transaction(() async {
        // Ensure anime record exists
        await _db.into(_db.animeRecords).insertOnConflictUpdate(
              _animeToCompanion(anime),
            );

        await _db.into(_db.collectionEntries).insertOnConflictUpdate(
              CollectionEntriesCompanion.insert(
                collectionId: favoritesId,
                animeId: anime.id,
                addedAt: Value(DateTime.now()),
              ),
            );
      });
      return true;
    }
  }

  /// Sets the primary watch status of an anime (e.g. 'watching', 'plan_to_watch').
  /// Mutually excludes other status categories so an anime has only one active status.
  Future<void> setAnimeStatus(AnimeMedia anime, String? newStatusCollectionId) async {
    await _db.transaction(() async {
      await _db.into(_db.animeRecords).insertOnConflictUpdate(
            _animeToCompanion(anime),
          );

      // Remove from existing status collections
      await (_db.delete(_db.collectionEntries)
            ..where((t) =>
                t.animeId.equals(anime.id) &
                t.collectionId.isIn(statusCollectionIds)))
          .go();

      // If a new status is chosen, insert it
      if (newStatusCollectionId != null &&
          statusCollectionIds.contains(newStatusCollectionId)) {
        await _db.into(_db.collectionEntries).insertOnConflictUpdate(
              CollectionEntriesCompanion.insert(
                collectionId: newStatusCollectionId,
                animeId: anime.id,
                addedAt: Value(DateTime.now()),
              ),
            );
      }
    });

    // Auto-manage episode release notifications based on watch status
    try {
      if (newStatusCollectionId == 'watching') {
        if (SharedPreferencesService().notificationAutoSubscribeWatching) {
          if (SubscriptionRepository.instance.canSubscribe(anime)) {
            await SubscriptionRepository.instance.subscribe(anime);
          }
        }
      } else if (newStatusCollectionId == 'completed' ||
          newStatusCollectionId == 'dropped' ||
          newStatusCollectionId == null) {
        await SubscriptionRepository.instance.unsubscribe(anime.id);
      }
    } catch (_) {}
  }

  /// Gets the current watch status of an anime, or null if none is set.
  Future<String?> getAnimeStatus(int animeId) async {
    final entry = await (_db.select(_db.collectionEntries)
          ..where((t) =>
              t.animeId.equals(animeId) &
              t.collectionId.isIn(statusCollectionIds)))
        .getSingleOrNull();

    return entry?.collectionId;
  }

  /// Live reactive stream of the anime's current watch status.
  Stream<String?> watchAnimeStatus(int animeId) {
    return (_db.select(_db.collectionEntries)
          ..where((t) =>
              t.animeId.equals(animeId) &
              t.collectionId.isIn(statusCollectionIds)))
        .watchSingleOrNull()
        .map((entry) => entry?.collectionId);
  }

  /// Live reactive stream of all anime in a specific collection, ordered newest first.
  Stream<List<AnimeMedia>> watchCollection(String collectionId) {
    final query = (_db.select(_db.collectionEntries)
          ..where((t) => t.collectionId.equals(collectionId))
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .join([
      innerJoin(
        _db.animeRecords,
        _db.animeRecords.id.equalsExp(_db.collectionEntries.animeId),
      ),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final record = row.readTable(_db.animeRecords);
        return _recordToAnime(record);
      }).toList();
    });
  }

  /// Gets all anime IDs in a specific collection, ordered newest first.
  Future<List<int>> getCollectionAnimeIds(String collectionId) async {
    final query = _db.select(_db.collectionEntries)
      ..where((t) => t.collectionId.equals(collectionId))
      ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]);
    final entries = await query.get();
    return entries.map((e) => e.animeId).toList();
  }

  /// Live reactive stream of all anime IDs in a specific collection.
  Stream<Set<int>> watchCollectionAnimeIds(String collectionId) {
    final query = _db.select(_db.collectionEntries)
      ..where((t) => t.collectionId.equals(collectionId));
    return query.watch().map((entries) => entries.map((e) => e.animeId).toSet());
  }

  /// Gets anime IDs that should never be recommended:
  /// completed, watching, and dropped.
  Future<Set<int>> getExcludedRecommendationIds() async {
    final query = _db.select(_db.collectionEntries)
      ..where((t) => t.collectionId.isIn(const [
            'completed',
            'watching',
            'dropped',
          ]));
    final entries = await query.get();
    return entries.map((e) => e.animeId).toSet();
  }

  /// Live reactive stream of all available collections ordered by sortOrder.
  Stream<List<Collection>> watchCollections() {
    return (_db.select(_db.collections)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Live reactive stream of item counts mapped by collectionId:
  /// e.g. `{'favorites': 4, 'watching': 2, ...}`
  Stream<Map<String, int>> watchAllCollectionCounts() {
    final countExp = _db.collectionEntries.animeId.count();
    final query = _db.selectOnly(_db.collectionEntries)
      ..addColumns([_db.collectionEntries.collectionId, countExp])
      ..groupBy([_db.collectionEntries.collectionId]);

    return query.watch().map((rows) {
      final map = <String, int>{};
      for (final row in rows) {
        final colId = row.read(_db.collectionEntries.collectionId);
        final count = row.read(countExp);
        if (colId != null && count != null) {
          map[colId] = count;
        }
      }
      return map;
    });
  }

  /// Helper: converts AnimeMedia to Drift Companion
  static AnimeRecordsCompanion _animeToCompanion(AnimeMedia anime) {
    return AnimeRecordsCompanion.insert(
      id: Value(anime.id),
      malId: Value(anime.idMal),
      title: anime.title,
      romajiTitle: Value(anime.romajiTitle),
      englishTitle: Value(anime.englishTitle),
      coverUrl: Value(anime.coverUrl),
      bannerUrl: Value(anime.bannerUrl),
      coverColor: Value(anime.coverColor),
      format: Value(anime.format),
      status: Value(anime.status),
      totalEpisodes: Value(anime.episodes),
      averageScore: Value(anime.averageScore),
      genres: Value(json.encode(anime.genres)),
      updatedAt: Value(DateTime.now()),
    );
  }

  /// Helper: converts Drift AnimeRecord to AnimeMedia
  static AnimeMedia _recordToAnime(AnimeRecord record) {
    List<String> parsedGenres = const [];
    try {
      final decoded = json.decode(record.genres);
      if (decoded is List) {
        parsedGenres = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return AnimeMedia(
      id: record.id,
      idMal: record.malId,
      romajiTitle: record.romajiTitle ?? record.title,
      englishTitle: record.englishTitle,
      coverUrl: record.coverUrl,
      bannerUrl: record.bannerUrl,
      coverColor: record.coverColor,
      format: record.format,
      status: record.status,
      episodes: record.totalEpisodes,
      averageScore: record.averageScore,
      genres: parsedGenres,
    );
  }
}

