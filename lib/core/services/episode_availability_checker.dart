import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';

/// Report containing provider availability status for a released episode.
class AvailabilityReport {
  const AvailabilityReport({
    required this.anilistId,
    required this.episodeNumber,
    required this.isAvailable,
    required this.availableCount,
    required this.providerNames,
    required this.audioLabel,
  });

  final int anilistId;
  final int episodeNumber;
  final bool isAvailable;
  final int availableCount;
  final List<String> providerNames;
  final String audioLabel;
}

/// Service that actively checks video provider availability before notifying users.
class EpisodeAvailabilityChecker {
  EpisodeAvailabilityChecker._();
  static final EpisodeAvailabilityChecker instance =
      EpisodeAvailabilityChecker._();
  factory EpisodeAvailabilityChecker() => instance;

  /// Primary scraping providers to inspect for newly indexed episodes
  static const List<String> primaryProviders = [
    'gogoanime',
    'aniwaves',
    'animeonsen',
    'anikoto',
    'anizone',
  ];

  /// Checks if [episodeNumber] is actually indexed and ready to stream on
  /// at least [minimumProviders] providers.
  Future<AvailabilityReport> checkAvailability({
    required int anilistId,
    required int episodeNumber,
    int? minimumProviders,
  }) async {
    final prefs = SharedPreferencesService();
    final minRequired = minimumProviders ??
        (prefs.notificationMinimumProviders); // 1 or 2
    final prefAudio = prefs.notificationPreferredAudio; // 'sub', 'dub', 'either'

    final availableProviders = <String>[];
    var subFound = false;
    var dubFound = false;

    final active = (await extractorService.providers())
        .where((p) => p.isOnline)
        .map((p) => p.id)
        .toList();
    final providersToCheck = active.isNotEmpty ? active : primaryProviders;

    final results = await Future.wait(
      providersToCheck.map((providerId) async {
        try {
          return await extractorService.episodes(anilistId, providerId);
        } catch (e) {
          log.w('Provider check error [$providerId] for anime $anilistId: $e');
          return null;
        }
      }),
    );

    for (final data in results) {
      if (data == null) continue;

      final hasSub = data.sub.any((ep) => ep.number == episodeNumber);
      final hasDub = data.dub.any((ep) => ep.number == episodeNumber);

      final matchesAudio = switch (prefAudio) {
        'dub' => hasDub,
        'sub' => hasSub,
        _ => hasSub || hasDub,
      };

      if (matchesAudio) {
        if (hasSub) subFound = true;
        if (hasDub) dubFound = true;
        availableProviders.add(data.providerTitle);
      }
    }

    final String audioLabel;
    if (subFound && dubFound) {
      audioLabel = 'Sub & Dub';
    } else if (dubFound) {
      audioLabel = 'Dub';
    } else if (subFound) {
      audioLabel = 'Sub';
    } else {
      audioLabel = '';
    }

    return AvailabilityReport(
      anilistId: anilistId,
      episodeNumber: episodeNumber,
      isAvailable: availableProviders.length >= minRequired,
      availableCount: availableProviders.length,
      providerNames: availableProviders,
      audioLabel: audioLabel,
    );
  }
}

