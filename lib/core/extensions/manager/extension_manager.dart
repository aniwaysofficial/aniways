import 'dart:async';

import 'package:aniways/core/database/repositories/extension_database_repository.dart';
import 'package:aniways/core/extensions/models/extension_manifest.dart';
import 'package:aniways/core/extensions/runtime/extension_runtime.dart';
import 'package:aniways/core/extensions/storage/extension_file_storage.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/network/extractor_service.dart';

/// Global singleton for managing client-side anime extensions.
final ExtensionManager extensionManager = ExtensionManager._();

class ExtensionManager {
  ExtensionManager._({
    ExtensionRuntime? runtime,
    ExtensionDatabaseRepository? dbRepo,
    ExtensionFileStorage? fileStorage,
    AnilistService? anilistServiceParam,
  })  : _runtime = runtime ?? ExtensionRuntime(),
        _dbRepo = dbRepo ?? ExtensionDatabaseRepository(),
        _fileStorage = fileStorage ?? ExtensionFileStorage(),
        _aniListService = anilistServiceParam ?? anilistService {
    _initCache();
  }

  final ExtensionRuntime _runtime;
  final ExtensionDatabaseRepository _dbRepo;
  final ExtensionFileStorage _fileStorage;
  final AnilistService _aniListService;

  bool _isInitialized = false;
  List<ExtensionManifest> _installedCache = [];
  bool _cacheLoaded = false;
  StreamSubscription? _cacheSub;

  bool get isInitialized => _isInitialized;
  bool get isCacheLoaded => _cacheLoaded;
  bool get hasInstalledExtensions => _installedCache.isNotEmpty;
  bool get hasEnabledExtensions => _installedCache.any((e) => e.isEnabled);
  List<ExtensionManifest> get installedExtensions =>
      List.unmodifiable(_installedCache);
  List<ExtensionManifest> get enabledExtensions =>
      _installedCache.where((e) => e.isEnabled).toList();

  ExtensionDatabaseRepository get dbRepository => _dbRepo;

  void _initCache() {
    _cacheSub = _dbRepo.watchInstalledExtensions().listen((list) {
      _installedCache = list;
      _cacheLoaded = true;
    });
  }

  /// Disposes resources held by the manager.
  void dispose() {
    _cacheSub?.cancel();
  }

  /// Initializes the JS runtime and loads all enabled installed extensions.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _runtime.init();

      final all = await _dbRepo.getInstalledExtensions();
      _installedCache = all;
      _cacheLoaded = true;

      final enabled = all.where((e) => e.isEnabled).toList();
      for (final ext in enabled) {
        final script = await _fileStorage.readScript(ext.id);
        if (script != null && script.isNotEmpty) {
          final loaded = await _runtime.loadExtension(ext.id, script);
          if (loaded) {
            log.i('ExtensionManager: Loaded extension ${ext.name} (${ext.id})');
          } else {
            log.w('ExtensionManager: Failed to evaluate extension ${ext.id}');
          }
        } else {
          log.w('ExtensionManager: Script file missing for extension ${ext.id}');
        }
      }

      _isInitialized = true;
      log.i('ExtensionManager initialized successfully.');
    } catch (e) {
      log.e('ExtensionManager initialization failed: $e');
    }
  }

  /// Installs or updates an extension from script content and manifest.
  Future<bool> installExtension(ExtensionManifest manifest, String scriptCode) async {
    if (!_isInitialized) await initialize();

    try {
      // 1. Save script to disk
      final localPath = await _fileStorage.saveScript(manifest.id, scriptCode);

      // 2. Load into JS runtime
      final loaded = await _runtime.loadExtension(manifest.id, scriptCode);
      if (!loaded) {
        log.w('ExtensionManager: Script did not register valid extension.');
        return false;
      }

      // 3. Save to Drift database
      await _dbRepo.upsertExtension(manifest, localPath);
      log.i('ExtensionManager: Extension ${manifest.name} installed successfully.');
      return true;
    } catch (e) {
      log.e('ExtensionManager: Failed to install extension ${manifest.id}: $e');
      return false;
    }
  }

  /// Uninstalls an extension.
  Future<void> uninstallExtension(String id) async {
    try {
      _runtime.unloadExtension(id);
      await _fileStorage.deleteScript(id);
      await _dbRepo.deleteExtension(id);
      log.i('ExtensionManager: Uninstalled extension $id.');
    } catch (e) {
      log.e('ExtensionManager: Failed to uninstall extension $id: $e');
    }
  }

  /// Toggles an extension active/inactive.
  Future<void> toggleExtension(String id, bool isEnabled) async {
    await _dbRepo.setExtensionEnabled(id, isEnabled);
    if (isEnabled) {
      final script = await _fileStorage.readScript(id);
      if (script != null) {
        await _runtime.loadExtension(id, script);
      }
    } else {
      _runtime.unloadExtension(id);
    }
  }

  /// Returns all active extensions as [ProviderInfo] for the player UI.
  Future<List<ProviderInfo>> getAvailableProviders() async {
    if (!_isInitialized) await initialize();

    if (_cacheLoaded) {
      return enabledExtensions.map((e) => e.toProviderInfo()).toList();
    }
    final enabled = await _dbRepo.getEnabledExtensions();
    return enabled.map((e) => e.toProviderInfo()).toList();
  }

  /// Resolves episode list for [anilistId] via extension [providerId].
  Future<ProviderEpisodes?> getEpisodes(int anilistId, String providerId) async {
    if (!_isInitialized) await initialize();

    try {
      // 1. Fetch anime metadata from AniList
      final media = await _aniListService.details(anilistId);
      final titlesMap = (media['title'] as Map?)?.cast<String, dynamic>() ?? {};
      final startDate = (media['startDate'] as Map?)?.cast<String, dynamic>() ?? {};

      final animeMeta = {
        'anilistId': anilistId,
        'malId': media['idMal'],
        'titles': {
          'romaji': (titlesMap['romaji'] as String?) ?? '',
          'english': titlesMap['english'] as String?,
          'native': titlesMap['native'] as String?,
          'synonyms': (media['synonyms'] as List?)?.map((e) => e.toString()).toList() ?? [],
        },
        'year': (startDate['year'] as num?)?.toInt() ?? (media['seasonYear'] as num?)?.toInt(),
        'format': media['format'] as String?,
        'episodesCount': (media['episodes'] as num?)?.toInt(),
      };

      // 2. Call extension getEpisodes
      final rawEpisodes = await _runtime.getEpisodes(providerId, animeMeta);
      if (rawEpisodes.isEmpty) {
        log.w('ExtensionManager: No episodes returned by $providerId for $anilistId');
        return null;
      }

      // 3. Partition into sub and dub
      final subList = <EpisodeItem>[];
      final dubList = <EpisodeItem>[];

      for (final raw in rawEpisodes) {
        final epNum = (raw['number'] as num?)?.toInt() ?? 0;
        final epTitle = (raw['title'] as String?) ?? 'Episode $epNum';
        final epRef = (raw['ref'] as String?) ?? epNum.toString();
        final isFiller = (raw['filler'] as bool?) ?? false;
        final isRecap = (raw['recap'] as bool?) ?? false;
        final duration = (raw['duration'] as num?)?.toInt();
        final airDate = raw['airDate'] as String?;
        final image = raw['image'] as String?;
        final description = raw['description'] as String?;
        final bool hasSub = (raw['sub'] as bool?) ?? true;
        final bool hasDub = (raw['dub'] as bool?) ?? false;

        // Encode provider, anilistId, audio, and ref into EpisodeItem.id
        if (hasSub) {
          subList.add(EpisodeItem(
            id: 'ext:$providerId:$anilistId:sub:$epRef',
            number: epNum,
            title: epTitle,
            audio: StreamAudio.sub,
            filler: isFiller,
            recap: isRecap,
            duration: duration,
            airDate: airDate,
            image: image,
            description: description,
          ));
        }

        if (hasDub) {
          dubList.add(EpisodeItem(
            id: 'ext:$providerId:$anilistId:dub:$epRef',
            number: epNum,
            title: epTitle,
            audio: StreamAudio.dub,
            filler: isFiller,
            recap: isRecap,
            duration: duration,
            airDate: airDate,
            image: image,
            description: description,
          ));
        }
      }

      return ProviderEpisodes(
        providerId: providerId,
        providerTitle: providerId,
        matchScore: 1000.0,
        sub: subList,
        dub: dubList,
      );
    } catch (e, st) {
      log.e('ExtensionManager: Failed to getEpisodes from $providerId: $e', error: e, stackTrace: st);
      return null;
    }
  }

  /// Resolves video playback stream URLs for an [EpisodeItem].
  Future<WatchResult> watch(String providerId, int anilistId, EpisodeItem ep) async {
    if (!_isInitialized) await initialize();

    String actualRef = ep.id;
    String actualProvider = providerId;
    int actualAnilist = anilistId;

    if (ep.id.startsWith('ext:')) {
      final parts = ep.id.split(':');
      if (parts.length >= 5) {
        actualProvider = parts[1];
        actualAnilist = int.tryParse(parts[2]) ?? anilistId;
        actualRef = parts.sublist(4).join(':');
      }
    }

    try {
      final rawResult = await _runtime.getStreams(
        actualProvider,
        actualRef,
        ep.audio.name,
      );

      final streams = <StreamSource>[];
      if (rawResult != null && rawResult['streams'] is List) {
        final list = rawResult['streams'] as List;
        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map) {
            final map = item.cast<String, dynamic>();
            final url = map['url'] as String? ?? '';
            if (url.isEmpty) continue;

            final typeStr = map['type'] as String? ?? 'hls';
            final type = switch (typeStr.toLowerCase()) {
              'mp4' => StreamType.mp4,
              'dash' => StreamType.dash,
              'embed' => StreamType.embed,
              _ => StreamType.hls,
            };

            final server = (map['server'] as String?) ?? 'Server ${i + 1}';
            final quality = map['quality'] as String?;

            final rawHeaders = map['headers'];
            final headers = <String, String>{};
            if (rawHeaders is Map) {
              for (final entry in rawHeaders.entries) {
                headers[entry.key.toString()] = entry.value.toString();
              }
            }

            final subs = <SubtitleTrack>[];
            if (map['subtitles'] is List) {
              for (final s in map['subtitles'] as List) {
                if (s is Map) {
                  subs.add(SubtitleTrack.fromJson(s.cast<String, dynamic>()));
                }
              }
            }

            streams.add(StreamSource(
              url: url,
              type: type,
              server: server,
              quality: quality,
              headers: headers,
              subtitles: subs,
              isActive: i == 0,
            ));
          }
        }
      }

      final parsedIntro = TimeRange.fromJson(rawResult?['intro']);
      final parsedOutro = TimeRange.fromJson(rawResult?['outro']);
      final validOutro = (parsedOutro != null &&
              parsedOutro.start > 0 &&
              parsedOutro.end > parsedOutro.start &&
              (parsedIntro == null || parsedOutro.start >= parsedIntro.end))
          ? parsedOutro
          : null;

      return WatchResult(
        anilistId: actualAnilist,
        episode: ep.number,
        audio: ep.audio,
        provider: actualProvider,
        streams: streams,
        intro: parsedIntro,
        outro: validOutro,
      );
    } catch (e, st) {
      log.e('ExtensionManager: watch failed for $providerId: $e', error: e, stackTrace: st);
      return WatchResult(
        anilistId: actualAnilist,
        episode: ep.number,
        audio: ep.audio,
        provider: actualProvider,
        streams: const [],
      );
    }
  }
}
