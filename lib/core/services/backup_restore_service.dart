import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aniways/core/constants.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/services/app_info_service.dart';
import 'package:aniways/core/services/saf_storage_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/providers/theme_provider.dart';

/// Represents a discovered backup file entry (either in local app storage or user SAF folder).
class BackupItem {
  const BackupItem({
    required this.name,
    required this.pathOrUri,
    required this.isSaf,
    required this.sizeBytes,
    this.lastModified,
    this.file,
  });

  final String name;
  final String pathOrUri;
  final bool isSaf;
  final int sizeBytes;
  final DateTime? lastModified;
  final File? file;
}

/// Summary metadata for a parsed backup file.
class BackupSummary {
  const BackupSummary({
    required this.version,
    required this.appName,
    required this.appVersion,
    required this.createdAt,
    required this.animeCount,
    required this.collectionEntriesCount,
    this.collectionsCount = 0,
    required this.watchHistoryCount,
    required this.episodeProgressCount,
    required this.settingsCount,
    required this.rawData,
  });

  final int version;
  final String appName;
  final String appVersion;
  final DateTime createdAt;
  final int animeCount;
  final int collectionEntriesCount;
  final int collectionsCount;
  final int watchHistoryCount;
  final int episodeProgressCount;
  final int settingsCount;
  final Map<String, dynamic> rawData;
}

/// Service for exporting, importing, verifying, and restoring app backups
/// using the compressed `.anw` (or legacy `.hnm`) format.
class BackupRestoreService {
  BackupRestoreService._internal();
  static final BackupRestoreService instance = BackupRestoreService._internal();
  factory BackupRestoreService() => instance;

  static const String backupExtension = 'anw';
  static const String legacyBackupExtension = 'hnm';
  static const int currentBackupVersion = 1;

  final AppDatabase _db = AppDatabase.instance;

  /// Dedicated app-storage backup directory. Guaranteed writable and readable without extra permissions.
  Future<Directory> getDefaultBackupDirectory() async {
    Directory? baseDir;
    try {
      baseDir = await getExternalStorageDirectory();
    } catch (_) {}

    baseDir ??= await getApplicationDocumentsDirectory();

    final defaultDir =
        Directory('${baseDir.path}${Platform.pathSeparator}backups');
    if (!await defaultDir.exists()) {
      await defaultDir.create(recursive: true);
    }
    return defaultDir;
  }

  /// Checks whether direct POSIX filesystem writes succeed in the given directory.
  Future<bool> isDirectoryWritable(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final testFile = File(
          '${dir.path}${Platform.pathSeparator}.write_test_${DateTime.now().millisecondsSinceEpoch}');
      await testFile.writeAsString('test', flush: true);
      await testFile.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns user-friendly display name of the current backup location (e.g. "Aniways/backups").
  String getBackupLocationDisplayName() {
    final prefs = SharedPreferencesService();
    final customPath = prefs.backupDirectoryPath;
    if (customPath != null && customPath.trim().isNotEmpty) {
      var clean = customPath;
      if (clean.startsWith('/storage/emulated/0/')) {
        clean = clean.replaceFirst('/storage/emulated/0/', '');
      }
      final lower = clean.toLowerCase();
      if (!lower.endsWith('/backups') &&
          !lower.endsWith('/backup') &&
          lower != 'backups' &&
          lower != 'backup') {
        return '$clean/backups';
      }
      return clean;
    }
    return 'Default (App Storage)';
  }

  /// Returns all existing .hnm backup files from both the SAF tree directory and default storage,
  /// deduplicated by filename and sorted from newest to oldest.
  Future<List<BackupItem>> getExistingBackups() async {
    try {
      final items = <BackupItem>[];
      final seenNames = <String>{};

      // 1. Check SAF tree directory if configured on Android (Mihon architecture)
      final treeUri = SharedPreferencesService().backupTreeUri;
      if (Platform.isAndroid && treeUri != null && treeUri.isNotEmpty) {
        final safFiles = await SafStorageService.instance.listFiles(
          treeUri: treeUri,
          extension: backupExtension,
        );
        for (final sf in safFiles) {
          if (seenNames.add(sf.name)) {
            items.add(BackupItem(
              name: sf.name,
              pathOrUri: sf.uri,
              isSaf: true,
              sizeBytes: sf.size,
              lastModified: sf.lastModified,
            ));
          }
        }
        // Also include legacy .hnm backups
        final legacySafFiles = await SafStorageService.instance.listFiles(
          treeUri: treeUri,
          extension: legacyBackupExtension,
        );
        for (final sf in legacySafFiles) {
          if (seenNames.add(sf.name)) {
            items.add(BackupItem(
              name: sf.name,
              pathOrUri: sf.uri,
              isSaf: true,
              sizeBytes: sf.size,
              lastModified: sf.lastModified,
            ));
          }
        }
      }

      // 2. Check custom POSIX path if configured and accessible (e.g. desktop/iOS)
      final customPath = SharedPreferencesService().backupDirectoryPath;
      if (customPath != null && customPath.isNotEmpty) {
        var dirPath = customPath;
        final lower = dirPath.toLowerCase();
        if (!lower.endsWith('/backups') && !lower.endsWith('/backup')) {
          dirPath = '$dirPath${Platform.pathSeparator}backups';
        }
        final targetDir = Directory(dirPath);
        if (await targetDir.exists()) {
          try {
            await for (final entity in targetDir.list(followLinks: false)) {
              if (entity is File &&
                  (entity.path.endsWith('.$backupExtension') ||
                      entity.path.endsWith('.$legacyBackupExtension'))) {
                final name = entity.path.split(Platform.pathSeparator).last;
                if (seenNames.add(name)) {
                  int size = 0;
                  DateTime? mod;
                  try {
                    size = entity.lengthSync();
                    mod = entity.lastModifiedSync();
                  } catch (_) {}
                  items.add(BackupItem(
                    name: name,
                    pathOrUri: entity.path,
                    isSaf: false,
                    sizeBytes: size,
                    lastModified: mod,
                    file: entity,
                  ));
                }
              }
            }
          } catch (_) {}
        }
      }

      // 3. Check default dedicated app storage directory
      final defaultDir = await getDefaultBackupDirectory();
      if (await defaultDir.exists()) {
        try {
          await for (final entity in defaultDir.list(followLinks: false)) {
            if (entity is File &&
                (entity.path.endsWith('.$backupExtension') ||
                    entity.path.endsWith('.$legacyBackupExtension'))) {
              final name = entity.path.split(Platform.pathSeparator).last;
              if (seenNames.add(name)) {
                int size = 0;
                DateTime? mod;
                try {
                  size = entity.lengthSync();
                  mod = entity.lastModifiedSync();
                } catch (_) {}
                items.add(BackupItem(
                  name: name,
                  pathOrUri: entity.path,
                  isSaf: false,
                  sizeBytes: size,
                  lastModified: mod,
                  file: entity,
                ));
              }
            }
          }
        } catch (_) {}
      }

      items.sort((a, b) {
        final aTime = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return items;
    } catch (e) {
      log.w('Failed to list existing backups: $e');
      return [];
    }
  }

  /// Enforces max automatic backups retention limit.
  Future<void> pruneOldAutoBackups() async {
    try {
      final maxBackups = SharedPreferencesService().maxAutoBackups;

      // 1. Prune from SAF directory if configured
      final treeUri = SharedPreferencesService().backupTreeUri;
      if (Platform.isAndroid && treeUri != null && treeUri.isNotEmpty) {
        final safFiles = await SafStorageService.instance.listFiles(
          treeUri: treeUri,
          extension: backupExtension,
        );
        final autoSaf = safFiles.where((f) => f.name.contains('auto')).toList();
        if (autoSaf.length > maxBackups) {
          autoSaf.sort((a, b) => b.lastModified.compareTo(a.lastModified));
          for (var i = maxBackups; i < autoSaf.length; i++) {
            await SafStorageService.instance.deleteFile(autoSaf[i].uri);
            log.i('Pruned old auto-backup via SAF: ${autoSaf[i].name}');
          }
        }
      }

      // 2. Prune from default app storage directory
      final defaultDir = await getDefaultBackupDirectory();
      if (await defaultDir.exists()) {
        final autoFiles = <File>[];
        try {
          await for (final entity in defaultDir.list(followLinks: false)) {
            if (entity is File &&
                entity.path.endsWith('.$backupExtension') &&
                entity.path.contains('auto')) {
              autoFiles.add(entity);
            }
          }
          if (autoFiles.length > maxBackups) {
            autoFiles.sort((a, b) {
              try {
                return b.lastModifiedSync().compareTo(a.lastModifiedSync());
              } catch (_) {
                return 0;
              }
            });
            for (var i = maxBackups; i < autoFiles.length; i++) {
              try {
                await autoFiles[i].delete();
                log.i('Pruned old auto-backup in default storage: ${autoFiles[i].path}');
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      log.w('Failed to prune auto-backups: $e');
    }
  }

  /// Checks whether an automatic backup is due (daily/weekly) and runs it silently.
  Future<void> checkAndRunAutoBackup() async {
    try {
      final prefs = SharedPreferencesService();
      final freq = prefs.autoBackupFrequency;
      if (freq == 'off') return;

      final now = DateTime.now();
      final lastBackupStr = prefs.lastAutoBackupTime;
      if (lastBackupStr != null && lastBackupStr.isNotEmpty) {
        final lastTime = DateTime.tryParse(lastBackupStr);
        if (lastTime != null) {
          final diff = now.difference(lastTime);
          if (freq == 'daily' && diff.inHours < 24) {
            log.d('Auto-backup daily not due yet (${diff.inHours}h since last)');
            return;
          }
          if (freq == 'weekly' && diff.inDays < 7) {
            log.d('Auto-backup weekly not due yet (${diff.inDays}d since last)');
            return;
          }
        }
      }

      log.i('Running automatic backup ($freq)...');
      await createBackup(
        includeLibrary: true,
        includeProgress: true,
        includeSettings: true,
        isAuto: true,
      );
      log.i('Automatic backup completed successfully.');
    } catch (e) {
      log.e('Failed to run automatic backup: $e');
    }
  }

  /// Deletes a backup item (from SAF or local storage).
  Future<bool> deleteBackupItem(BackupItem item) async {
    try {
      if (item.isSaf && Platform.isAndroid) {
        return await SafStorageService.instance.deleteFile(item.pathOrUri);
      } else if (item.file != null) {
        if (await item.file!.exists()) {
          await item.file!.delete();
          return true;
        }
      } else {
        final f = File(item.pathOrUri);
        if (await f.exists()) {
          await f.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      log.e('Failed to delete backup: $e');
      return false;
    }
  }

  /// Generates the compressed `.hnm` backup bytes.
  Future<Uint8List> generateBackupBytes({
    bool includeLibrary = true,
    bool includeProgress = true,
    bool includeSettings = true,
  }) async {
    final now = DateTime.now().toUtc();
    final dataMap = <String, dynamic>{};

    // 1. Settings
    if (includeSettings) {
      dataMap['settings'] = SharedPreferencesService().exportSettings();
    }

    // Collect referenced anime IDs to ensure we only export anime records that
    // have actual user data (collections, preferences, history, or progress)
    final referencedAnimeIds = <int>{};

    // 2. Library & Collections
    List<CollectionEntry>? entries;
    List<AnimePreference>? prefs;
    if (includeLibrary) {
      final collections = await _db.select(_db.collections).get();
      dataMap['collections'] = collections.map((c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'isSystem': c.isSystem,
        'iconName': c.iconName,
        'sortOrder': c.sortOrder,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
      }).toList();

      entries = await _db.select(_db.collectionEntries).get();
      dataMap['collection_entries'] = entries.map((e) => {
        'collectionId': e.collectionId,
        'animeId': e.animeId,
        'userScore': e.userScore,
        'userNotes': e.userNotes,
        'addedAt': e.addedAt.toIso8601String(),
      }).toList();
      for (final e in entries) {
        referencedAnimeIds.add(e.animeId);
      }

      prefs = await _db.select(_db.animePreferences).get();
      dataMap['anime_preferences'] = prefs.map((p) => {
        'animeId': p.animeId,
        'preferredProvider': p.preferredProvider,
        'preferredAudio': p.preferredAudio,
        'preferredServer': p.preferredServer,
        'preferredSubtitleTrack': p.preferredSubtitleTrack,
        'customPlaybackSpeed': p.customPlaybackSpeed,
        'preferredQuality': p.preferredQuality,
      }).toList();
      for (final p in prefs) {
        referencedAnimeIds.add(p.animeId);
      }
    }

    // 3. Progress & History
    if (includeProgress) {
      final history = await _db.select(_db.watchHistory).get();
      dataMap['watch_history'] = history.map((h) => {
        'animeId': h.animeId,
        'episodeNumber': h.episodeNumber,
        'episodeTitle': h.episodeTitle,
        'episodeThumbnail': h.episodeThumbnail,
        'positionMs': h.positionMs,
        'durationMs': h.durationMs,
        'progressPercent': h.progressPercent,
        'isCompleted': h.isCompleted,
        'providerId': h.providerId,
        'audio': h.audio,
        'server': h.server,
        'lastWatchedAt': h.lastWatchedAt.toIso8601String(),
      }).toList();
      for (final h in history) {
        referencedAnimeIds.add(h.animeId);
      }

      final progress = await _db.select(_db.episodeProgress).get();
      dataMap['episode_progress'] = progress.map((p) => {
        'animeId': p.animeId,
        'episodeNumber': p.episodeNumber,
        'positionMs': p.positionMs,
        'durationMs': p.durationMs,
        'progressPercent': p.progressPercent,
        'isCompleted': p.isCompleted,
        'updatedAt': p.updatedAt.toIso8601String(),
      }).toList();
      for (final p in progress) {
        referencedAnimeIds.add(p.animeId);
      }
    }

    // 4. Anime Records: export metadata for all referenced anime to guarantee foreign key integrity
    if (includeLibrary || includeProgress) {
      final allRecords = await _db.select(_db.animeRecords).get();
      final relevantRecords = referencedAnimeIds.isEmpty
          ? allRecords
          : allRecords.where((r) => referencedAnimeIds.contains(r.id)).toList();

      dataMap['anime_records'] = relevantRecords.map((r) => {
        'id': r.id,
        'malId': r.malId,
        'title': r.title,
        'romajiTitle': r.romajiTitle,
        'englishTitle': r.englishTitle,
        'coverUrl': r.coverUrl,
        'bannerUrl': r.bannerUrl,
        'coverColor': r.coverColor,
        'format': r.format,
        'status': r.status,
        'totalEpisodes': r.totalEpisodes,
        'averageScore': r.averageScore,
        'genres': r.genres,
        'updatedAt': r.updatedAt.toIso8601String(),
      }).toList();
    }

    final rootPayload = <String, dynamic>{
      'version': currentBackupVersion,
      'appName': AppConstants.appName,
      'appVersion': AppInfoService.instance.version,
      'createdAt': now.toIso8601String(),
      'data': dataMap,
    };

    final jsonString = json.encode(rootPayload);
    final compressedBytes = gzip.encode(utf8.encode(jsonString));
    return Uint8List.fromList(compressedBytes);
  }

  /// Creates a backup file (.hnm).
  ///
  /// - On Android with a configured SAF folder (Mihon architecture), writes directly
  ///   and silently into the user's folder without any Google Files or system dialogs.
  /// - Automatically records retention timestamp for automatic backups.
  /// - If no SAF folder is configured, saves into the app's dedicated backup directory.
  Future<BackupItem> createBackup({
    bool includeLibrary = true,
    bool includeProgress = true,
    bool includeSettings = true,
    bool isAuto = false,
  }) async {
    final now = DateTime.now().toUtc();
    final compressedBytes = await generateBackupBytes(
      includeLibrary: includeLibrary,
      includeProgress: includeProgress,
      includeSettings: includeSettings,
    );

    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final prefix = isAuto ? 'aniways_auto_backup' : 'aniways_backup';
    final fileName = '${prefix}_$dateStr.$backupExtension';

    // 1. Android SAF tree directory (Mihon architecture) - zero user prompts!
    final treeUri = SharedPreferencesService().backupTreeUri;
    if (Platform.isAndroid && treeUri != null && treeUri.isNotEmpty) {
      final safResult = await SafStorageService.instance.createFile(
        treeUri: treeUri,
        fileName: fileName,
        bytes: compressedBytes,
      );
      if (safResult != null) {
        log.i('Created backup directly via SAF in user folder: $fileName');
        if (isAuto) {
          await SharedPreferencesService()
              .setLastAutoBackupTime(now.toIso8601String());
          await pruneOldAutoBackups();
        }
        return BackupItem(
          name: fileName,
          pathOrUri: safResult['uri'] as String? ?? treeUri,
          isSaf: true,
          sizeBytes: compressedBytes.length,
          lastModified: now.toLocal(),
        );
      }
      log.w('SAF createFile returned null, falling back to app storage');
    }

    // 2. Custom POSIX path (desktop / iOS / accessible POSIX directory)
    final customPath = SharedPreferencesService().backupDirectoryPath;
    if (customPath != null && customPath.trim().isNotEmpty) {
      var dirPath = customPath;
      final lower = dirPath.toLowerCase();
      if (!lower.endsWith('/backups') && !lower.endsWith('/backup')) {
        dirPath = '$dirPath${Platform.pathSeparator}backups';
      }
      final customDir = Directory(dirPath);
      if (!await customDir.exists()) {
        try {
          await customDir.create(recursive: true);
        } catch (_) {}
      }
      if (await isDirectoryWritable(customDir)) {
        try {
          final customFile =
              File('${customDir.path}${Platform.pathSeparator}$fileName');
          await customFile.writeAsBytes(compressedBytes, flush: true);
          log.i('Created backup in custom POSIX dir: ${customFile.path}');
          if (isAuto) {
            await SharedPreferencesService()
                .setLastAutoBackupTime(now.toIso8601String());
            await pruneOldAutoBackups();
          }
          return BackupItem(
            name: fileName,
            pathOrUri: customFile.path,
            isSaf: false,
            sizeBytes: compressedBytes.length,
            lastModified: now.toLocal(),
            file: customFile,
          );
        } catch (_) {}
      }
    }

    // 3. Guaranteed fallback: app dedicated storage directory
    final defaultDir = await getDefaultBackupDirectory();
    final defaultFile =
        File('${defaultDir.path}${Platform.pathSeparator}$fileName');
    await defaultFile.writeAsBytes(compressedBytes, flush: true);

    if (isAuto) {
      await SharedPreferencesService()
          .setLastAutoBackupTime(now.toIso8601String());
      await pruneOldAutoBackups();
    }

    log.i('Created backup in default storage: ${defaultFile.path}');
    return BackupItem(
      name: fileName,
      pathOrUri: defaultFile.path,
      isSaf: false,
      sizeBytes: compressedBytes.length,
      lastModified: now.toLocal(),
      file: defaultFile,
    );
  }

  /// Shares a backup item using the system share sheet.
  Future<void> shareBackupItem(BackupItem item) async {
    try {
      if (item.isSaf && Platform.isAndroid) {
        final bytes = await SafStorageService.instance.readFile(item.pathOrUri);
        if (bytes != null) {
          final tempDir = await getTemporaryDirectory();
          final tempFile =
              File('${tempDir.path}${Platform.pathSeparator}${item.name}');
          await tempFile.writeAsBytes(bytes, flush: true);
          final xFile =
              XFile(tempFile.path, mimeType: 'application/octet-stream');
          await SharePlus.instance.share(
            ShareParams(
              files: [xFile],
              subject: '${AppConstants.appName} Backup (${item.name})',
            ),
          );
          return;
        }
      }

      final path = item.file?.path ?? item.pathOrUri;
      final xFile = XFile(path, mimeType: 'application/octet-stream');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: '${AppConstants.appName} Backup (${item.name})',
        ),
      );
    } catch (e) {
      log.e('Failed to share backup: $e');
    }
  }

  /// Reads and parses a backup item (from SAF or local file), returning summary details for user review.
  Future<BackupSummary> readBackupFromItem(BackupItem item) async {
    Uint8List? bytes;
    if (item.isSaf && Platform.isAndroid) {
      bytes = await SafStorageService.instance.readFile(item.pathOrUri);
    } else if (item.file != null) {
      bytes = await item.file!.readAsBytes();
    } else {
      final f = File(item.pathOrUri);
      if (await f.exists()) {
        bytes = await f.readAsBytes();
      }
    }

    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Could not read backup file content.');
    }

    return _parseBackupBytes(bytes);
  }

  /// Reads and parses a backup file from a filesystem path.
  Future<BackupSummary> readBackupFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FormatException('The selected backup file does not exist.');
    }

    final bytes = await file.readAsBytes();
    return _parseBackupBytes(bytes);
  }

  /// Parses compressed or uncompressed backup bytes into a summary.
  BackupSummary parseBackupBytes(Uint8List bytes) => _parseBackupBytes(bytes);

  BackupSummary _parseBackupBytes(Uint8List bytes) {
    String jsonString;
    try {
      final decompressed = gzip.decode(bytes);
      jsonString = utf8.decode(decompressed);
    } catch (_) {
      // Fallback: uncompressed UTF8 JSON
      jsonString = utf8.decode(bytes);
    }

    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('data')) {
      throw const FormatException('Invalid or unrecognized backup format.');
    }

    final version = (decoded['version'] as num?)?.toInt() ?? 1;
    final appName = decoded['appName']?.toString() ?? AppConstants.appName;
    final appVersion = decoded['appVersion']?.toString() ?? '1.0.0';
    final createdAtStr = decoded['createdAt']?.toString();
    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();

    final data = decoded['data'] as Map<String, dynamic>? ?? {};

    final animeList = data['anime_records'] as List<dynamic>? ?? const [];
    final collectionEntries =
        data['collection_entries'] as List<dynamic>? ?? const [];
    final collections = data['collections'] as List<dynamic>? ?? const [];
    final watchHistory = data['watch_history'] as List<dynamic>? ?? const [];
    final episodeProgress =
        data['episode_progress'] as List<dynamic>? ?? const [];
    final settings = data['settings'] as Map<String, dynamic>? ?? const {};

    return BackupSummary(
      version: version,
      appName: appName,
      appVersion: appVersion,
      createdAt: createdAt,
      animeCount: animeList.length,
      collectionEntriesCount: collectionEntries.length,
      collectionsCount: collections.length,
      watchHistoryCount: watchHistory.length,
      episodeProgressCount: episodeProgress.length,
      settingsCount: settings.length,
      rawData: decoded,
    );
  }

  /// Restores data from the parsed backup map into the database and preferences.
  Future<void> restoreBackup(
    Map<String, dynamic> rawBackup, {
    bool restoreLibrary = true,
    bool restoreProgress = true,
    bool restoreSettings = true,
    bool replaceExisting = false,
    BuildContext? context,
  }) async {
    final data = rawBackup['data'] as Map<String, dynamic>? ?? {};

    await _db.transaction(() async {
      // If replaceExisting mode, clear target tables before restoring
      if (replaceExisting) {
        if (restoreLibrary) {
          await _db.delete(_db.collectionEntries).go();
          await (_db.delete(_db.collections)
                ..where((t) => t.isSystem.equals(false)))
              .go();
        }
        if (restoreProgress) {
          await _db.delete(_db.episodeProgress).go();
          await _db.delete(_db.watchHistory).go();
        }
        if (restoreLibrary && restoreProgress) {
          await _db.delete(_db.animeRecords).go();
        }
      }

      // 1. Anime Records
      final rawAnime = data['anime_records'] as List<dynamic>?;
      if (rawAnime != null && rawAnime.isNotEmpty) {
        final companions = <AnimeRecordsCompanion>[];
        for (final item in rawAnime) {
          if (item is Map<String, dynamic>) {
            final id = (item['id'] as num?)?.toInt();
            final title = item['title']?.toString();
            if (id != null && title != null) {
              companions.add(
                AnimeRecordsCompanion.insert(
                  id: Value(id),
                  malId: Value((item['malId'] as num?)?.toInt()),
                  title: title,
                  romajiTitle: Value(item['romajiTitle']?.toString()),
                  englishTitle: Value(item['englishTitle']?.toString()),
                  coverUrl: Value(item['coverUrl']?.toString()),
                  bannerUrl: Value(item['bannerUrl']?.toString()),
                  coverColor: Value((item['coverColor'] as num?)?.toInt()),
                  format: Value(item['format']?.toString()),
                  status: Value(item['status']?.toString()),
                  totalEpisodes:
                      Value((item['totalEpisodes'] as num?)?.toInt()),
                  averageScore: Value((item['averageScore'] as num?)?.toInt()),
                  genres: Value(item['genres']?.toString() ?? '[]'),
                  updatedAt: Value(
                    DateTime.tryParse(item['updatedAt']?.toString() ?? '') ??
                        DateTime.now(),
                  ),
                ),
              );
            }
          }
        }
        if (companions.isNotEmpty) {
          await _db.batch((b) {
            b.insertAllOnConflictUpdate(_db.animeRecords, companions);
          });
        }
      }

      // 2. Collections & Entries
      if (restoreLibrary) {
        final rawCollections = data['collections'] as List<dynamic>?;
        if (rawCollections != null) {
          final companions = <CollectionsCompanion>[];
          for (final item in rawCollections) {
            if (item is Map<String, dynamic>) {
              final id = item['id']?.toString();
              final name = item['name']?.toString();
              if (id != null && name != null) {
                companions.add(
                  CollectionsCompanion.insert(
                    id: id,
                    name: name,
                    description: Value(item['description']?.toString()),
                    isSystem: Value(item['isSystem'] == true),
                    iconName: Value(item['iconName']?.toString()),
                    sortOrder: Value((item['sortOrder'] as num?)?.toInt() ?? 0),
                    createdAt: Value(
                      DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
                          DateTime.now(),
                    ),
                    updatedAt: Value(
                      DateTime.tryParse(item['updatedAt']?.toString() ?? '') ??
                          DateTime.now(),
                    ),
                  ),
                );
              }
            }
          }
          if (companions.isNotEmpty) {
            await _db.batch((b) {
              b.insertAllOnConflictUpdate(_db.collections, companions);
            });
          }
        }

        final rawEntries = data['collection_entries'] as List<dynamic>?;
        if (rawEntries != null) {
          final companions = <CollectionEntriesCompanion>[];
          for (final item in rawEntries) {
            if (item is Map<String, dynamic>) {
              final colId = item['collectionId']?.toString();
              final animeId = (item['animeId'] as num?)?.toInt();
              if (colId != null && animeId != null) {
                companions.add(
                  CollectionEntriesCompanion.insert(
                    collectionId: colId,
                    animeId: animeId,
                    userScore: Value((item['userScore'] as num?)?.toDouble()),
                    userNotes: Value(item['userNotes']?.toString()),
                    addedAt: Value(
                      DateTime.tryParse(item['addedAt']?.toString() ?? '') ??
                          DateTime.now(),
                    ),
                  ),
                );
              }
            }
          }
          if (companions.isNotEmpty) {
            await _db.batch((b) {
              b.insertAllOnConflictUpdate(_db.collectionEntries, companions);
            });
          }
        }

        final rawPrefs = data['anime_preferences'] as List<dynamic>?;
        if (rawPrefs != null) {
          final companions = <AnimePreferencesCompanion>[];
          for (final item in rawPrefs) {
            if (item is Map<String, dynamic>) {
              final animeId = (item['animeId'] as num?)?.toInt();
              if (animeId != null) {
                companions.add(
                  AnimePreferencesCompanion.insert(
                    animeId: Value(animeId),
                    preferredProvider:
                        Value(item['preferredProvider']?.toString()),
                    preferredAudio: Value(item['preferredAudio']?.toString()),
                    preferredServer: Value(item['preferredServer']?.toString()),
                    preferredSubtitleTrack:
                        Value(item['preferredSubtitleTrack']?.toString()),
                    customPlaybackSpeed: Value(
                      (item['customPlaybackSpeed'] as num?)?.toDouble(),
                    ),
                    preferredQuality:
                        Value(item['preferredQuality']?.toString()),
                  ),
                );
              }
            }
          }
          if (companions.isNotEmpty) {
            await _db.batch((b) {
              b.insertAllOnConflictUpdate(_db.animePreferences, companions);
            });
          }
        }
      }

      // 3. Progress & Watch History
      if (restoreProgress) {
        final rawHistory = data['watch_history'] as List<dynamic>?;
        if (rawHistory != null) {
          final companions = <WatchHistoryCompanion>[];
          for (final item in rawHistory) {
            if (item is Map<String, dynamic>) {
              final animeId = (item['animeId'] as num?)?.toInt();
              final epNum = (item['episodeNumber'] as num?)?.toInt();
              if (animeId != null && epNum != null) {
                companions.add(
                  WatchHistoryCompanion.insert(
                    animeId: Value(animeId),
                    episodeNumber: epNum,
                    episodeTitle: Value(item['episodeTitle']?.toString()),
                    episodeThumbnail:
                        Value(item['episodeThumbnail']?.toString()),
                    positionMs: Value(
                      (item['positionMs'] as num?)?.toInt() ?? 0,
                    ),
                    durationMs: Value(
                      (item['durationMs'] as num?)?.toInt() ?? 0,
                    ),
                    progressPercent: Value(
                      (item['progressPercent'] as num?)?.toDouble() ?? 0.0,
                    ),
                    isCompleted: Value(item['isCompleted'] == true),
                    providerId: Value(item['providerId']?.toString()),
                    audio: Value(item['audio']?.toString() ?? 'sub'),
                    server: Value(item['server']?.toString()),
                    lastWatchedAt: Value(
                      DateTime.tryParse(
                            item['lastWatchedAt']?.toString() ?? '',
                          ) ??
                          DateTime.now(),
                    ),
                  ),
                );
              }
            }
          }
          if (companions.isNotEmpty) {
            await _db.batch((b) {
              b.insertAllOnConflictUpdate(_db.watchHistory, companions);
            });
          }
        }

        final rawProgress = data['episode_progress'] as List<dynamic>?;
        if (rawProgress != null) {
          final companions = <EpisodeProgressCompanion>[];
          for (final item in rawProgress) {
            if (item is Map<String, dynamic>) {
              final animeId = (item['animeId'] as num?)?.toInt();
              final epNum = (item['episodeNumber'] as num?)?.toInt();
              if (animeId != null && epNum != null) {
                companions.add(
                  EpisodeProgressCompanion.insert(
                    animeId: animeId,
                    episodeNumber: epNum,
                    positionMs: Value(
                      (item['positionMs'] as num?)?.toInt() ?? 0,
                    ),
                    durationMs: Value(
                      (item['durationMs'] as num?)?.toInt() ?? 0,
                    ),
                    progressPercent: Value(
                      (item['progressPercent'] as num?)?.toDouble() ?? 0.0,
                    ),
                    isCompleted: Value(item['isCompleted'] == true),
                    updatedAt: Value(
                      DateTime.tryParse(
                            item['updatedAt']?.toString() ?? '',
                          ) ??
                          DateTime.now(),
                    ),
                  ),
                );
              }
            }
          }
          if (companions.isNotEmpty) {
            await _db.batch((b) {
              b.insertAllOnConflictUpdate(_db.episodeProgress, companions);
            });
          }
        }
      }
    });

    // 4. Restore Settings
    if (restoreSettings && data.containsKey('settings')) {
      final settings = data['settings'];
      if (settings is Map<String, dynamic>) {
        await SharedPreferencesService().importSettings(settings);
      }
    }

    // 5. Hot Reload Active UI Providers
    if (context != null && context.mounted) {
      try {
        context.read<ThemeProvider>().reload();
      } catch (_) {}
    }

    log.i('Backup restore completed successfully');
  }
}
