import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aniways/core/constants.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/services/app_info_service.dart';

import 'update_models.dart';

/// Service responsible for querying GitHub Releases, comparing versions,
/// and streaming APK downloads to local cache storage.
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const String _prefLastCheckTime = 'app_update_last_check_ms';
  static const String _prefLastNotifiedVersion = 'app_update_last_notified_version';
  static const Duration autoCheckCooldown = Duration(hours: 12);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Aniways-App',
      },
    ),
  );

  AppRelease? _cachedRelease;
  AppRelease? get cachedRelease => _cachedRelease;

  /// Checks if the 12-hour cooldown period has elapsed since the last automatic check.
  /// Always returns false in debug mode so auto-update checks never run during development.
  Future<bool> shouldAutoCheck() async {
    if (kDebugMode) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_prefLastCheckTime);
      if (lastMs == null) return true;
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
      return DateTime.now().difference(lastDate) >= autoCheckCooldown;
    } catch (_) {
      return true;
    }
  }

  /// Records the current timestamp as the last update check time.
  Future<void> recordCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefLastCheckTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      log.w('Could not record last update check time: $e');
    }
  }

  /// Checks if a notification has already been shown for this specific version tag.
  Future<bool> hasNotifiedForVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefLastNotifiedVersion) == version;
    } catch (_) {
      return false;
    }
  }

  /// Records that a notification was fired for this version tag.
  Future<void> recordNotifiedVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastNotifiedVersion, version);
    } catch (e) {
      log.w('Could not record notified version: $e');
    }
  }

  /// Queries GitHub's latest release API and checks if a newer version is available.
  Future<UpdateCheckResult> checkForUpdate({bool isManual = false}) async {
    try {
      final url = 'https://api.github.com/repos/${AppConstants.githubRepo}/releases/latest';
      final response = await _dio.get<Map<String, dynamic>>(url);

      if (response.statusCode != 200 || response.data == null) {
        return const UpdateCheckResult(
          hasUpdate: false,
          errorMessage: 'Failed to retrieve release information.',
        );
      }

      final release = AppRelease.fromJson(response.data!);
      _cachedRelease = release;
      await recordCheckTime();

      final currentVersion = AppInfoService.instance.version;
      final isNewer = release.isNewerThan(currentVersion);

      return UpdateCheckResult(
        hasUpdate: isNewer,
        release: release,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const UpdateCheckResult(
          hasUpdate: false,
          errorMessage: 'No published releases found on repository.',
        );
      }
      if (e.response?.statusCode == 403) {
        return const UpdateCheckResult(
          hasUpdate: false,
          errorMessage: 'GitHub API rate limit exceeded. Please try again later.',
        );
      }
      return UpdateCheckResult(
        hasUpdate: false,
        errorMessage: 'Network error checking for updates: ${e.message}',
      );
    } catch (e) {
      log.e('Unexpected error during update check: $e');
      return UpdateCheckResult(
        hasUpdate: false,
        errorMessage: 'Unable to check for updates: $e',
      );
    }
  }

  /// Returns the target updates directory in the app's local cache.
  Future<Directory> getUpdatesDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final updateDir = Directory('${tempDir.path}${Platform.pathSeparator}updates');
    if (!await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }
    return updateDir;
  }

  /// Cleans up any previously downloaded APKs in the updates directory.
  Future<void> cleanOldUpdates() async {
    try {
      final dir = await getUpdatesDirectory();
      if (await dir.exists()) {
        final files = dir.listSync();
        for (final file in files) {
          if (file is File) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      log.w('Could not clean old update cache: $e');
    }
  }

  /// Streams the download of the specified [asset] into the temporary cache directory.
  Future<File?> downloadUpdate({
    required ReleaseAsset asset,
    required void Function(DownloadProgress progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await cleanOldUpdates();
      final dir = await getUpdatesDirectory();
      final filePath = '${dir.path}${Platform.pathSeparator}${asset.name}';
      final file = File(filePath);

      await _dio.download(
        asset.downloadUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          onProgress(
            DownloadProgress(
              receivedBytes: received,
              totalBytes: total,
            ),
          );
        },
      );

      if (await file.exists()) {
        return file;
      }
      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        log.d('Update download canceled by user.');
        await cleanOldUpdates();
        return null;
      }
      log.e('Download failed: ${e.message}');
      rethrow;
    } catch (e) {
      log.e('Unexpected error during update download: $e');
      rethrow;
    }
  }
}

