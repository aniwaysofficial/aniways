import 'package:drift/drift.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/core/services/background_notification_worker.dart';
import 'package:aniways/models/anime_media.dart';

/// Repository for managing anime episode release notification subscriptions.
class SubscriptionRepository {
  SubscriptionRepository._();
  static final SubscriptionRepository instance = SubscriptionRepository._();
  factory SubscriptionRepository() => instance;

  final AppDatabase _db = AppDatabase.instance;

  /// Checks if an anime is actively subscribed for release notifications.
  Future<bool> isSubscribed(int animeId) async {
    final entry = await (_db.select(_db.episodeSubscriptions)
          ..where((t) => t.animeId.equals(animeId) & t.isSubscribed.equals(true)))
        .getSingleOrNull();
    return entry != null;
  }

  /// Live reactive stream of whether an anime is subscribed.
  Stream<bool> watchIsSubscribed(int animeId) {
    return (_db.select(_db.episodeSubscriptions)
          ..where((t) => t.animeId.equals(animeId)))
        .watchSingleOrNull()
        .map((entry) => entry?.isSubscribed ?? false);
  }

  /// Checks whether an anime can be subscribed to for release notifications.
  /// Finished or cancelled anime cannot be subscribed.
  bool canSubscribe(AnimeMedia anime, [NextAiring? nextAiring]) {
    final status = anime.status?.toUpperCase();
    if (status == 'FINISHED' || status == 'CANCELLED') {
      return false;
    }
    if (nextAiring != null || anime.nextAiring != null) {
      return true;
    }
    return status == 'RELEASING' || status == 'NOT_YET_RELEASED';
  }

  /// Toggles subscription status. Returns the new subscription state.
  Future<bool> toggleSubscription(AnimeMedia anime, NextAiring? nextAiring) async {
    final subscribed = await isSubscribed(anime.id);
    if (subscribed) {
      await unsubscribe(anime.id);
      return false;
    } else {
      if (!canSubscribe(anime, nextAiring)) {
        return false;
      }
      await subscribe(
        anime,
        episode: nextAiring?.episode,
        airingAt: nextAiring != null
            ? DateTime.fromMillisecondsSinceEpoch(nextAiring.airingAt * 1000)
            : null,
      );
      return true;
    }
  }

  /// Subscribes an anime for episode release notifications.
  Future<void> subscribe(
    AnimeMedia anime, {
    int? episode,
    DateTime? airingAt,
  }) async {
    if (!canSubscribe(anime, anime.nextAiring)) {
      return;
    }

    final epNum = episode ?? anime.nextAiring?.episode ?? 1;
    final airTime = airingAt ??
        (anime.nextAiring != null
            ? DateTime.fromMillisecondsSinceEpoch(
                anime.nextAiring!.airingAt * 1000,
              )
            : DateTime.now().add(const Duration(days: 7)));

    await _db.into(_db.episodeSubscriptions).insertOnConflictUpdate(
          EpisodeSubscriptionsCompanion(
            animeId: Value(anime.id),
            animeTitle: Value(anime.title),
            coverUrl: Value(anime.coverUrl),
            nextEpisodeNumber: Value(epNum),
            nextAiringAt: Value(airTime),
            isSubscribed: const Value(true),
          ),
        );

    final sub = await (_db.select(_db.episodeSubscriptions)
          ..where((t) => t.animeId.equals(anime.id)))
        .getSingleOrNull();
    if (sub != null) {
      await BackgroundNotificationWorker.scheduleForSubscription(sub);
    }
  }

  /// Unsubscribes an anime series from release alerts.
  Future<void> unsubscribe(int animeId) async {
    await (_db.update(_db.episodeSubscriptions)
          ..where((t) => t.animeId.equals(animeId)))
        .write(const EpisodeSubscriptionsCompanion(isSubscribed: Value(false)));
    await BackgroundNotificationWorker.cancelForSubscription(animeId);
  }

  /// Gets all active subscriptions.
  Future<List<EpisodeSubscription>> getActiveSubscriptions() {
    return (_db.select(_db.episodeSubscriptions)
          ..where((t) => t.isSubscribed.equals(true)))
        .get();
  }

  /// Updates the next airing episode schedule for an anime.
  Future<void> updateNextAiring(
    int animeId,
    int nextEpisode,
    DateTime nextAiringAt,
  ) async {
    await (_db.update(_db.episodeSubscriptions)
          ..where((t) => t.animeId.equals(animeId)))
        .write(
      EpisodeSubscriptionsCompanion(
        nextEpisodeNumber: Value(nextEpisode),
        nextAiringAt: Value(nextAiringAt),
        retryCount: const Value(0),
      ),
    );
  }

  /// Records that a notification was dispatched for [episodeNumber].
  Future<void> recordNotified(int animeId, int episodeNumber) async {
    await (_db.update(_db.episodeSubscriptions)
          ..where((t) => t.animeId.equals(animeId)))
        .write(
      EpisodeSubscriptionsCompanion(
        lastNotifiedEpisode: Value(episodeNumber),
        lastCheckedAt: Value(DateTime.now()),
        retryCount: const Value(0),
      ),
    );
  }

  /// Records that an availability check was performed and increments retry count.
  Future<void> recordCheckAttempt(int animeId) async {
    final entry = await (_db.select(_db.episodeSubscriptions)
          ..where((t) => t.animeId.equals(animeId)))
        .getSingleOrNull();
    if (entry != null) {
      await (_db.update(_db.episodeSubscriptions)
            ..where((t) => t.animeId.equals(animeId)))
          .write(
        EpisodeSubscriptionsCompanion(
          lastCheckedAt: Value(DateTime.now()),
          retryCount: Value(entry.retryCount + 1),
        ),
      );
    }
  }
}

