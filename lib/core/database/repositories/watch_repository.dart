import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/models/anime_media.dart';

typedef EpisodeProgressInfo = ({
  Duration position,
  Duration duration,
  double percent,
  bool isCompleted,
});

class ContinueWatchingItem {
  const ContinueWatchingItem({
    required this.anime,
    required this.history,
    this.episodeProgress,
  });

  final AnimeMedia anime;
  final WatchHistoryData history;
  final EpisodeProgressData? episodeProgress;

  int get episodeNumber => history.episodeNumber;
  double get percent => episodeProgress?.progressPercent ?? 0.0;
  Duration get position =>
      Duration(milliseconds: episodeProgress?.positionMs ?? 0);
  Duration get duration =>
      Duration(milliseconds: episodeProgress?.durationMs ?? 0);
  bool get isCompleted => episodeProgress?.isCompleted ?? false;
}

class WatchRepository {
  WatchRepository._internal();
  static final WatchRepository instance = WatchRepository._internal();
  factory WatchRepository() => instance;

  final AppDatabase _db = AppDatabase.instance;

  /// Ensures the anime record exists and is fresh in the database.
  Future<void> upsertAnime(AnimeMedia anime) async {
    await _db.into(_db.animeRecords).insertOnConflictUpdate(
          _animeToCompanion(anime),
        );
  }

  /// Saves playback progress for a specific episode and updates the
  /// anime-level WatchHistory entry in an atomic transaction.
  Future<void> saveProgress({
    required AnimeMedia anime,
    required int episodeNumber,
    String? episodeTitle,
    String? episodeThumbnail,
    required Duration position,
    required Duration duration,
    String? providerId,
    String? audio,
    String? server,
  }) async {
    final durMs = duration.inMilliseconds;
    if (durMs <= 0) return;
    final posMs = position.inMilliseconds;
    final percent = (posMs / durMs).clamp(0.0, 1.0);
    final isCompleted = percent >= 0.90;
    final now = DateTime.now();

    await _db.transaction(() async {
      // 1. Ensure anime record exists
      await _db.into(_db.animeRecords).insertOnConflictUpdate(
            _animeToCompanion(anime),
          );

      // 2. Save individual episode progress
      await _db.into(_db.episodeProgress).insertOnConflictUpdate(
            EpisodeProgressCompanion(
              animeId: Value(anime.id),
              episodeNumber: Value(episodeNumber),
              positionMs: Value(posMs),
              durationMs: Value(durMs),
              progressPercent: Value(percent),
              isCompleted: Value(isCompleted),
              updatedAt: Value(now),
            ),
          );

      // 3. Update anime-level watch history for Continue Watching
      await _db.into(_db.watchHistory).insertOnConflictUpdate(
            WatchHistoryCompanion(
              animeId: Value(anime.id),
              episodeNumber: Value(episodeNumber),
              episodeTitle: Value(episodeTitle),
              episodeThumbnail: Value(episodeThumbnail),
              positionMs: Value(posMs),
              durationMs: Value(durMs),
              progressPercent: Value(percent),
              isCompleted: Value(isCompleted),
              providerId: Value(providerId),
              audio: Value(audio ?? 'sub'),
              server: Value(server),
              lastWatchedAt: Value(now),
            ),
          );
    });
  }

  /// Saves anime watch state selection (episode, provider, audio, server).
  Future<void> saveWatchState(
    AnimeMedia anime, {
    required int episode,
    required String provider,
    required String audio,
    String? server,
    String? episodeTitle,
    String? episodeThumbnail,
  }) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.animeRecords).insertOnConflictUpdate(
            _animeToCompanion(anime),
          );

      // Check existing entry to retain server or provider if needed
      final existing = await (_db.select(_db.watchHistory)
            ..where((t) => t.animeId.equals(anime.id)))
          .getSingleOrNull();

      // Look up target episode progress in episodeProgress table
      final epProgress = await (_db.select(_db.episodeProgress)
            ..where((t) =>
                t.animeId.equals(anime.id) &
                t.episodeNumber.equals(episode)))
          .getSingleOrNull();

      final int posMs;
      final int durMs;
      final double percent;
      final bool completed;

      if (epProgress != null) {
        posMs = epProgress.positionMs;
        durMs = epProgress.durationMs;
        percent = epProgress.progressPercent;
        completed = epProgress.isCompleted;
      } else {
        // Never carry over previous episode's position to a different episode!
        posMs = 0;
        durMs = 0;
        percent = 0.0;
        completed = false;
      }

      await _db.into(_db.watchHistory).insertOnConflictUpdate(
            WatchHistoryCompanion(
              animeId: Value(anime.id),
              episodeNumber: Value(episode),
              episodeTitle: Value(
                episodeTitle ??
                    (existing != null && existing.episodeNumber == episode
                        ? existing.episodeTitle
                        : null),
              ),
              episodeThumbnail: Value(
                episodeThumbnail ??
                    (existing != null && existing.episodeNumber == episode
                        ? existing.episodeThumbnail
                        : null),
              ),
              providerId: Value(provider),
              audio: Value(audio),
              server: Value(server ?? existing?.server),
              lastWatchedAt: Value(now),
              positionMs: Value(posMs),
              durationMs: Value(durMs),
              progressPercent: Value(percent),
              isCompleted: Value(completed),
            ),
          );
    });
  }

  /// Retrieves progress for a specific episode.
  Future<EpisodeProgressInfo?> getEpisodeProgress(
      int animeId, int episodeNumber) async {
    final row = await (_db.select(_db.episodeProgress)
          ..where((t) =>
              t.animeId.equals(animeId) &
              t.episodeNumber.equals(episodeNumber)))
        .getSingleOrNull();

    if (row == null) return null;
    return (
      position: Duration(milliseconds: row.positionMs),
      duration: Duration(milliseconds: row.durationMs),
      percent: row.progressPercent,
      isCompleted: row.isCompleted,
    );
  }

  /// Retrieves progress for all episodes of an anime.
  Future<Map<int, EpisodeProgressInfo>> getAllEpisodeProgress(
      int animeId) async {
    final rows = await (_db.select(_db.episodeProgress)
          ..where((t) => t.animeId.equals(animeId)))
        .get();

    return {
      for (final r in rows)
        r.episodeNumber: (
          position: Duration(milliseconds: r.positionMs),
          duration: Duration(milliseconds: r.durationMs),
          percent: r.progressPercent,
          isCompleted: r.isCompleted,
        ),
    };
  }

  /// Returns a map of episode numbers to watched percentages for an anime.
  Future<Map<int, double>> getWatchedPercentages(int animeId) async {
    final rows = await (_db.select(_db.episodeProgress)
          ..where((t) => t.animeId.equals(animeId)))
        .get();

    return {for (final r in rows) r.episodeNumber: r.progressPercent};
  }

  /// Live reactive stream of watched percentages for an anime.
  Stream<Map<int, double>> watchWatchedPercentages(int animeId) {
    return (_db.select(_db.episodeProgress)
          ..where((t) => t.animeId.equals(animeId)))
        .watch()
        .map((rows) => {for (final r in rows) r.episodeNumber: r.progressPercent});
  }

  /// Retrieves anime-level watch state (last watched episode, provider, audio).
  Future<({int episode, String provider, String audio})?>
      getAnimeWatchState(int animeId) async {
    final row = await (_db.select(_db.watchHistory)
          ..where((t) => t.animeId.equals(animeId)))
        .getSingleOrNull();

    if (row == null) return null;
    return (
      episode: row.episodeNumber,
      provider: row.providerId ?? '',
      audio: row.audio,
    );
  }

  /// Live reactive stream of anime-level watch state.
  Stream<({int episode, String provider, String audio})?>
      watchAnimeWatchState(int animeId) {
    return (_db.select(_db.watchHistory)
          ..where((t) => t.animeId.equals(animeId)))
        .watchSingleOrNull()
        .map((row) {
      if (row == null) return null;
      return (
        episode: row.episodeNumber,
        provider: row.providerId ?? '',
        audio: row.audio,
      );
    });
  }

  /// Retrieves playback preferences specific to an anime.
  Future<AnimePreference?> getAnimePreferences(int animeId) async {
    return (_db.select(_db.animePreferences)
          ..where((t) => t.animeId.equals(animeId)))
        .getSingleOrNull();
  }

  /// Live reactive stream of playback preferences for an anime.
  Stream<AnimePreference?> watchAnimePreferences(int animeId) {
    return (_db.select(_db.animePreferences)
          ..where((t) => t.animeId.equals(animeId)))
        .watchSingleOrNull();
  }

  /// Updates playback preferences for an anime, retaining existing fields if not specified.
  Future<void> saveAnimePreferences(
    int animeId, {
    AnimeMedia? anime,
    String? provider,
    String? audio,
    String? server,
    String? subtitleTrack,
    double? playbackSpeed,
    String? quality,
  }) async {
    if (anime != null) {
      await upsertAnime(anime);
    } else {
      final existingRecord = await (_db.select(_db.animeRecords)
            ..where((t) => t.id.equals(animeId)))
          .getSingleOrNull();
      if (existingRecord == null) {
        // Guarantee foreign key constraint is satisfied even if anime object is omitted
        await _db.into(_db.animeRecords).insertOnConflictUpdate(
              AnimeRecordsCompanion(
                id: Value(animeId),
                title: const Value('Anime'),
                updatedAt: Value(DateTime.now()),
              ),
            );
      }
    }

    final existing = await getAnimePreferences(animeId);

    await _db.into(_db.animePreferences).insertOnConflictUpdate(
          AnimePreferencesCompanion(
            animeId: Value(animeId),
            preferredProvider: Value(provider ?? existing?.preferredProvider),
            preferredAudio: Value(audio ?? existing?.preferredAudio),
            preferredServer: Value(server ?? existing?.preferredServer),
            preferredSubtitleTrack:
                Value(subtitleTrack ?? existing?.preferredSubtitleTrack),
            customPlaybackSpeed:
                Value(playbackSpeed ?? existing?.customPlaybackSpeed),
            preferredQuality: Value(quality ?? existing?.preferredQuality),
          ),
        );
  }

  /// Live reactive stream of Continue Watching items ordered by latest watched.
  Stream<List<ContinueWatchingItem>> watchContinueWatching({int limit = 20}) {
    final query = (_db.select(_db.watchHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.lastWatchedAt)])
          ..limit(limit))
        .join([
      innerJoin(
        _db.animeRecords,
        _db.animeRecords.id.equalsExp(_db.watchHistory.animeId),
      ),
      leftOuterJoin(
        _db.episodeProgress,
        _db.episodeProgress.animeId.equalsExp(_db.watchHistory.animeId) &
            _db.episodeProgress.episodeNumber
                .equalsExp(_db.watchHistory.episodeNumber),
      ),
    ]);

    return query.watch().asyncMap((rows) async {
      final items = <ContinueWatchingItem>[];
      for (final row in rows) {
        final history = row.readTable(_db.watchHistory);
        final animeRecord = row.readTable(_db.animeRecords);
        final epProgress = row.readTableOrNull(_db.episodeProgress);

        final hasCurrentProgress = epProgress != null &&
            (epProgress.positionMs > 0 || epProgress.isCompleted);

        if (hasCurrentProgress) {
          items.add(ContinueWatchingItem(
            anime: _recordToAnime(animeRecord),
            history: history,
            episodeProgress: epProgress,
          ));
          continue;
        }

        // If current episode has no recorded progress, check if ANY episode
        // of this anime was watched (e.g. user finished Ep 1–3, Ep 4 is next up).
        final hasAnyProgress = await (_db.select(_db.episodeProgress)
              ..where((t) =>
                  t.animeId.equals(history.animeId) &
                  (t.isCompleted.equals(true) |
                      t.positionMs.isBiggerThanValue(0)))
              ..limit(1))
            .getSingleOrNull() !=
            null;

        if (hasAnyProgress) {
          items.add(ContinueWatchingItem(
            anime: _recordToAnime(animeRecord),
            history: history,
            episodeProgress: epProgress,
          ));
        } else {
          // Phantom entry from an aborted stream load where playback never started.
          // Clean it up from watchHistory so it doesn't linger in Continue Watching.
          await (_db.delete(_db.watchHistory)
                ..where((t) => t.animeId.equals(history.animeId)))
              .go();
        }
      }
      return items;
    });
  }

  /// Removes an anime from watch history (hiding it from Continue Watching).
  Future<void> removeFromHistory(int animeId) async {
    await (_db.delete(_db.watchHistory)
          ..where((t) => t.animeId.equals(animeId)))
        .go();
  }

  /// Completely clears all watch history and episode playback progress.
  Future<void> clearAllWatchHistory() async {
    await _db.transaction(() async {
      await _db.delete(_db.watchHistory).go();
      await _db.delete(_db.episodeProgress).go();
    });
  }

  /// Marks a single episode as fully watched.
  Future<void> markEpisodeWatched({
    required AnimeMedia anime,
    required int episodeNumber,
    String? episodeTitle,
    String? episodeThumbnail,
  }) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.into(_db.animeRecords).insertOnConflictUpdate(
            _animeToCompanion(anime),
          );

      await _db.into(_db.episodeProgress).insertOnConflictUpdate(
            EpisodeProgressCompanion(
              animeId: Value(anime.id),
              episodeNumber: Value(episodeNumber),
              positionMs: const Value(24 * 60 * 1000),
              durationMs: const Value(24 * 60 * 1000),
              progressPercent: const Value(1.0),
              isCompleted: const Value(true),
              updatedAt: Value(now),
            ),
          );

      final currentHistory = await (_db.select(_db.watchHistory)
            ..where((t) => t.animeId.equals(anime.id)))
          .getSingleOrNull();

      if (currentHistory == null || episodeNumber >= currentHistory.episodeNumber) {
        await _db.into(_db.watchHistory).insertOnConflictUpdate(
              WatchHistoryCompanion(
                animeId: Value(anime.id),
                episodeNumber: Value(episodeNumber),
                episodeTitle: Value(episodeTitle ?? currentHistory?.episodeTitle),
                episodeThumbnail: Value(episodeThumbnail ?? currentHistory?.episodeThumbnail),
                positionMs: const Value(24 * 60 * 1000),
                durationMs: const Value(24 * 60 * 1000),
                progressPercent: const Value(1.0),
                isCompleted: const Value(true),
                providerId: Value(currentHistory?.providerId),
                audio: Value(currentHistory?.audio ?? 'sub'),
                server: Value(currentHistory?.server),
                lastWatchedAt: Value(now),
              ),
            );
      }
    });
  }

  /// Marks a single episode as unwatched (clears progress).
  Future<void> markEpisodeUnwatched({
    required int animeId,
    required int episodeNumber,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.episodeProgress)
            ..where((t) =>
                t.animeId.equals(animeId) &
                t.episodeNumber.equals(episodeNumber)))
          .go();

      // Check if watchHistory was pointing to this episode
      final currentHistory = await (_db.select(_db.watchHistory)
            ..where((t) => t.animeId.equals(animeId)))
          .getSingleOrNull();

      if (currentHistory != null && currentHistory.episodeNumber == episodeNumber) {
        // Find latest remaining episode in episodeProgress
        final latest = await (_db.select(_db.episodeProgress)
              ..where((t) => t.animeId.equals(animeId))
              ..orderBy([(t) => OrderingTerm.desc(t.episodeNumber)])
              ..limit(1))
            .getSingleOrNull();

        if (latest != null) {
          await _db.into(_db.watchHistory).insertOnConflictUpdate(
                WatchHistoryCompanion(
                  animeId: Value(animeId),
                  episodeNumber: Value(latest.episodeNumber),
                  positionMs: Value(latest.positionMs),
                  durationMs: Value(latest.durationMs),
                  progressPercent: Value(latest.progressPercent),
                  isCompleted: Value(latest.isCompleted),
                  providerId: Value(currentHistory.providerId),
                  audio: Value(currentHistory.audio),
                  server: Value(currentHistory.server),
                  lastWatchedAt: Value(latest.updatedAt),
                ),
              );
        } else {
          // No watched episodes remain, clear watchHistory
          await (_db.delete(_db.watchHistory)
                ..where((t) => t.animeId.equals(animeId)))
              .go();
        }
      }
    });
  }

  /// Marks all episodes up to [upToEpisodeNumber] as watched.
  Future<void> markPreviousEpisodesWatched({
    required AnimeMedia anime,
    required int upToEpisodeNumber,
    List<int>? availableEpisodeNumbers,
  }) async {
    final now = DateTime.now();
    final numbers = (availableEpisodeNumbers != null && availableEpisodeNumbers.isNotEmpty)
        ? availableEpisodeNumbers
        : List.generate(upToEpisodeNumber, (i) => i + 1);

    await _db.transaction(() async {
      await _db.into(_db.animeRecords).insertOnConflictUpdate(
            _animeToCompanion(anime),
          );

      final companions = <EpisodeProgressCompanion>[];
      for (final num in numbers) {
        if (num <= upToEpisodeNumber) {
          companions.add(
            EpisodeProgressCompanion(
              animeId: Value(anime.id),
              episodeNumber: Value(num),
              positionMs: const Value(24 * 60 * 1000),
              durationMs: const Value(24 * 60 * 1000),
              progressPercent: const Value(1.0),
              isCompleted: const Value(true),
              updatedAt: Value(now),
            ),
          );
        }
      }

      if (companions.isNotEmpty) {
        await _db.batch((b) {
          b.insertAllOnConflictUpdate(_db.episodeProgress, companions);
        });
      }

      final currentHistory = await (_db.select(_db.watchHistory)
            ..where((t) => t.animeId.equals(anime.id)))
          .getSingleOrNull();

      if (currentHistory == null || upToEpisodeNumber >= currentHistory.episodeNumber) {
        await _db.into(_db.watchHistory).insertOnConflictUpdate(
              WatchHistoryCompanion(
                animeId: Value(anime.id),
                episodeNumber: Value(upToEpisodeNumber),
                positionMs: const Value(24 * 60 * 1000),
                durationMs: const Value(24 * 60 * 1000),
                progressPercent: const Value(1.0),
                isCompleted: const Value(true),
                providerId: Value(currentHistory?.providerId),
                audio: Value(currentHistory?.audio ?? 'sub'),
                server: Value(currentHistory?.server),
                lastWatchedAt: Value(now),
              ),
            );
      }
    });
  }

  /// Unmarks all episodes up to [upToEpisodeNumber] (clears progress).
  Future<void> unmarkPreviousEpisodes({
    required int animeId,
    required int upToEpisodeNumber,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.episodeProgress)
            ..where((t) =>
                t.animeId.equals(animeId) &
                t.episodeNumber.isSmallerOrEqualValue(upToEpisodeNumber)))
          .go();

      final currentHistory = await (_db.select(_db.watchHistory)
            ..where((t) => t.animeId.equals(animeId)))
          .getSingleOrNull();

      if (currentHistory != null && currentHistory.episodeNumber <= upToEpisodeNumber) {
        final latest = await (_db.select(_db.episodeProgress)
              ..where((t) => t.animeId.equals(animeId))
              ..orderBy([(t) => OrderingTerm.desc(t.episodeNumber)])
              ..limit(1))
            .getSingleOrNull();

        if (latest != null) {
          await _db.into(_db.watchHistory).insertOnConflictUpdate(
                WatchHistoryCompanion(
                  animeId: Value(animeId),
                  episodeNumber: Value(latest.episodeNumber),
                  positionMs: Value(latest.positionMs),
                  durationMs: Value(latest.durationMs),
                  progressPercent: Value(latest.progressPercent),
                  isCompleted: Value(latest.isCompleted),
                  providerId: Value(currentHistory.providerId),
                  audio: Value(currentHistory.audio),
                  server: Value(currentHistory.server),
                  lastWatchedAt: Value(latest.updatedAt),
                ),
              );
        } else {
          await (_db.delete(_db.watchHistory)
                ..where((t) => t.animeId.equals(animeId)))
              .go();
        }
      }
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
