import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:aniways/core/database/repositories/collection_repository.dart';
import 'package:aniways/core/database/repositories/watch_repository.dart';
import 'package:aniways/core/device_control.dart';
import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
export 'package:aniways/core/storage/shared_preferences_service.dart'
    show EpisodeViewMode;
import 'package:aniways/core/subtitles/ass_converter.dart';
import 'package:aniways/models/anime_media.dart';

// ═════════════════════════════════════════════════════════════════════════
// State enum
// ═════════════════════════════════════════════════════════════════════════

enum WatchState {
  /// Initial uninitialized state before any watch tab or episode request is triggered
  idle,

  /// Loading providers or initial episodes
  loading,

  /// Anime is upcoming and has not yet aired
  upcoming,

  /// No streaming extensions installed or all are disabled
  noExtensions,

  /// Episodes are loaded and ready to browse / play
  episodesReady,

  /// Resolving stream source from the extractor backend
  loadingStream,

  /// Video is loaded and playing via BetterPlayer
  playing,

  /// Error state
  error,
}

/// Video aspect ratio display modes for fullscreen playback.
enum PlayerAspectRatio {
  /// Standard 16:9 aspect ratio with pillarbox/letterbox as needed (default for modern anime)
  fit,

  /// Zoom/Crop to fill entire display edge-to-edge without black bars on 19.5:9 / 20:9 screens
  zoom,

  /// Stretch video horizontally/vertically to fill screen without cropping
  stretch,

  /// Classic 4:3 ratio for retro anime (Evangelion, DBZ, early One Piece, Sailor Moon)
  ratio4x3,
}

// ═════════════════════════════════════════════════════════════════════════
// WatchProvider
// ═════════════════════════════════════════════════════════════════════════

class WatchProvider extends ChangeNotifier {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final WatchRepository _watchRepo = WatchRepository.instance;

  AnimeMedia? _anime;
  AnimeMedia? get anime => _anime;

  Color? accentColor;

  double playbackSpeed = 1.0;
  PlayerSubtitlesSource? _selectedSubtitle;

  // ── Provider state ────────────────────────────────────────────────────
  List<ProviderInfo> availableProviders = [];
  String? selectedProviderId;
  bool hasExtensionsInstalled = extensionManager.hasInstalledExtensions;
  StreamSubscription? _extensionSubscription;

  WatchProvider() {
    _initExtensionListener();
  }

  void _initExtensionListener() {
    hasExtensionsInstalled = extensionManager.hasInstalledExtensions;
    _extensionSubscription = extensionManager.dbRepository
        .watchInstalledExtensions()
        .listen((extensions) {
      if (_isDisposed) return;
      hasExtensionsInstalled = extensions.isNotEmpty;
      if (state == WatchState.noExtensions) {
        final anyEnabled = extensions.any((e) => e.isEnabled);
        if (anyEnabled) {
          retry();
        }
      }
    });
  }

  // ── Per-anime playback preference overrides ───────────────────────────
  String? _preferredServer;
  String? _preferredQuality;
  String? _preferredSubtitleTrack;

  // ── Probed Provider Episodes Cache (for per-anime Sub/Dub availability) ──
  final Map<String, ProviderEpisodes?> _probedProviderEpisodes = {};
  final Set<String> _probingProviderIds = {};
  final Set<String> _probeFailedProviderIds = {};

  /// Check whether a provider has been probed for the currently loaded anime.
  bool isProviderProbed(String providerId) =>
      _probedProviderEpisodes.containsKey(providerId);

  /// Check whether a provider is currently being probed in the background.
  bool isProviderProbing(String providerId) =>
      _probingProviderIds.contains(providerId);

  /// Check whether background probing failed or timed out for a provider.
  bool isProviderProbeFailed(String providerId) =>
      _probeFailedProviderIds.contains(providerId);

  /// Get probed episodes for a provider (if already resolved).
  ProviderEpisodes? getProbedEpisodes(String providerId) {
    if (providerId == selectedProviderId && currentProviderEpisodes != null) {
      return currentProviderEpisodes;
    }
    return _probedProviderEpisodes[providerId];
  }

  static const List<String> _providerPriority = [
    'gogoanime',
    'aniwaves',
    'anikoto',
    'anizone',
    'animeonsen',
    'anipm',
    'animegg',
  ];

  // ── Episodes state ────────────────────────────────────────────────────
  ProviderEpisodes? currentProviderEpisodes;
  StreamAudio selectedAudio = StreamAudio.sub;
  EpisodeItem? currentEpisode;
  WatchResult? watchResult;
  StreamSource? activeSource;

  // Watched progress map (episodeNumber -> percent 0.0 to 1.0)
  Map<int, double> watchedPercentages = {};
  Map<int, EpisodeProgressInfo> episodeProgressMap = {};

  // Transient notice for user (e.g. "Source unavailable. Switched to Aniwaves")
  String? statusNotice;
  String? errorMessage;
  WatchState state = extensionManager.hasEnabledExtensions
      ? WatchState.idle
      : WatchState.noExtensions;

  // ── Browse & Filter State ─────────────────────────────────────────────
  EpisodeViewMode viewMode = SharedPreferencesService().episodeViewMode;

  bool get isGridView => viewMode == EpisodeViewMode.compact;
  bool get isCardsView => viewMode == EpisodeViewMode.cards;
  bool get isListView => viewMode == EpisodeViewMode.list;

  bool isReversed = false;
  int selectedChunkIndex = 0;
  static const int chunkSize = 25;

  // ── ValueNotifiers for High-Frequency Playback Ticks ──────────────────
  // These prevent rebuilding the episode list/full view on progress ticks.
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> bufferedNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isBufferingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isInitializedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isFullScreenNotifier = ValueNotifier(false);
  final ValueNotifier<bool> showSkipIntroNotifier = ValueNotifier(false);
  final ValueNotifier<bool> showSkipOutroNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isControlsLockedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isSpeedBoostedNotifier = ValueNotifier(false);
  final ValueNotifier<double> volumeNotifier = ValueNotifier(1.0);
  final ValueNotifier<double> brightnessNotifier = ValueNotifier(1.0);
  final ValueNotifier<int?> autoNextCountdownNotifier = ValueNotifier(null);
  final ValueNotifier<({String text, IconData icon})?> hudNoticeNotifier =
      ValueNotifier(null);
  Timer? _hudNoticeTimer;
  bool _qualityTrackApplied = false;

  void showHudNotice(String text, IconData icon) {
    _hudNoticeTimer?.cancel();
    hudNoticeNotifier.value = (text: text, icon: icon);
    _hudNoticeTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!_isDisposed) {
        hudNoticeNotifier.value = null;
      }
    });
  }
  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  void _safeNotifyListeners() {
    if (_isDisposed) return;
    if (WidgetsBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks ||
        WidgetsBinding.instance.schedulerPhase ==
            SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      if (!_isDisposed) notifyListeners();
    }
  }

  // ── Internal Player & Cancellation ────────────────────────────────────
  final GlobalKey betterPlayerWidgetKey = GlobalKey();
  int _playerKeyVersion = 0;
  int get playerKeyVersion => _playerKeyVersion;

  BetterPlayerController? betterPlayerController;
  BetterPlayerRoutePageBuilder? fullScreenRouteBuilder;
  Duration? _pendingResumePosition;
  int _currentRequestId = 0;
  bool _isDisposed = false;

  void _disposePlayerController() {
    _targetSeekPosition = null;
    _lastSeekTime = null;
    bufferedNotifier.value = Duration.zero;
    showSkipIntroNotifier.value = false;
    showSkipOutroNotifier.value = false;
    final oldController = betterPlayerController;
    betterPlayerController = null;
    if (oldController != null) {
      try {
        oldController.removeEventsListener(_onPlayerEvent);
        oldController.pause();
        oldController.dispose(forceDispose: true);
      } catch (e) {
        log.w('Error disposing player controller: $e');
      }
    }
    _playerKeyVersion++;
    _safeNotifyListeners();
  }
  bool _introDismissed = false;
  bool _outroDismissed = false;
  bool _hasRecordedPlaybackStart = false;
  Duration? _targetSeekPosition;
  DateTime? _lastSeekTime;
  Timer? _autoNextTimer;
  Timer? _noticeTimer;

  // ── Getters ───────────────────────────────────────────────────────────

  List<EpisodeItem> get allEpisodesForAudio {
    final pe = currentProviderEpisodes;
    if (pe == null) return const [];
    return selectedAudio == StreamAudio.sub ? pe.sub : pe.dub;
  }

  /// Sorted list of episodes.
  List<EpisodeItem> get episodes {
    var list = List<EpisodeItem>.from(allEpisodesForAudio);

    // Apply sort order
    if (isReversed) {
      list = list.reversed.toList();
    }

    return list;
  }

  /// Total chunks for range selector
  int get totalChunks {
    final total = allEpisodesForAudio.length;
    if (total <= chunkSize) return 1;
    return (total / chunkSize).ceil();
  }

  /// Episodes for current range chunk
  List<EpisodeItem> get chunkedEpisodes {
    final fullList = episodes;
    if (fullList.length <= chunkSize) return fullList;

    final start = (selectedChunkIndex * chunkSize).clamp(0, fullList.length);
    final end = ((selectedChunkIndex + 1) * chunkSize).clamp(0, fullList.length);
    return fullList.sublist(start, end);
  }

  bool get hasDub => currentProviderEpisodes?.hasDub ?? false;
  bool get hasSub => currentProviderEpisodes?.hasSub ?? false;

  bool get hasNextEpisode {
    if (currentEpisode == null) return false;
    final nextNum = currentEpisode!.number + 1;
    final list = allEpisodesForAudio;
    if (list.any((e) => e.number == nextNum)) return true;
    if (_anime?.episodes != null && nextNum <= _anime!.episodes!) {
      return true;
    }
    return false;
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Initializes WatchProvider with anime metadata and persisted preferences.
  Future<void> init(AnimeMedia anime, {Color? accent}) async {
    final isUpcoming = anime.isUpcoming || anime.status == 'NOT_YET_RELEASED';
    if (_anime?.id != anime.id) {
      _probedProviderEpisodes.clear();
      _probingProviderIds.clear();
      _probeFailedProviderIds.clear();
      playbackSpeed = 1.0;
      _preferredServer = null;
      _preferredQuality = null;
      _preferredSubtitleTrack = null;
    }
    _anime = anime;
    if (accent != null) {
      accentColor = accent;
    }

    try {
      await _watchRepo.upsertAnime(anime);
    } catch (_) {}

    if (isUpcoming) {
      state = WatchState.upcoming;
      availableProviders = const [];
      currentProviderEpisodes = null;
      errorMessage = null;
      statusNotice = null;
      notifyListeners();
      return;
    }

    if (_anime?.id == anime.id &&
        (state == WatchState.loading || currentProviderEpisodes != null)) {
      if (state == WatchState.error) {
        // Clear previous playback error and restore episodesReady so the tab isn't poisoned
        state = WatchState.episodesReady;
        errorMessage = null;
        notifyListeners();
      }
      return;
    }

    // ── Immediate check: If no extensions are enabled, stay in noExtensions without flashing loading ──
    final hasEnabled = extensionManager.hasEnabledExtensions;
    hasExtensionsInstalled = extensionManager.hasInstalledExtensions;

    if (!hasEnabled) {
      availableProviders = const [];
      currentProviderEpisodes = null;
      state = WatchState.noExtensions;
      errorMessage = !hasExtensionsInstalled
          ? 'No source extensions installed.'
          : 'All installed source extensions are disabled.';
      notifyListeners();
      return;
    }

    state = WatchState.loading;
    errorMessage = null;
    statusNotice = null;
    notifyListeners();

    // Load watched history for this anime
    await _refreshWatchedProgress();

    try {
      final installed =
          await extensionManager.dbRepository.getInstalledExtensions();
      hasExtensionsInstalled = installed.isNotEmpty;

      final allProviders = await extractorService.providers();
      final adultEnabled = _prefs.enableAdultContent;
      final isAnimeAdult = anime.isAdult;

      // Filter adult providers:
      // - If adult content is disabled globally, adult extensions are excluded.
      // - If the current anime is not 18+ adult, adult extensions are excluded.
      availableProviders = allProviders.where((p) {
        if (p.isAdult && (!adultEnabled || !isAnimeAdult)) {
          return false;
        }
        return true;
      }).toList();

      if (isAnimeAdult && adultEnabled) {
        // Prioritize adult-specialized providers for 18+ adult anime
        availableProviders.sort((a, b) {
          if (a.isAdult && !b.isAdult) return -1;
          if (!a.isAdult && b.isAdult) return 1;
          return 0;
        });
      }
      if (_isDisposed) return;

      if (availableProviders.isEmpty) {
        state = WatchState.noExtensions;
        errorMessage = !hasExtensionsInstalled
            ? 'No source extensions installed.'
            : 'All installed source extensions are disabled.';
        currentProviderEpisodes = null;
        notifyListeners();
        return;
      }

      // Prioritize online providers from /status
      final onlineCandidates = availableProviders.where((p) => p.isOnline).toList();
      final effectivePool = onlineCandidates.isNotEmpty ? onlineCandidates : availableProviders;

      // Check saved anime preferences and watch state from WatchRepository
      final savedPrefs = await _watchRepo.getAnimePreferences(anime.id);
      final savedState = await _watchRepo.getAnimeWatchState(anime.id);

      // Initialize default aspect ratio from user preferences
      final savedAspect = _prefs.defaultAspectRatio;
      _currentAspectRatio = switch (savedAspect) {
        'zoom' => PlayerAspectRatio.zoom,
        'stretch' => PlayerAspectRatio.stretch,
        'ratio4x3' => PlayerAspectRatio.ratio4x3,
        _ => PlayerAspectRatio.fit,
      };

      // 1. Playback Speed: per-anime override -> default preference -> default 1.0
      playbackSpeed =
          savedPrefs?.customPlaybackSpeed ?? _prefs.defaultPlaybackSpeed;

      // 2. Audio (Sub vs Dub): per-anime override -> watch state -> default preference
      // Note: 18+ adult anime is almost universally Japanese audio with subtitles.
      // If the anime is 18+ and there is no explicit per-anime override, default to Sub
      // so a global Dub setting doesn't reject 18+ providers or prioritize non-existent dubs.
      final audioPref = savedPrefs?.preferredAudio ??
          savedState?.audio ??
          (isAnimeAdult && adultEnabled ? 'sub' : _prefs.defaultAudioTrack);
      if (audioPref == 'dub') {
        selectedAudio = StreamAudio.dub;
      } else {
        selectedAudio = StreamAudio.sub;
      }

      // Filter effective pool based on audio preference (if dub is wanted, prefer dub-supporting providers)
      // For 18+ adult titles, adult providers must never be stripped out of poolToUse.
      final poolForAudio = selectedAudio == StreamAudio.dub
          ? effectivePool
              .where((p) => p.supports(StreamAudio.dub) || (isAnimeAdult && p.isAdult))
              .toList()
          : effectivePool;
      final poolToUse = poolForAudio.isNotEmpty ? poolForAudio : effectivePool;

      // 3. Provider: per-anime override -> watch state (filtered for 18+ titles)
      String? initialProvider = savedPrefs?.preferredProvider;
      if (initialProvider == null && savedState?.provider != null) {
        final savedId = savedState!.provider;
        final isSavedAdult = poolToUse.any((p) => p.id == savedId && p.isAdult);
        final hasAdultCandidate = poolToUse.any((p) => p.isAdult);
        // If this is an 18+ title, only use savedState provider if it was already an adult provider,
        // or if there are no adult providers in the pool.
        if (!isAnimeAdult || isSavedAdult || !hasAdultCandidate) {
          initialProvider = savedId;
        }
      }

      // 4. Server, Quality, Subtitle overrides
      _preferredServer = savedPrefs?.preferredServer;
      final rawQuality = savedPrefs?.preferredQuality;
      if (rawQuality != null &&
          (rawQuality.toLowerCase() == 'default' ||
              rawQuality.toLowerCase() == 'auto')) {
        _preferredQuality = null;
      } else {
        _preferredQuality = rawQuality;
      }
      _preferredSubtitleTrack = savedPrefs?.preferredSubtitleTrack;

      // Validate saved provider is in pool or select by priority
      if (initialProvider == null || !poolToUse.any((p) => p.id == initialProvider)) {
        initialProvider = null;
        if (isAnimeAdult && adultEnabled) {
          // For 18+ adult anime without a saved preference, prioritize adult providers first
          for (final p in poolToUse) {
            if (p.isAdult) {
              initialProvider = p.id;
              break;
            }
          }
        }
        if (initialProvider == null) {
          for (final candidate in _providerPriority) {
            if (poolToUse.any((p) => p.id == candidate)) {
              initialProvider = candidate;
              break;
            }
          }
        }
      }
      initialProvider ??= poolToUse.first.id;

      await _loadEpisodesWithFallback(initialProvider, preferredEpisode: savedState?.episode);
    } catch (e) {
      if (_isDisposed) return;
      log.e('WatchProvider.init error', error: e);
      state = WatchState.error;
      errorMessage = 'Could not load stream providers. Check your internet or local server.';
      notifyListeners();
    }
  }

  Future<void> _loadEpisodesWithFallback(String initialProviderId, {int? preferredEpisode}) async {
    final toTry = <String>[];
    final isAnimeAdult = _anime?.isAdult ?? false;
    final adultEnabled = _prefs.enableAdultContent;

    if (isAnimeAdult && adultEnabled) {
      // For 18+ adult anime, prioritize adult-specialized providers first to minimize fallback latency
      toTry.addAll(
        availableProviders
            .where((p) => p.isAdult && p.isOnline)
            .map((p) => p.id),
      );
      toTry.addAll(
        availableProviders
            .where((p) => p.isAdult && !p.isOnline)
            .map((p) => p.id),
      );
    } else if (selectedAudio == StreamAudio.dub) {
      // If selectedAudio is Dub, prioritize dub-capable providers first
      toTry.addAll(
        availableProviders
            .where((p) => p.isOnline && p.supports(StreamAudio.dub))
            .map((p) => p.id),
      );
      toTry.addAll(
        availableProviders
            .where((p) => !p.isOnline && p.supports(StreamAudio.dub))
            .map((p) => p.id),
      );
    }

    // Add remaining providers
    for (final p in availableProviders) {
      if (!toTry.contains(p.id)) {
        toTry.add(p.id);
      }
    }

    // Move initialProviderId to the front if present
    if (toTry.contains(initialProviderId)) {
      toTry.remove(initialProviderId);
      toTry.insert(0, initialProviderId);
    }

    for (int i = 0; i < toTry.length; i++) {
      final providerId = toTry[i];
      if (_isDisposed) return;
      try {
        final result = await extractorService.episodes(_anime!.id, providerId);
        if (_isDisposed) return;

        if (result != null && (result.hasSub || result.hasDub)) {
          // If user wanted DUB, but this provider only has SUB:
          // Check if there are other providers in toTry that support DUB!
          if (selectedAudio == StreamAudio.dub && !result.hasDub) {
            final isCurrentAdult = availableProviders.any((p) => p.id == providerId && p.isAdult);
            // On 18+ adult anime, never skip an adult provider just to search for non-existent dubs on mainstream providers
            if (!isAnimeAdult && !isCurrentAdult) {
              final hasRemainingDubCandidates = toTry
                  .skip(i + 1)
                  .any((id) => availableProviders
                      .any((p) => p.id == id && p.supports(StreamAudio.dub)));
              if (hasRemainingDubCandidates) {
                // Don't settle for sub yet! Keep looking for a Dub provider.
                continue;
              }
            }
            // All dub providers failed or had no dub for this anime.
            selectedAudio = StreamAudio.sub;
            _showNotice('Dub unavailable for this title. Loaded Subtitled.');
          } else if (selectedAudio == StreamAudio.sub && !result.hasSub && result.hasDub) {
            selectedAudio = StreamAudio.dub;
          }

          selectedProviderId = providerId;
          currentProviderEpisodes = result;
          _probedProviderEpisodes[providerId] = result;

          final epList = result.forAudio(selectedAudio);
          if (epList.isNotEmpty) {
            if (preferredEpisode != null) {
              currentEpisode = epList.firstWhere(
                (e) => e.number == preferredEpisode,
                orElse: () => epList.first,
              );
            } else {
              currentEpisode = epList.first;
            }
          } else {
            currentEpisode = null;
          }

          syncChunkWithCurrentEpisode();
          state = WatchState.episodesReady;
          notifyListeners();
          return;
        }
      } catch (e) {
        log.w('Provider "$providerId" failed to list episodes: $e');
      }
    }

    if (_isDisposed) return;
    state = WatchState.error;
    errorMessage = 'No episodes found for "${_anime?.title}" across all providers.';
    notifyListeners();
  }

  /// Triggers on-demand background probing of all online providers for the current anime.
  /// Called when the user opens the Providers sheet / tab.
  Future<void> probeProvidersForCurrentAnime() async {
    final animeId = _anime?.id;
    if (animeId == null) return;

    // Cache the currently active provider's episodes
    if (selectedProviderId != null && currentProviderEpisodes != null) {
      _probedProviderEpisodes[selectedProviderId!] = currentProviderEpisodes;
    }

    // Identify providers that need probing
    final toProbe = availableProviders.where((p) {
      if (!p.isOnline) return false;
      if (_probedProviderEpisodes.containsKey(p.id)) return false;
      if (_probingProviderIds.contains(p.id)) return false;
      return true;
    }).toList();

    if (toProbe.isEmpty) return;

    for (final p in toProbe) {
      _probingProviderIds.add(p.id);
      _probeFailedProviderIds.remove(p.id);
    }
    _safeNotifyListeners();

    // Probe each provider asynchronously in parallel
    for (final p in toProbe) {
      extractorService
          .episodes(animeId, p.id)
          .timeout(const Duration(seconds: 30))
          .then((result) {
        _probingProviderIds.remove(p.id);
        if (_isDisposed || _anime?.id != animeId) return;
        _probedProviderEpisodes[p.id] = result;
        _safeNotifyListeners();
      }).catchError((err) {
        log.w('Probe provider ${p.id} error: $err');
        _probingProviderIds.remove(p.id);
        if (_isDisposed || _anime?.id != animeId) return;
        _probeFailedProviderIds.add(p.id);
        _safeNotifyListeners();
      });
    }
  }

  /// Switch provider manually via settings sheet.
  Future<void> selectProvider(String providerId) async {
    _probeFailedProviderIds.remove(providerId);
    if (selectedProviderId == providerId && currentProviderEpisodes != null) {
      return;
    }

    final isFullScreen = isFullScreenNotifier.value;
    final shouldAutoPlay = isFullScreen &&
        (isPlayingNotifier.value ||
            state == WatchState.playing ||
            state == WatchState.loadingStream);
    final previousEpisode = currentEpisode;
    final previousProviderId = selectedProviderId;
    final previousEpisodes = currentProviderEpisodes;
    final wasIntroDismissed = _introDismissed;
    final wasOutroDismissed = _outroDismissed;

    // Save current playback progress before switching if video was active
    if (currentEpisode != null && _anime != null) {
      final currentPos = positionNotifier.value;
      if (currentPos.inSeconds > 0) {
        _watchRepo.saveProgress(
          anime: _anime!,
          episodeNumber: currentEpisode!.number,
          episodeTitle: currentEpisode!.title,
          episodeThumbnail: currentEpisode!.image,
          position: currentPos,
          duration: durationNotifier.value,
          providerId: selectedProviderId,
          audio: selectedAudio.name,
        );
      }
    }

    // Stop currently playing video before switching provider
    _stopPlayback();

    state = shouldAutoPlay ? WatchState.loadingStream : WatchState.loading;
    errorMessage = null;
    showSkipIntroNotifier.value = false;
    showSkipOutroNotifier.value = false;
    notifyListeners();

    try {
      final cached = _probedProviderEpisodes[providerId];
      final ProviderEpisodes? result;
      if (cached != null) {
        result = cached;
      } else {
        result = await extractorService.episodes(_anime!.id, providerId);
        if (_isDisposed) return;
        _probedProviderEpisodes[providerId] = result;
      }

      if (result == null || (!result.hasSub && !result.hasDub)) {
        throw Exception('No episodes available on "$providerId".');
      }

      selectedProviderId = providerId;
      _saveAnimePreferences(provider: providerId);
      currentProviderEpisodes = result;
      _probedProviderEpisodes[providerId] = result;
      if (selectedAudio == StreamAudio.dub && !result.hasDub) {
        selectedAudio = StreamAudio.sub;
        _showNotice('${result.providerId} only offers Subtitled episodes');
      }

      final epList = result.forAudio(selectedAudio);
      if (epList.isNotEmpty) {
        if (previousEpisode != null) {
          currentEpisode = epList.firstWhere(
            (e) => e.number == previousEpisode.number,
            orElse: () => epList.first,
          );
        } else {
          currentEpisode = epList.first;
        }
      } else {
        currentEpisode = null;
      }

      syncChunkWithCurrentEpisode();

      if (shouldAutoPlay && currentEpisode != null) {
        await playEpisode(currentEpisode!, accent: accentColor);
        if (currentEpisode?.number == previousEpisode?.number) {
          if (wasIntroDismissed) _introDismissed = true;
          if (wasOutroDismissed) _outroDismissed = true;
        }
      } else {
        state = WatchState.episodesReady;
        notifyListeners();
      }
    } catch (e) {
      if (_isDisposed) return;
      log.e('WatchProvider.selectProvider error', error: e);
      if (previousEpisodes != null && previousProviderId != null) {
        selectedProviderId = previousProviderId;
        currentProviderEpisodes = previousEpisodes;
        _showNotice('No episodes available on "$providerId". Kept $previousProviderId.');
        if (shouldAutoPlay && previousEpisode != null) {
          currentEpisode = previousEpisode;
          await playEpisode(previousEpisode, accent: accentColor);
          if (wasIntroDismissed) _introDismissed = true;
          if (wasOutroDismissed) _outroDismissed = true;
        } else {
          state = WatchState.episodesReady;
          notifyListeners();
        }
      } else {
        selectedProviderId = previousProviderId;
        state = WatchState.error;
        errorMessage = 'Failed to load episodes from "$providerId".';
        notifyListeners();
      }
    }
  }

  /// Switch between Sub and Dub tracks.
  Future<void> setAudio(StreamAudio audio) async {
    if (selectedAudio == audio) return;
    selectedAudio = audio;
    _saveAnimePreferences(audio: audio.name);
    final audioLabel = audio == StreamAudio.dub ? 'Dubbed' : 'Subtitled';
    showHudNotice('Audio: $audioLabel', Icons.audiotrack_rounded);

    final isFullScreen = isFullScreenNotifier.value;
    final shouldAutoPlay = isFullScreen &&
        (isPlayingNotifier.value ||
            state == WatchState.playing ||
            state == WatchState.loadingStream);
    final wasIntroDismissed = _introDismissed;
    final wasOutroDismissed = _outroDismissed;
    final previousEpisodeNumber = currentEpisode?.number;

    showSkipIntroNotifier.value = false;
    showSkipOutroNotifier.value = false;

    // Remap currentEpisode to the matching episode in the new audio list
    final newEpList = allEpisodesForAudio;
    if (newEpList.isNotEmpty) {
      if (currentEpisode != null) {
        currentEpisode = newEpList.firstWhere(
          (e) => e.number == currentEpisode!.number,
          orElse: () => newEpList.first,
        );
      } else {
        currentEpisode = newEpList.first;
      }
    } else {
      currentEpisode = null;
    }

    syncChunkWithCurrentEpisode();

    // If video was playing in fullscreen, reload playback with the newly mapped episode
    if (shouldAutoPlay && currentEpisode != null) {
      await playEpisode(currentEpisode!, accent: accentColor);
      if (currentEpisode?.number == previousEpisodeNumber) {
        if (wasIntroDismissed) _introDismissed = true;
        if (wasOutroDismissed) _outroDismissed = true;
      }
    } else {
      _stopPlayback();
      if (state == WatchState.playing || state == WatchState.loadingStream) {
        state = WatchState.episodesReady;
      }
      notifyListeners();
    }
  }

  /// Cycles between list view -> card grid -> compact numbers and saves preference.
  void cycleViewMode() {
    switch (viewMode) {
      case EpisodeViewMode.list:
        viewMode = EpisodeViewMode.cards;
        break;
      case EpisodeViewMode.cards:
        viewMode = EpisodeViewMode.compact;
        break;
      case EpisodeViewMode.compact:
        viewMode = EpisodeViewMode.list;
        break;
    }
    _prefs.setEpisodeViewMode(viewMode);
    notifyListeners();
  }

  /// Directly sets the episode view mode and saves preference.
  void setViewMode(EpisodeViewMode mode) {
    if (viewMode == mode) return;
    viewMode = mode;
    _prefs.setEpisodeViewMode(mode);
    notifyListeners();
  }

  /// Toggles / cycles view mode (kept for backwards compatibility).
  void toggleViewMode() => cycleViewMode();

  /// Toggles sort order between 1->N and N->1.
  void toggleSortOrder() {
    isReversed = !isReversed;
    syncChunkWithCurrentEpisode();
    notifyListeners();
  }

  /// Selects range chunk index (0 for 1-25, 1 for 26-50, etc.).
  void selectChunk(int index) {
    selectedChunkIndex = index;
    notifyListeners();
  }

  /// Syncs the selected chunk index to encompass the [currentEpisode].
  void syncChunkWithCurrentEpisode() {
    if (currentEpisode == null) return;
    final list = episodes;
    final idx = list.indexWhere((e) => e.number == currentEpisode!.number);
    if (idx != -1 && totalChunks > 0) {
      final target = (idx ~/ chunkSize).clamp(0, totalChunks - 1);
      if (selectedChunkIndex != target) {
        selectedChunkIndex = target;
        notifyListeners();
      }
    }
  }

  // ── Playback Execution ────────────────────────────────────────────────

  /// Cancels any active or pending stream loading and halts playback immediately.
  /// Flushes current playback progress to database and refreshes watched state.
  Future<void> cancelPlayback() async {
    if (_isDisposed) return;
    _currentRequestId++;
    _cancelAutoNextTimer();
    try {
      betterPlayerController?.pause();
    } catch (_) {}
    try {
      WakelockPlus.disable();
    } catch (_) {}
    if (!_isDisposed) {
      try {
        isPlayingNotifier.value = false;
      } catch (_) {}
    }

    if (state == WatchState.loadingStream || state == WatchState.playing) {
      state = WatchState.episodesReady;
    }

    // Flush current playback progress before leaving
    if (_anime != null && currentEpisode != null && !_isDisposed) {
      final currentPos = positionNotifier.value;
      final totalDur = durationNotifier.value;
      if (totalDur.inSeconds > 0 && currentPos.inSeconds > 0) {
        // Reset notifiers immediately so repeated exit calls (PopScope, dispose)
        // do not re-flush progress with stale values.
        positionNotifier.value = Duration.zero;
        durationNotifier.value = Duration.zero;

        await _watchRepo.saveProgress(
          anime: _anime!,
          episodeNumber: currentEpisode!.number,
          episodeTitle: currentEpisode!.title,
          episodeThumbnail: currentEpisode!.image,
          position: currentPos,
          duration: totalDur,
          providerId: selectedProviderId,
          audio: selectedAudio.name,
        );

        if (_isDisposed) return;

        // If completed (>= 90%), advance resume state pointer to next episode if available
        final percent = currentPos.inMilliseconds / totalDur.inMilliseconds;
        if (percent >= 0.90) {
          await _checkAndSetCompletedIfFinished(currentEpisode!.number);
          if (_isDisposed) return;
          final nextNumber = currentEpisode!.number + 1;
          final nextInList = allEpisodesForAudio
              .where((e) => e.number == nextNumber)
              .firstOrNull;
          if (nextInList != null && !_isDisposed) {
            currentEpisode = nextInList;
            syncChunkWithCurrentEpisode();
            _saveWatchState(nextInList);
          }
        }
      }
      if (_isDisposed) return;
      await _refreshWatchedProgress();
    }

    // Cleanly tear down the native player and its surface texture
    _disposePlayerController();

    if (_isDisposed) return;
    _safeNotifyListeners();
  }

  /// Explicitly pulls latest watched percentages from SQLite and notifies listeners.
  Future<void> refreshWatchState() async {
    await _refreshWatchedProgress();
    _safeNotifyListeners();
  }

  /// Marks a specific episode as watched (100% progress).
  Future<void> markEpisodeWatched(EpisodeItem episode) async {
    if (_anime == null) return;
    await _watchRepo.markEpisodeWatched(
      anime: _anime!,
      episodeNumber: episode.number,
      episodeTitle: episode.title,
      episodeThumbnail: episode.image,
    );
    await _refreshWatchedProgress();
    _safeNotifyListeners();
  }

  /// Marks a specific episode as unwatched (clears progress).
  Future<void> markEpisodeUnwatched(EpisodeItem episode) async {
    if (_anime == null) return;
    await _watchRepo.markEpisodeUnwatched(
      animeId: _anime!.id,
      episodeNumber: episode.number,
    );
    await _refreshWatchedProgress();
    _safeNotifyListeners();
  }

  /// Marks all episodes up to and including [episode] as watched.
  Future<void> markPreviousEpisodesWatched(EpisodeItem episode) async {
    if (_anime == null) return;
    final allNumbers = allEpisodesForAudio.isNotEmpty
        ? allEpisodesForAudio.map((e) => e.number).toList()
        : null;
    await _watchRepo.markPreviousEpisodesWatched(
      anime: _anime!,
      upToEpisodeNumber: episode.number,
      availableEpisodeNumbers: allNumbers,
    );
    await _refreshWatchedProgress();
    _safeNotifyListeners();
  }

  /// Unmarks all episodes up to and including [episode] (clears progress).
  Future<void> unmarkPreviousEpisodes(EpisodeItem episode) async {
    if (_anime == null) return;
    await _watchRepo.unmarkPreviousEpisodes(
      animeId: _anime!.id,
      upToEpisodeNumber: episode.number,
    );
    await _refreshWatchedProgress();
    _safeNotifyListeners();
  }

  /// Starts playback for [ep] with request cancellation & multi-tier fallback.
  Future<void> playEpisode(EpisodeItem ep, {Color? accent}) async {
    if (accent != null) accentColor = accent;
    _cancelAutoNextTimer();

    // Flush current playback progress before switching if a previous episode was playing
    if (_anime != null && currentEpisode != null && currentEpisode != ep) {
      final currentPos = positionNotifier.value;
      final totalDur = durationNotifier.value;
      if (totalDur.inSeconds > 0 && currentPos.inSeconds > 0) {
        await _watchRepo.saveProgress(
          anime: _anime!,
          episodeNumber: currentEpisode!.number,
          episodeTitle: currentEpisode!.title,
          episodeThumbnail: currentEpisode!.image,
          position: currentPos,
          duration: totalDur,
          providerId: selectedProviderId,
          audio: selectedAudio.name,
        );

        final percent = currentPos.inMilliseconds / totalDur.inMilliseconds;
        if (percent >= 0.90) {
          await _checkAndSetCompletedIfFinished(currentEpisode!.number);
        }
      }
    }

    // Stop current playback before switching
    _stopPlayback();

    final requestId = ++_currentRequestId;
    _qualityTrackApplied = false;
    _hasRecordedPlaybackStart = false;
    currentEpisode = ep;
    syncChunkWithCurrentEpisode();
    _introDismissed = false;
    _outroDismissed = false;
    showSkipIntroNotifier.value = false;
    showSkipOutroNotifier.value = false;
    state = WatchState.loadingStream;
    errorMessage = null;
    notifyListeners();

    await _fetchAndPlayWithFallback(ep, requestId);
  }

  Future<void> _fetchAndPlayWithFallback(EpisodeItem ep, int requestId) async {
    // 1. Try current provider: test all playable streams (e.g. MuL-AuD, DatSaV, Vidplay, MyCloud)
    try {
      final result = await extractorService.watch(ep);
      if (_isDisposed || requestId != _currentRequestId) return;

      final playable = result.playableStreams;
      if (playable.isNotEmpty) {
        watchResult = result;
        final preferred = _selectPreferredStream(playable);
        final streamsToTry = [
          preferred,
          ...playable.where((s) => s.url != preferred.url),
        ];

        for (final source in streamsToTry) {
          if (_isDisposed || requestId != _currentRequestId) return;
          try {
            activeSource = source;
            await _setupBetterPlayer(source, requestId);
            if (_isDisposed || requestId != _currentRequestId) return;

            state = WatchState.playing;
            notifyListeners();
            _saveAnimePreferences(server: source.server);
            return;
          } catch (e) {
            log.w('Stream ${source.server} (${source.quality}) failed on $selectedProviderId: $e');
            _disposePlayerController();
          }
        }
      } else {
        log.w('Provider "$selectedProviderId" returned no playable streams for Episode ${ep.number} (total: ${result.streams.length})');
      }
    } catch (e) {
      log.w('Provider $selectedProviderId failed for ep ${ep.number}: $e');
    }

    // 2. Multi-tier fallback: Try other providers for the exact episode
    for (final p in availableProviders) {
      if (p.id == selectedProviderId || !p.supports(ep.audio) || !p.isOnline) continue;
      if (_isDisposed || requestId != _currentRequestId) return;

      try {
        final provResult = _probedProviderEpisodes[p.id] ??
            await extractorService.episodes(_anime!.id, p.id);
        if (_isDisposed || requestId != _currentRequestId) return;
        if (provResult == null) continue;
        _probedProviderEpisodes[p.id] = provResult;

        final targetList = provResult.forAudio(ep.audio);
        final nextEp = targetList.firstWhere(
          (e) => e.number == ep.number,
          orElse: () => throw Exception('Episode not found'),
        );

        final watchRes = await extractorService.watch(nextEp);
        if (_isDisposed || requestId != _currentRequestId) return;

        final playable = watchRes.playableStreams;
        if (playable.isNotEmpty) {
          final preferred = _selectPreferredStream(playable);
          final streamsToTry = [
            preferred,
            ...playable.where((s) => s.url != preferred.url),
          ];

          for (final source in streamsToTry) {
            if (_isDisposed || requestId != _currentRequestId) return;
            try {
              await _setupBetterPlayer(source, requestId);
              if (_isDisposed || requestId != _currentRequestId) return;

              // Successfully set up stream! Only now commit provider state:
              final oldProvider = selectedProviderId;
              selectedProviderId = p.id;
              currentProviderEpisodes = provResult;
              currentEpisode = nextEp;
              watchResult = watchRes;
              activeSource = source;
              _saveAnimePreferences(server: source.server);

              _showNotice('Switched to ${p.displayName} (source unavailable on $oldProvider)');

              state = WatchState.playing;
              notifyListeners();
              return;
            } catch (err) {
              log.w('Fallback stream ${source.server} on ${p.id} failed: $err');
              _disposePlayerController();
            }
          }
        }
      } catch (err) {
        log.w('Fallback provider ${p.id} failed: $err');
      }
    }

    if (_isDisposed || requestId != _currentRequestId) return;
    state = WatchState.error;
    errorMessage = ep.audio == StreamAudio.dub
        ? 'Episode ${ep.number} is not available in Dubbed audio across any provider.'
        : 'Unable to stream Episode ${ep.number} across all available sources.';
    notifyListeners();
  }

  StreamSource _selectPreferredStream(List<StreamSource> streams) {
    // 1. If an anime-specific server preference exists, prefer matching server
    if (_preferredServer != null && _preferredServer!.isNotEmpty) {
      final matchingServerStreams = streams
          .where(
            (s) => s.server.toLowerCase() == _preferredServer!.toLowerCase(),
          )
          .toList();
      if (matchingServerStreams.isNotEmpty) {
        return _selectQualityFromPool(matchingServerStreams);
      }
    }

    return _selectQualityFromPool(streams);
  }

  StreamSource _selectQualityFromPool(List<StreamSource> streams) {
    // Quality priority: anime-specific quality override -> global preferred quality
    final isExplicitAuto = _preferredQuality?.toLowerCase() == 'manual_auto';
    final hasSpecificOverride = _preferredQuality != null &&
        _preferredQuality!.isNotEmpty &&
        _preferredQuality!.toLowerCase() != 'default' &&
        _preferredQuality!.toLowerCase() != 'auto' &&
        !isExplicitAuto;

    final effectiveQuality = isExplicitAuto
        ? 'auto'
        : (hasSpecificOverride
            ? _preferredQuality!.toLowerCase().replaceAll('p', '').trim()
            : _prefs.streamingQuality.toLowerCase().replaceAll('p', '').trim());

    if (effectiveQuality != 'auto' && effectiveQuality != 'default') {
      final matching = streams.firstWhere(
        (s) => (s.quality ?? '').toLowerCase().contains(effectiveQuality),
        orElse: () => streams.first,
      );
      return matching;
    }
    return streams.first;
  }

  Map<String, String> _buildEffectiveHeaders(StreamSource source) {
    final effectiveHeaders = <String, String>{
      ...source.headers,
    };

    if (!effectiveHeaders.keys.any((k) => k.toLowerCase() == 'user-agent')) {
      effectiveHeaders['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
    }

    final refererKey = effectiveHeaders.keys.firstWhere(
      (k) => k.toLowerCase() == 'referer',
      orElse: () => '',
    );
    if (refererKey.isNotEmpty &&
        !effectiveHeaders.keys.any((k) => k.toLowerCase() == 'origin')) {
      try {
        final uri = Uri.parse(effectiveHeaders[refererKey]!);
        if (uri.hasScheme && uri.host.isNotEmpty) {
          effectiveHeaders['Origin'] = uri.origin;
        }
      } catch (_) {}
    }

    return effectiveHeaders;
  }

  Future<void> _setupBetterPlayer(
    StreamSource source,
    int requestId, {
    Duration? initialPosition,
  }) async {
    // Ensure native player environment (textureRegistry, activity) is restored
    // in case background tasks (e.g. WorkManager) detached and clobbered it.
    await DeviceControl.ensureBetterPlayerReady();

    final isHls = source.type == StreamType.hls ||
        source.url.toLowerCase().contains('.m3u8') ||
        source.url.toLowerCase().contains('m3u8');
    final isDash = source.type == StreamType.dash ||
        source.url.toLowerCase().contains('.mpd');
    final format = isHls
        ? VideoFormat.hls
        : (isDash ? VideoFormat.dash : VideoFormat.other);

    final preferredSubLang = _prefs.subtitleLanguage.toLowerCase();
    final effectiveHeaders = _buildEffectiveHeaders(source);

    // Find the preferred subtitle track (defaults to anime-specific track, else user preferred language, else English/default, else first)
    SubtitleTrack? preferredTrack;
    if (source.subtitles.isNotEmpty) {
      final isSubOff = _preferredSubtitleTrack != null &&
          (_preferredSubtitleTrack!.toLowerCase() == 'none' ||
              _preferredSubtitleTrack!.toLowerCase() == 'off');

      if (!isSubOff) {
        // 0. Anime-specific preferred subtitle track (if explicitly set)
        if (_preferredSubtitleTrack != null &&
            _preferredSubtitleTrack!.isNotEmpty) {
          preferredTrack = source.subtitles.cast<SubtitleTrack?>().firstWhere(
                (s) =>
                    s!.label.toLowerCase() ==
                        _preferredSubtitleTrack!.toLowerCase() ||
                    s.srclang.toLowerCase() ==
                        _preferredSubtitleTrack!.toLowerCase(),
                orElse: () => null,
              );
        }

        // 1. Strict match on user's preferred language code or label
        preferredTrack ??= source.subtitles.cast<SubtitleTrack?>().firstWhere(
              (s) =>
                  s!.srclang.toLowerCase() == preferredSubLang ||
                  s.label.toLowerCase() == preferredSubLang ||
                  s.label.toLowerCase().startsWith(preferredSubLang),
              orElse: () => null,
            );

        // 2. Fall back to English or isDefault
        preferredTrack ??= source.subtitles.cast<SubtitleTrack?>().firstWhere(
              (s) =>
                  s!.isDefault ||
                  s.srclang.toLowerCase() == 'en' ||
                  s.srclang.toLowerCase().startsWith('en') ||
                  s.label.toLowerCase().contains('english'),
              orElse: () => null,
            );

        // 3. Fall back to first available track
        preferredTrack ??= source.subtitles.first;
      }
    }

    // Start preferred subtitle download in parallel with a 6-second timeout
    final Future<PlayerSubtitlesSource?> subtitleFuture = preferredTrack != null
        ? SubtitleLoader.instance
            .loadTrack(
              preferredTrack,
              extraHeaders: effectiveHeaders,
              isSelected: true,
            )
            .timeout(const Duration(seconds: 6))
            .catchError((e) {
              log.w('Failed to preload preferred subtitle: $e');
              return null;
            })
        : Future<PlayerSubtitlesSource?>.value(null);

    final subConfig = _buildSubtitlesConfiguration();

    // Cleanly tear down any prior controller to guarantee a fresh, isolated ExoPlayer instance
    if (betterPlayerController != null) {
      _disposePlayerController();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    final playerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: false, // Keep false during setup to prevent audio starting without video
      allowedScreenSleep: false,
      autoDetectFullscreenDeviceOrientation: false,
      autoDetectFullscreenAspectRatio: false,
      handleLifecycle: false,
      autoDispose: false,
      fullScreenByDefault: false,
      subtitlesConfiguration: subConfig,
      routePageBuilder: (context, anim, secAnim, provider) {
        if (fullScreenRouteBuilder != null) {
          return fullScreenRouteBuilder!(context, anim, secAnim, provider);
        }
        return Scaffold(backgroundColor: Colors.black, body: provider);
      },
      controlsConfiguration: const PlayerControlsConfiguration(
        showControls: false,
      ),
    );

    final controller = BetterPlayerController(playerConfiguration);
    controller.addEventsListener(_onPlayerEvent);
    betterPlayerController = controller;
    _safeNotifyListeners();

    // Await the preferred subtitle result
    final initialSelectedSub = await subtitleFuture;

    if (_isDisposed || requestId != _currentRequestId) {
      return;
    }

    // Build subtitle descriptors without mass-downloading remaining tracks
    final initialSubtitles = <PlayerSubtitlesSource>[];
    for (final s in source.subtitles) {
      if (preferredTrack != null &&
          s.url == preferredTrack.url &&
          initialSelectedSub != null) {
        initialSubtitles.add(initialSelectedSub);
      } else {
        final cached = SubtitleLoader.instance.getCached(s.url);
        initialSubtitles.add(
          PlayerSubtitlesSource(
            type: PlayerSubtitlesSourceType.memory,
            name: s.label,
            content: cached,
            urls: [s.url],
            selectedByDefault: false,
          ),
        );
      }
    }

    // Check saved progress or explicit position to resume playback
    final savedProgress = _anime != null && currentEpisode != null
        ? await _watchRepo.getEpisodeProgress(_anime!.id, currentEpisode!.number)
        : null;
    final resumePos = initialPosition ??
        ((savedProgress != null && !savedProgress.isCompleted)
            ? savedProgress.position
            : null);

    _pendingResumePosition = null;
    isInitializedNotifier.value = false;
    showSkipIntroNotifier.value = false;
    showSkipOutroNotifier.value = false;

    if (resumePos != null) {
      if (watchResult?.intro != null &&
          resumePos.inSeconds > watchResult!.intro!.end) {
        _introDismissed = true;
      }
      if (watchResult?.outro != null &&
          resumePos.inSeconds > watchResult!.outro!.end) {
        _outroDismissed = true;
      }
    }

    final dataSource = PlayerDataSource(
      DataSourceType.network,
      source.url,
      headers: effectiveHeaders.isNotEmpty ? effectiveHeaders : null,
      videoFormat: format,
      videoExtension: isHls ? 'm3u8' : (isDash ? 'mpd' : null),
      useAsmsSubtitles: false, // Disable duplicate manifest parsing to prevent TrackGroup warning
      useAsmsTracks: true,
      subtitles: initialSubtitles.isNotEmpty ? initialSubtitles : null,
    );

    final sw = Stopwatch()..start();
    log.i(
      '[Player] Setting up dataSource: ${source.server} (${source.quality ?? "default"}), '
      'format=$format, url=${source.url}',
    );
    if (effectiveHeaders.isNotEmpty) {
      log.d('[Player] Headers: $effectiveHeaders');
    }

    try {
      await betterPlayerController!
          .setupDataSource(dataSource)
          .timeout(const Duration(seconds: 30));
      log.i(
        '[Player] setupDataSource completed in ${sw.elapsedMilliseconds}ms',
      );
    } catch (e) {
      log.w(
        '[Player] setupDataSource failed after ${sw.elapsedMilliseconds}ms: $e',
      );
      _disposePlayerController();
      rethrow;
    }
    if (_isDisposed || requestId != _currentRequestId) {
      betterPlayerController?.pause();
      return;
    }

    if (playbackSpeed != 1.0) {
      betterPlayerController?.setSpeed(playbackSpeed);
    }
    _applyAspectRatio();
    _applyPreferredQualityTrack();

    final defaultSub = initialSelectedSub ??
        initialSubtitles.where((s) => s.selectedByDefault == true).firstOrNull ??
        (initialSubtitles.isNotEmpty ? initialSubtitles.first : null);
    _selectedSubtitle = defaultSub;

    if (resumePos != null && resumePos.inSeconds > 5) {
      if (betterPlayerController?.isInitialized ?? false) {
        try {
          await seek(resumePos);
        } catch (_) {}
      } else {
        _pendingResumePosition = resumePos;
      }
    }

    // Start playback once video surface and subtitles are ready
    if (_prefs.autoPlay && isFullScreenNotifier.value) {
      betterPlayerController?.play();
      isPlayingNotifier.value = true;
    }
  }

  void _onPlayerEvent(PlayerEvent event) {
    if (_isDisposed) return;

    switch (event.betterPlayerEventType) {
      case PlayerEventType.progress:
        final p = event.parameters?['progress'] as Duration?;
        final d = event.parameters?['duration'] as Duration?;
        if (d != null) durationNotifier.value = d;

        if (p != null) {
          if (_targetSeekPosition != null) {
            final elapsed = DateTime.now().difference(_lastSeekTime!);
            final diff = (p - _targetSeekPosition!).inMilliseconds.abs();
            // While seeking is settling, ignore stale progress ticks from the native
            // player loop (which reports pre-seek position) until ExoPlayer catches up
            // or timeout elapses.
            if (diff <= 1500 || elapsed > const Duration(milliseconds: 1500)) {
              _targetSeekPosition = null;
              positionNotifier.value = p;
            } else {
              break;
            }
          } else {
            positionNotifier.value = p;
          }
        }

        // Skip intro & outro checking
        final isPlayerReady = isInitializedNotifier.value &&
            _pendingResumePosition == null &&
            _targetSeekPosition == null;

        if (isPlayerReady && p != null && watchResult?.intro != null) {
          final intro = watchResult!.intro!;
          // If playback has progressed past the intro, permanently dismiss it for this episode
          if (p.inSeconds > intro.end) {
            _introDismissed = true;
          }

          if (!_introDismissed) {
            final inRange =
                p.inSeconds >= intro.start && p.inSeconds <= intro.end;
            if (inRange && _prefs.autoSkipIntro) {
              skipIntro(isAuto: true);
            } else {
              showSkipIntroNotifier.value = inRange;
            }
          } else {
            showSkipIntroNotifier.value = false;
          }
        } else {
          showSkipIntroNotifier.value = false;
        }

        if (isPlayerReady && p != null && watchResult?.outro != null) {
          final outro = watchResult!.outro!;
          if (outro.start > 0 && outro.end > outro.start) {
            if (p.inSeconds > outro.end) {
              _outroDismissed = true;
            }

            if (!_outroDismissed) {
              final inRange =
                  p.inSeconds >= outro.start && p.inSeconds <= outro.end;
              if (inRange && _prefs.autoSkipOutro) {
                skipOutro(isAuto: true);
              } else {
                showSkipOutroNotifier.value = inRange;
              }
            } else {
              showSkipOutroNotifier.value = false;
            }
          } else {
            showSkipOutroNotifier.value = false;
          }
        } else {
          showSkipOutroNotifier.value = false;
        }

        // Periodically save watch progress
        if (p != null && d != null && _anime != null && currentEpisode != null) {
          if (p.inSeconds % 5 == 0 && d.inSeconds > 0) {
            _watchRepo.saveProgress(
              anime: _anime!,
              episodeNumber: currentEpisode!.number,
              episodeTitle: currentEpisode!.title,
              episodeThumbnail: currentEpisode!.image,
              position: p,
              duration: d,
              providerId: selectedProviderId,
              audio: selectedAudio.name,
            );
            final durMs = d.inMilliseconds;
            if (durMs > 0) {
              final pct = (p.inMilliseconds / durMs).clamp(0.0, 1.0);
              episodeProgressMap[currentEpisode!.number] = (
                position: p,
                duration: d,
                percent: pct,
                isCompleted: pct >= 0.90,
              );
              watchedPercentages[currentEpisode!.number] = pct;
            }
          }
        }

        if (p != null && p.inSeconds >= 1 && !_hasRecordedPlaybackStart) {
          _onPlaybackStarted();
        }

        if (!_qualityTrackApplied && availableQualityTracks.isNotEmpty) {
          _applyPreferredQualityTrack();
        }
        _updateBufferedProgress();
        break;

      case PlayerEventType.play:
        isPlayingNotifier.value = true;
        isBufferingNotifier.value = false;
        _onPlaybackStarted();
        break;

      case PlayerEventType.pause:
        isPlayingNotifier.value = false;
        break;

      case PlayerEventType.bufferingStart:
        isBufferingNotifier.value = true;
        break;

      case PlayerEventType.bufferingUpdate:
        _updateBufferedProgress();
        break;

      case PlayerEventType.bufferingEnd:
        isBufferingNotifier.value = false;
        _updateBufferedProgress();
        break;

      case PlayerEventType.metadataReady:
      case PlayerEventType.initialized:
        isInitializedNotifier.value = true;
        isBufferingNotifier.value = false;
        if (_pendingResumePosition != null) {
          final pos = _pendingResumePosition!;
          _pendingResumePosition = null;
          seek(pos);
        }
        if (playbackSpeed != 1.0) {
          try {
            betterPlayerController?.setSpeed(playbackSpeed);
          } catch (_) {}
        }
        if (!_qualityTrackApplied && availableQualityTracks.isNotEmpty) {
          _applyPreferredQualityTrack();
        }
        break;

      case PlayerEventType.openFullscreen:
        isFullScreenNotifier.value = true;
        break;

      case PlayerEventType.hideFullscreen:
        isFullScreenNotifier.value = false;
        break;

      case PlayerEventType.finished:
        isPlayingNotifier.value = false;
        _handleEpisodeFinished();
        break;

      case PlayerEventType.changedTrack:
        _safeNotifyListeners();
        break;

      case PlayerEventType.changedSubtitles:
        _safeNotifyListeners();
        break;

      case PlayerEventType.exception:
        log.w('BetterPlayer exception event received: ${event.parameters}');
        if (state == WatchState.loadingStream || state == WatchState.playing) {
          // If playback failed, attempt next playable stream in current watch result
          if (watchResult != null && activeSource != null) {
            final playable = watchResult!.playableStreams;
            final currIdx =
                playable.indexWhere((s) => s.url == activeSource!.url);
            if (currIdx != -1 && currIdx + 1 < playable.length) {
              final nextSource = playable[currIdx + 1];
              log.i(
                  'Exception on ${activeSource!.server}, attempting next stream: ${nextSource.server}');
              setSource(nextSource);
              return;
            }
          }
          state = WatchState.error;
          errorMessage = 'Playback error: Unable to play this stream.';
          _safeNotifyListeners();
        }
        break;

      default:
        break;
    }
  }

  Future<void> _handleEpisodeFinished() async {
    _targetSeekPosition = null;
    _lastSeekTime = null;
    if (_anime != null && currentEpisode != null) {
      final total = durationNotifier.value;
      final finishedEpisode = currentEpisode!;

      // Clear position notifiers so stale playback times do not bleed into subsequent actions
      positionNotifier.value = Duration.zero;
      durationNotifier.value = Duration.zero;

      await _watchRepo.saveProgress(
        anime: _anime!,
        episodeNumber: finishedEpisode.number,
        episodeTitle: finishedEpisode.title,
        episodeThumbnail: finishedEpisode.image,
        position: total,
        duration: total,
        providerId: selectedProviderId,
        audio: selectedAudio.name,
      );

      // Check if this was the final episode of the anime
      await _checkAndSetCompletedIfFinished(finishedEpisode.number);

      // Update resume state pointer to next episode if available (without prematurely mutating currentEpisode)
      final nextNumber = finishedEpisode.number + 1;
      final nextInList = allEpisodesForAudio
          .where((e) => e.number == nextNumber)
          .firstOrNull;
      if (nextInList != null) {
        _saveWatchState(nextInList);
      }

      await _refreshWatchedProgress();
      _safeNotifyListeners();
    }

    if (_prefs.autoNextEpisode && hasNextEpisode) {
      _startAutoNextCountdown();
    }
  }

  void _startAutoNextCountdown() {
    _cancelAutoNextTimer();
    int secondsLeft = _prefs.autoNextDuration;
    if (secondsLeft <= 0) {
      playNextEpisode();
      return;
    }
    autoNextCountdownNotifier.value = secondsLeft;

    _autoNextTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        _cancelAutoNextTimer();
        playNextEpisode();
      } else {
        autoNextCountdownNotifier.value = secondsLeft;
      }
    });
  }

  void cancelAutoNext() {
    _cancelAutoNextTimer();
  }

  void _cancelAutoNextTimer() {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;
    autoNextCountdownNotifier.value = null;
  }

  /// Switch video stream quality / server while preserving playback position.
  Future<void> setSource(StreamSource source) async {
    if (activeSource?.url == source.url) return;
    final previousSource = activeSource;
    final currentPos = positionNotifier.value;
    final requestId = ++_currentRequestId;
    _qualityTrackApplied = false;

    showSkipIntroNotifier.value = false;
    showSkipOutroNotifier.value = false;

    if (watchResult?.intro != null &&
        currentPos.inSeconds > watchResult!.intro!.end) {
      _introDismissed = true;
    }
    if (watchResult?.outro != null &&
        currentPos.inSeconds > watchResult!.outro!.end) {
      _outroDismissed = true;
    }

    try {
      await _setupBetterPlayer(source, requestId, initialPosition: currentPos);
      if (_isDisposed || requestId != _currentRequestId) return;
      activeSource = source;
      _saveAnimePreferences(server: source.server);
      showHudNotice('Server: ${source.server}', Icons.dns_rounded);
      if (currentPos.inSeconds > 0) {
        await seek(currentPos);
      }
      notifyListeners();
    } catch (e) {
      if (_isDisposed || requestId != _currentRequestId) return;
      log.w('Failed to switch to stream ${source.server}: $e');
      activeSource = previousSource;
      _showNotice('Failed to switch to ${source.server}');
      notifyListeners();
    }
  }

  // ── Navigation & Control Actions ──────────────────────────────────────

  Future<void> playNextEpisode() async {
    if (currentEpisode == null) return;
    final nextNumber = currentEpisode!.number + 1;
    final list = allEpisodesForAudio;
    final nextInCurrent =
        list.where((e) => e.number == nextNumber).firstOrNull;

    if (nextInCurrent != null) {
      await playEpisode(nextInCurrent);
      return;
    }

    // Episode is not in current provider's list for this audio track.
    // Query other online providers supporting the active audio track:
    final targetAudio = selectedAudio;
    for (final p in availableProviders) {
      if (p.id == selectedProviderId ||
          !p.supports(targetAudio) ||
          !p.isOnline) {
        continue;
      }
      try {
        final provResult =
            await extractorService.episodes(_anime!.id, p.id);
        if (_isDisposed) return;
        if (provResult == null) continue;

        final candidateList =
            targetAudio == StreamAudio.dub ? provResult.dub : provResult.sub;
        final nextEp = candidateList
            .where((e) => e.number == nextNumber)
            .firstOrNull;
        if (nextEp != null) {
          selectedProviderId = p.id;
          currentProviderEpisodes = provResult;
          final suffix = targetAudio == StreamAudio.dub ? ' (Dub)' : '';
          _showNotice(
            'Switched to ${p.displayName} for Episode $nextNumber$suffix',
          );
          await playEpisode(nextEp, accent: accentColor);
          return;
        }
      } catch (_) {}
    }

    state = WatchState.error;
    if (targetAudio == StreamAudio.dub) {
      errorMessage =
          'Episode $nextNumber is not available in Dubbed audio across any provider.';
      _showNotice('Episode $nextNumber is not available in Dub');
    } else {
      errorMessage =
          'Episode $nextNumber is not available across any provider.';
    }
    notifyListeners();
  }

  bool get isVideoInitialized =>
      betterPlayerController != null &&
      (betterPlayerController?.isInitialized ?? false);

  void play() {
    if (!isVideoInitialized) return;
    try {
      betterPlayerController?.play();
      isPlayingNotifier.value = true;
    } catch (e) {
      log.w('play error: $e');
    }
  }

  void pause() {
    if (!isVideoInitialized) return;
    try {
      betterPlayerController?.pause();
      isPlayingNotifier.value = false;
    } catch (e) {
      log.w('pause error: $e');
    }
  }

  void togglePlay() {
    if (!isVideoInitialized) return;
    try {
      if (isPlayingNotifier.value) {
        betterPlayerController!.pause();
      } else {
        betterPlayerController!.play();
      }
    } catch (e) {
      log.w('togglePlay error: $e');
    }
  }

  Future<void> seek(Duration pos) async {
    if (!isVideoInitialized) return;
    positionNotifier.value = pos;
    _targetSeekPosition = pos;
    _lastSeekTime = DateTime.now();
    showSkipIntroNotifier.value = false;
    showSkipOutroNotifier.value = false;

    if (watchResult?.intro != null && pos.inSeconds > watchResult!.intro!.end) {
      _introDismissed = true;
    }
    if (watchResult?.outro != null && pos.inSeconds > watchResult!.outro!.end) {
      _outroDismissed = true;
    }

    try {
      await betterPlayerController?.seekTo(pos);
    } catch (e) {
      log.w('seek error: $e');
    }
  }

  void seekRelative(Duration delta) {
    if (!isVideoInitialized) return;
    final base = _targetSeekPosition ?? positionNotifier.value;
    final target = base + delta;
    final total = durationNotifier.value;
    final maxMs =
        total.inMilliseconds > 0 ? total.inMilliseconds : double.maxFinite.toInt();
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, maxMs),
    );
    seek(clamped);
  }

  void setSpeed(double speed) {
    playbackSpeed = speed;
    if (isVideoInitialized) {
      try {
        betterPlayerController?.setSpeed(speed);
      } catch (e) {
        log.w('setSpeed error: $e');
      }
    }
    _saveAnimePreferences(playbackSpeed: speed);
    notifyListeners();
  }

  // ── Quality Tracks & Subtitles ───────────────────────────────────────

  /// Currently active subtitle source in the player.
  PlayerSubtitlesSource? get currentSubtitleSource =>
      betterPlayerController?.betterPlayerSubtitlesSource ?? _selectedSubtitle;

  /// Short label for currently active subtitle track (e.g. "EN", "ES", "Off").
  String get currentSubtitleLabel {
    final sub = currentSubtitleSource;
    if (sub == null || sub.type == PlayerSubtitlesSourceType.none) {
      return 'Off';
    }
    final matchingTrack = activeSource?.subtitles.cast<SubtitleTrack?>().firstWhere(
          (s) =>
              s!.label == sub.name ||
              (sub.urls != null && sub.urls!.contains(s.url)),
          orElse: () => null,
        );
    if (matchingTrack != null && matchingTrack.srclang.isNotEmpty) {
      final code = matchingTrack.srclang.toUpperCase();
      return code.length > 4 ? code.substring(0, 3) : code;
    }
    final name = (sub.name ?? '').trim();
    if (name.isEmpty) return 'On';
    final lower = name.toLowerCase();

    bool isLang(String code, String fullName) {
      if (lower == code ||
          lower.startsWith('$code-') ||
          lower.startsWith('$code ') ||
          lower.startsWith('$code(')) {
        return true;
      }
      return lower.contains(fullName);
    }

    if (isLang('en', 'english')) return 'EN';
    if (isLang('es', 'spanish')) return 'ES';
    if (isLang('fr', 'french')) return 'FR';
    if (isLang('de', 'german')) return 'DE';
    if (isLang('pt', 'portuguese')) return 'PT';
    if (isLang('ja', 'japanese')) return 'JA';
    if (isLang('ru', 'russian')) return 'RU';
    if (isLang('ar', 'arabic')) return 'AR';
    if (isLang('it', 'italian')) return 'IT';
    if (isLang('hi', 'hindi')) return 'HI';
    if (isLang('zh', 'chinese')) return 'ZH';
    if (isLang('ko', 'korean')) return 'KO';
    if (name.length <= 4) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }

  /// Whether non-empty subtitles are currently active.
  bool get hasActiveSubtitles =>
      currentSubtitleSource != null &&
      currentSubtitleSource!.type != PlayerSubtitlesSourceType.none;

  /// All subtitle sources available for the currently loaded stream.
  List<PlayerSubtitlesSource> get playerSubtitleSources {
    final list = betterPlayerController?.betterPlayerSubtitlesSourceList;
    if (list != null && list.isNotEmpty) {
      return list
          .where((s) => s.type != PlayerSubtitlesSourceType.none)
          .toList();
    }
    return activeSource?.subtitles
            .map(
              (s) {
                final cached = SubtitleLoader.instance.getCached(s.url);
                return PlayerSubtitlesSource(
                  type: PlayerSubtitlesSourceType.memory,
                  name: s.label,
                  content: cached,
                  urls: [s.url],
                );
              },
            )
            .toList() ??
        const [];
  }

  /// Sets or disables subtitles. Passing null disables subtitles.
  Future<void> setSubtitle(PlayerSubtitlesSource? source) async {
    final subName =
        (source == null || source.type == PlayerSubtitlesSourceType.none)
            ? 'None'
            : (source.name ?? 'None');
    _saveAnimePreferences(subtitleTrack: subName);

    if (source == null || source.type == PlayerSubtitlesSourceType.none) {
      final noneTarget =
          PlayerSubtitlesSource(type: PlayerSubtitlesSourceType.none);
      _selectedSubtitle = noneTarget;
      if (betterPlayerController != null) {
        try {
          await betterPlayerController!.setupSubtitleSource(noneTarget);
        } catch (e) {
          log.w('setSubtitle error: $e');
        }
      }
      _safeNotifyListeners();
      return;
    }

    PlayerSubtitlesSource target = source;
    // If the subtitle content is not yet loaded in memory, load & convert it on device
    if (target.content == null || target.content!.isEmpty) {
      final track = activeSource?.subtitles.cast<SubtitleTrack?>().firstWhere(
            (s) =>
                s!.label == source.name ||
                (source.urls != null && source.urls!.contains(s.url)),
            orElse: () => null,
          );
      if (track != null) {
        final loaded = await SubtitleLoader.instance.loadTrack(
          track,
          extraHeaders:
              activeSource != null ? _buildEffectiveHeaders(activeSource!) : null,
          isSelected: true,
        );
        if (loaded != null) {
          target = loaded;
        }
      }
    }

    _selectedSubtitle = target;

    if (betterPlayerController != null) {
      try {
        await betterPlayerController!.setupSubtitleSource(target);
      } catch (e) {
        log.w('setSubtitle error: $e');
      }
    }
    _safeNotifyListeners();
  }

  /// Available ASMS resolution tracks (e.g. 1080p, 720p, etc.).
  List<PlayerAsmsTrack> get availableQualityTracks =>
      betterPlayerController?.betterPlayerAsmsTracks ?? const [];

  /// Currently active ASMS resolution track (null or height == 0 means Auto).
  PlayerAsmsTrack? get currentQualityTrack =>
      betterPlayerController?.betterPlayerAsmsTrack;

  /// Sets video quality resolution track. Use [PlayerAsmsTrack.defaultTrack()] for Auto.
  void setQualityTrack(PlayerAsmsTrack track) {
    if (betterPlayerController == null) return;
    try {
      betterPlayerController!.setTrack(track);
      _qualityTrackApplied = true;
      final isDefault =
          track == PlayerAsmsTrack.defaultTrack() || (track.height ?? 0) == 0;
      final qLabel = isDefault ? 'manual_auto' : '${track.height}p';
      _saveAnimePreferences(quality: qLabel);
      notifyListeners();
    } catch (e) {
      log.w('setQualityTrack error: $e');
    }
  }

  /// Resolution height of the currently active video track (0 if Auto/unknown).
  int get currentQualityHeight => currentQualityTrack?.height ?? 0;

  /// Formatted label of the currently active video quality (e.g. "Auto", "1080p", "720p").
  String get currentQualityLabel {
    final track = currentQualityTrack;
    final h = track?.height ?? 0;
    final isAuto = track == null ||
        track == PlayerAsmsTrack.defaultTrack() ||
        h == 0;
    if (!isAuto && h > 0) {
      return '${h}p';
    }
    final q = activeSource?.quality;
    if (q != null && q.isNotEmpty) {
      final lower = q.toLowerCase();
      if (lower == 'auto' || lower == 'default') return 'Auto';
      return q;
    }
    return 'Auto';
  }

  /// Whether the current video quality resolution is Auto.
  bool get isAutoQuality {
    final track = currentQualityTrack;
    if (track != null &&
        (track.height ?? 0) > 0 &&
        track != PlayerAsmsTrack.defaultTrack()) {
      return false;
    }
    final q = activeSource?.quality;
    if (q != null && q.isNotEmpty) {
      final lower = q.toLowerCase();
      if (lower != 'auto' && lower != 'default') return false;
    }
    return true;
  }

  // ── Video Aspect Ratio ──

  PlayerAspectRatio _currentAspectRatio = PlayerAspectRatio.fit;
  double? _lastScreenAspect;
  Timer? _aspectRatioNoticeTimer;

  /// High-priority HUD notice for aspect ratio changes.
  final ValueNotifier<String?> aspectRatioNoticeNotifier =
      ValueNotifier<String?>(null);

  void _showAspectRatioNotice(String text) {
    _aspectRatioNoticeTimer?.cancel();
    aspectRatioNoticeNotifier.value = text;
    _aspectRatioNoticeTimer = Timer(const Duration(milliseconds: 1400), () {
      aspectRatioNoticeNotifier.value = null;
    });
  }

  /// Currently active aspect ratio mode.
  PlayerAspectRatio get currentAspectRatio => _currentAspectRatio;

  /// Short label for player bottom controls (e.g. "FIT", "FILL", "STRETCH", "4:3").
  String get currentAspectRatioLabel => switch (_currentAspectRatio) {
        PlayerAspectRatio.fit => 'FIT',
        PlayerAspectRatio.zoom => 'FILL',
        PlayerAspectRatio.stretch => 'STRETCH',
        PlayerAspectRatio.ratio4x3 => '4:3',
      };

  /// User-friendly description for HUD indicator.
  String get currentAspectRatioDescription => switch (_currentAspectRatio) {
        PlayerAspectRatio.fit => 'Fit (16:9)',
        PlayerAspectRatio.zoom => 'Fill Screen (Crop)',
        PlayerAspectRatio.stretch => 'Stretch to Screen',
        PlayerAspectRatio.ratio4x3 => 'Classic 4:3',
      };

  /// Visual icon corresponding to the current aspect ratio mode.
  IconData get currentAspectRatioIcon => switch (_currentAspectRatio) {
        PlayerAspectRatio.fit => Icons.fit_screen_rounded,
        PlayerAspectRatio.zoom => Icons.zoom_out_map_rounded,
        PlayerAspectRatio.stretch => Icons.open_in_full_rounded,
        PlayerAspectRatio.ratio4x3 => Icons.crop_3_2_rounded,
      };

  /// Cycles sequentially through available aspect ratio modes.
  void cycleAspectRatio(double screenAspect) {
    _lastScreenAspect = screenAspect;
    final next = switch (_currentAspectRatio) {
      PlayerAspectRatio.fit => PlayerAspectRatio.zoom,
      PlayerAspectRatio.zoom => PlayerAspectRatio.stretch,
      PlayerAspectRatio.stretch => PlayerAspectRatio.ratio4x3,
      PlayerAspectRatio.ratio4x3 => PlayerAspectRatio.fit,
    };
    setAspectRatio(next, screenAspect);
    _showAspectRatioNotice(currentAspectRatioDescription);
  }

  /// Sets video aspect ratio mode and applies it immediately to BetterPlayer.
  void setAspectRatio(PlayerAspectRatio ratio, [double? screenAspect]) {
    _currentAspectRatio = ratio;
    if (screenAspect != null && screenAspect > 0) {
      _lastScreenAspect = screenAspect;
    }
    _applyAspectRatio();
    _safeNotifyListeners();
  }

  /// Updates cached screen aspect ratio without notifying listeners.
  void updateScreenAspect(double screenAspect) {
    if (screenAspect > 0 &&
        (screenAspect - (_lastScreenAspect ?? 0)).abs() > 0.01) {
      _lastScreenAspect = screenAspect;
      if (_currentAspectRatio == PlayerAspectRatio.zoom ||
          _currentAspectRatio == PlayerAspectRatio.stretch) {
        _applyAspectRatio();
      }
    }
  }

  void _applyAspectRatio() {
    final controller = betterPlayerController;
    if (controller == null) return;

    final screenAspect = _lastScreenAspect ?? (16 / 9);

    switch (_currentAspectRatio) {
      case PlayerAspectRatio.fit:
        controller.setOverriddenAspectRatio(16 / 9);
        controller.setOverriddenFit(BoxFit.contain);
      case PlayerAspectRatio.zoom:
        controller.setOverriddenAspectRatio(screenAspect);
        controller.setOverriddenFit(BoxFit.cover);
      case PlayerAspectRatio.stretch:
        controller.setOverriddenAspectRatio(screenAspect);
        controller.setOverriddenFit(BoxFit.fill);
      case PlayerAspectRatio.ratio4x3:
        controller.setOverriddenAspectRatio(4 / 3);
        controller.setOverriddenFit(BoxFit.contain);
    }
  }

  /// Display name of the currently selected provider (e.g. "Aniwaves", "AnimeOnsen").
  String get activeProviderDisplayName {
    if (selectedProviderId == null) return '';
    final info = availableProviders
        .where((p) => p.id == selectedProviderId)
        .firstOrNull;
    if (info != null) return info.displayName;
    final id = selectedProviderId!;
    return id.isEmpty ? id : id[0].toUpperCase() + id.substring(1);
  }

  Future<void> syncDeviceVolumeAndBrightness() async {
    final vol = await DeviceControl.getVolume();
    final br = await DeviceControl.getBrightness();
    volumeNotifier.value = vol;
    brightnessNotifier.value = br;
  }

  void setVolume(double volume) {
    final v = volume.clamp(0.0, 1.0);
    volumeNotifier.value = v;
    DeviceControl.setVolume(v);
    if (isVideoInitialized) {
      try {
        betterPlayerController?.setVolume(1.0);
      } catch (e) {
        log.w('setVolume error: $e');
      }
    }
  }

  void setBrightness(double b) {
    final clamped = b.clamp(0.0, 1.0);
    brightnessNotifier.value = clamped;
    DeviceControl.setBrightness(clamped);
  }

  void setSpeedBoost(bool active) {
    if (isSpeedBoostedNotifier.value == active) return;
    isSpeedBoostedNotifier.value = active;
    betterPlayerController?.setSpeed(active ? 2.0 : playbackSpeed);
  }

  void toggleControlsLock() {
    isControlsLockedNotifier.value = !isControlsLockedNotifier.value;
  }

  void skipIntro({bool isAuto = false}) {
    final intro = watchResult?.intro;
    if (intro == null) return;
    _introDismissed = true;
    showSkipIntroNotifier.value = false;
    if (isAuto) {
      showHudNotice('Intro Skipped', Icons.fast_forward_rounded);
    }
    seek(Duration(seconds: intro.end + 1));
  }

  void skipOutro({bool isAuto = false}) {
    final outro = watchResult?.outro;
    if (outro == null) return;
    _outroDismissed = true;
    showSkipOutroNotifier.value = false;
    if (isAuto) {
      showHudNotice('Outro Skipped', Icons.skip_next_rounded);
    }
    seek(Duration(seconds: outro.end + 1));
  }

  /// Pauses playback and stops audio when user switches to Info tab or leaves screen.
  void handleTabVisibility(bool isVisible) {
    if (!isVisible) {
      _currentRequestId++;
      betterPlayerController?.pause();
      isPlayingNotifier.value = false;
      _cancelAutoNextTimer();
      if (state == WatchState.loadingStream || state == WatchState.playing) {
        state = WatchState.episodesReady;
      }
    }
  }

  void retry() {
    final a = _anime;
    if (a != null) {
      _anime = null;
      init(a, accent: accentColor);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _stopPlayback() {
    _currentRequestId++;
    _targetSeekPosition = null;
    _lastSeekTime = null;
    _disposePlayerController();
    isPlayingNotifier.value = false;
    _cancelAutoNextTimer();
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    bufferedNotifier.value = Duration.zero;
  }

  void _updateBufferedProgress() {
    final bufferedList = betterPlayerController?.videoPlayerValue?.buffered;
    if (bufferedList != null && bufferedList.isNotEmpty) {
      final currentPos = positionNotifier.value;
      Duration? bestEnd;
      for (final range in bufferedList) {
        if (currentPos >= range.start && currentPos <= range.end) {
          bestEnd = range.end;
          break;
        }
      }
      bestEnd ??= bufferedList.last.end;
      if (bufferedNotifier.value != bestEnd) {
        bufferedNotifier.value = bestEnd;
      }
    }
  }

  void _showNotice(String message) {
    statusNotice = message;
    notifyListeners();
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 4), () {
      if (!_isDisposed) {
        statusNotice = null;
        notifyListeners();
      }
    });
  }

  PlayerSubtitlesConfiguration _buildSubtitlesConfiguration() {
    final fontSize = _prefs.subtitleFontSize;
    final fontColor = switch (_prefs.subtitleTextColor) {
      'yellow' => const Color(0xFFFFEB3B),
      'cyan' => const Color(0xFF00E5FF),
      _ => Colors.white,
    };
    final outlineStyle = _prefs.subtitleOutlineStyle;
    final isOutline = outlineStyle == 'outline';
    final isBackground = outlineStyle == 'background';

    return PlayerSubtitlesConfiguration(
      fontSize: fontSize,
      fontColor: fontColor,
      outlineEnabled: isOutline,
      outlineColor: isOutline ? Colors.black : Colors.transparent,
      outlineSize: isOutline ? 2.2 : 0.0,
      bottomPadding: 24.0,
      backgroundColor: isBackground
          ? Colors.black.withValues(alpha: 0.70)
          : Colors.transparent,
    );
  }

  void _onPlaybackStarted() {
    if (_hasRecordedPlaybackStart || _isDisposed || currentEpisode == null) return;
    _hasRecordedPlaybackStart = true;
    _saveWatchState(currentEpisode!);
    _autoUpdateWatchStatusOnPlay();
  }

  void _saveWatchState(EpisodeItem ep) {
    if (_anime != null && selectedProviderId != null) {
      _watchRepo.saveWatchState(
        _anime!,
        episode: ep.number,
        provider: selectedProviderId!,
        audio: ep.audio.name,
        episodeTitle: ep.title,
        episodeThumbnail: ep.image,
      );
    }
  }

  void _saveAnimePreferences({
    String? provider,
    String? audio,
    String? server,
    String? subtitleTrack,
    double? playbackSpeed,
    String? quality,
  }) {
    if (_anime == null) return;
    if (server != null) _preferredServer = server;
    if (subtitleTrack != null) _preferredSubtitleTrack = subtitleTrack;
    if (quality != null) _preferredQuality = quality;

    _watchRepo.saveAnimePreferences(
      _anime!.id,
      anime: _anime,
      provider: provider,
      audio: audio,
      server: server,
      subtitleTrack: subtitleTrack,
      playbackSpeed: playbackSpeed,
      quality: quality,
    );
  }

  /// Automatically moves anime to 'watching' if it had no status or was in 'plan_to_watch'.
  Future<void> _autoUpdateWatchStatusOnPlay() async {
    if (_anime == null) return;
    try {
      final status = await CollectionRepository.instance.getAnimeStatus(_anime!.id);
      if (status == null || status == 'plan_to_watch') {
        await CollectionRepository.instance.setAnimeStatus(_anime!, 'watching');
      }
    } catch (e) {
      log.w('Failed to auto update watch status to watching: $e');
    }
  }

  /// Automatically marks anime as 'completed' if the final episode has been watched.
  Future<void> _checkAndSetCompletedIfFinished(int episodeNumber) async {
    if (_anime == null) return;
    try {
      final totalEps = _anime!.episodes;
      final isLastEpByCount = totalEps != null && totalEps > 0 && episodeNumber >= totalEps;
      final hasNextInList = allEpisodesForAudio.any((e) => e.number > episodeNumber);
      final isAnimeFinished = _anime!.status == 'FINISHED';

      if (isLastEpByCount || (!hasNextInList && isAnimeFinished)) {
        final currentStatus = await CollectionRepository.instance.getAnimeStatus(_anime!.id);
        if (currentStatus != 'completed') {
          await CollectionRepository.instance.setAnimeStatus(_anime!, 'completed');
          _showNotice('Completed "${_anime!.title}"! Moved to Completed list.');
        }
      }
    } catch (e) {
      log.w('Failed to auto update status to completed: $e');
    }
  }

  void _applyPreferredQualityTrack() {
    final isExplicitAuto = _preferredQuality?.toLowerCase() == 'manual_auto';
    final hasSpecificOverride = _preferredQuality != null &&
        _preferredQuality!.isNotEmpty &&
        _preferredQuality!.toLowerCase() != 'default' &&
        _preferredQuality!.toLowerCase() != 'auto' &&
        !isExplicitAuto;

    final effectiveQuality = isExplicitAuto
        ? 'auto'
        : (hasSpecificOverride ? _preferredQuality! : _prefs.streamingQuality);

    if (effectiveQuality.isEmpty) return;
    final tracks = availableQualityTracks;
    if (tracks.isEmpty) return;

    final target = effectiveQuality.toLowerCase().replaceAll('p', '').trim();
    if (target == 'auto' || target == 'default') {
      try {
        betterPlayerController?.setTrack(PlayerAsmsTrack.defaultTrack());
        _qualityTrackApplied = true;
        _safeNotifyListeners();
      } catch (_) {}
      return;
    }

    final targetHeight = int.tryParse(target);
    if (targetHeight != null && targetHeight > 0) {
      final matchingTracks =
          tracks.where((t) => t.height == targetHeight).toList()
            ..sort((a, b) => (b.bitrate ?? 0).compareTo(a.bitrate ?? 0));

      final matching = matchingTracks.firstOrNull;
      if (matching != null && matching.height != null && matching.height! > 0) {
        try {
          betterPlayerController?.setTrack(matching);
          _qualityTrackApplied = true;
          _safeNotifyListeners();
        } catch (e) {
          log.w('_applyPreferredQualityTrack error: $e');
        }
      } else {
        final fallback = tracks.where((t) => (t.height ?? 0) > 0).toList()
          ..sort((a, b) => b.height!.compareTo(a.height!));
        if (fallback.isNotEmpty) {
          final best = fallback.firstWhere(
            (t) => (t.height ?? 0) <= targetHeight,
            orElse: () => fallback.first,
          );
          try {
            betterPlayerController?.setTrack(best);
            _qualityTrackApplied = true;
            _safeNotifyListeners();
          } catch (e) {
            log.w('_applyPreferredQualityTrack fallback error: $e');
          }
        }
      }
    }
  }

  Future<void> _refreshWatchedProgress() async {
    if (_isDisposed) return;
    if (_anime != null) {
      final progressMap = await _watchRepo.getAllEpisodeProgress(_anime!.id);
      if (_isDisposed) return;
      episodeProgressMap = progressMap;
      watchedPercentages = {
        for (final entry in progressMap.entries) entry.key: entry.value.percent,
      };

      // If playback is halted and the current episode is already completed (>= 90%),
      // advance currentEpisode to the next unwatched episode so that the hero banner
      // and episode selector point to the next episode to watch.
      if (state != WatchState.playing && state != WatchState.loadingStream) {
        if (currentEpisode != null) {
          final currentPercent =
              watchedPercentages[currentEpisode!.number] ?? 0.0;
          if (currentPercent >= 0.90) {
            EpisodeItem? nextUnwatched;
            for (final ep in allEpisodesForAudio) {
              if (ep.number > currentEpisode!.number) {
                final pct = watchedPercentages[ep.number] ?? 0.0;
                if (pct < 0.90) {
                  nextUnwatched = ep;
                  break;
                }
              }
            }
            nextUnwatched ??= allEpisodesForAudio
                .where((e) => e.number == currentEpisode!.number + 1)
                .firstOrNull;

            if (nextUnwatched != null && !_isDisposed) {
              currentEpisode = nextUnwatched;
              syncChunkWithCurrentEpisode();
              _saveWatchState(nextUnwatched);
            }
          }
        }
      }

      _safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _extensionSubscription?.cancel();
    _cancelAutoNextTimer();
    _noticeTimer?.cancel();
    _aspectRatioNoticeTimer?.cancel();
    _hudNoticeTimer?.cancel();

    // Flush progress to database if active before disposing notifiers
    if (_anime != null && currentEpisode != null) {
      try {
        final currentPos = positionNotifier.value;
        final totalDur = durationNotifier.value;
        if (totalDur.inSeconds > 0 && currentPos.inSeconds > 0) {
          _watchRepo.saveProgress(
            anime: _anime!,
            episodeNumber: currentEpisode!.number,
            episodeTitle: currentEpisode!.title,
            episodeThumbnail: currentEpisode!.image,
            position: currentPos,
            duration: totalDur,
            providerId: selectedProviderId,
            audio: selectedAudio.name,
          );
        }
      } catch (_) {}
    }

    try {
      aspectRatioNoticeNotifier.dispose();
      hudNoticeNotifier.dispose();
    } catch (_) {}
    SubtitleLoader.instance.clearCache();
    _disposePlayerController();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    try {
      positionNotifier.dispose();
      durationNotifier.dispose();
      bufferedNotifier.dispose();
      isPlayingNotifier.dispose();
      isBufferingNotifier.dispose();
      showSkipIntroNotifier.dispose();
      showSkipOutroNotifier.dispose();
      isControlsLockedNotifier.dispose();
      isSpeedBoostedNotifier.dispose();
      volumeNotifier.dispose();
      brightnessNotifier.dispose();
      autoNextCountdownNotifier.dispose();
      isInitializedNotifier.dispose();
      isFullScreenNotifier.dispose();
    } catch (_) {}
    super.dispose();
  }
}
