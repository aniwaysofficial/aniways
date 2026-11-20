import 'dart:io' as io;

import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aniways/core/logger.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';

/// Service for inspecting, sizing, clearing, and enforcing storage limits
/// on cached network images.
class ImageCacheService {
  ImageCacheService._internal();
  static final ImageCacheService instance = ImageCacheService._internal();
  factory ImageCacheService() => instance;

  /// Cache key used for anime posters, cards, banners, and thumbnails.
  static const String animeCacheKey = 'animeImages';

  /// Default cache key used by DefaultCacheManager.
  static const String defaultCacheKey = DefaultCacheManager.key; // 'libCachedImageData'

  /// Dedicated high-capacity image cache manager for anime posters and media.
  /// Uses [ImageCacheManager] mixin to natively support image resizing (maxWidth / memCacheWidth).
  static final AnimeImageCacheManager animeImageCache = AnimeImageCacheManager();

  final DefaultCacheManager _defaultCache = DefaultCacheManager();

  /// Returns all disk directories where cached images reside.
  Future<List<io.Directory>> getCacheDirectories() async {
    final tempDir = await getTemporaryDirectory();
    final dirs = <io.Directory>[
      io.Directory('${tempDir.path}${io.Platform.pathSeparator}$animeCacheKey'),
      io.Directory('${tempDir.path}${io.Platform.pathSeparator}$defaultCacheKey'),
    ];

    try {
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(followLinks: false)) {
          if (entity is io.Directory) {
            final name = entity.path.split(io.Platform.pathSeparator).last;
            final isKnown = dirs.any((d) => d.path == entity.path);
            if (!isKnown) {
              final lower = name.toLowerCase();
              if (lower.contains('cache') || lower.contains('image')) {
                dirs.add(entity);
              }
            }
          }
        }
      }
    } catch (e) {
      log.w('Error discovering cache directories: $e');
    }

    try {
      final supportDir = await getApplicationSupportDirectory();
      final blurredDir = io.Directory('${supportDir.path}${io.Platform.pathSeparator}blurred_covers');
      if (await blurredDir.exists()) {
        dirs.add(blurredDir);
      }
    } catch (_) {}

    return dirs;
  }

  /// Calculates total size of all cached images on disk in bytes.
  Future<int> getCacheSizeBytes() async {
    try {
      final dirs = await getCacheDirectories();
      int totalBytes = 0;
      final visitedFiles = <String>{};

      for (final dir in dirs) {
        if (!await dir.exists()) continue;

        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is io.File) {
            if (visitedFiles.add(entity.path)) {
              try {
                totalBytes += await entity.length();
              } catch (_) {}
            }
          }
        }
      }
      return totalBytes;
    } catch (e) {
      log.w('Failed to calculate image cache size: $e');
      return 0;
    }
  }

  /// Formats byte count into a human-readable string (e.g. "42.5 MB").
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
  }

  /// Empties the entire image disk cache and flushes memory image cache.
  Future<void> clearCache() async {
    try {
      // 1. Clear flutter_cache_manager cache stores (clears database records & cached files)
      await Future.wait([
        animeImageCache.emptyCache().catchError((e) {
          log.w('Failed to empty anime cache manager: $e');
        }),
        _defaultCache.emptyCache().catchError((e) {
          log.w('Failed to empty default cache manager: $e');
        }),
      ]);

      // 2. Clear physical files in all cache directories to catch any unindexed or orphaned files
      final dirs = await getCacheDirectories();
      for (final dir in dirs) {
        if (await dir.exists()) {
          try {
            await for (final entity in dir.list(recursive: true, followLinks: false)) {
              try {
                if (entity is io.File) {
                  await entity.delete();
                } else if (entity is io.Directory) {
                  await entity.delete(recursive: true);
                }
              } catch (_) {}
            }
          } catch (_) {}
        }
      }

      // 3. Flush Flutter's in-memory decoded image caches
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      log.i('Image cache cleared successfully');
    } catch (e) {
      log.e('Failed to clear image cache: $e');
      rethrow;
    }
  }

  /// Checks current cache size against user's configured limit and purges
  /// oldest files (LRU) if the limit is exceeded.
  Future<void> enforceCacheLimit() async {
    try {
      final maxMb = SharedPreferencesService().maxImageCacheMb;
      final maxBytes = maxMb * 1024 * 1024;
      final dirs = await getCacheDirectories();

      final files = <io.File>[];
      int totalBytes = 0;
      final visitedFiles = <String>{};

      for (final dir in dirs) {
        if (!await dir.exists()) continue;

        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is io.File) {
            if (visitedFiles.add(entity.path)) {
              try {
                final len = await entity.length();
                totalBytes += len;
                files.add(entity);
              } catch (_) {}
            }
          }
        }
      }

      if (totalBytes <= maxBytes) return;

      // Sort files oldest first (LRU based on last modified date)
      files.sort((a, b) {
        try {
          return a.lastModifiedSync().compareTo(b.lastModifiedSync());
        } catch (_) {
          return 0;
        }
      });

      // Target removing down to 80% of max limit to avoid frequent thrashing
      final targetBytes = (maxBytes * 0.80).toInt();
      for (final file in files) {
        if (totalBytes <= targetBytes) break;
        try {
          final len = await file.length();
          await file.delete();
          totalBytes -= len;
        } catch (_) {}
      }

      log.i(
        'Image cache trimmed to fit $maxMb MB limit (now ${formatBytes(totalBytes)})',
      );
    } catch (e) {
      log.w('Failed to enforce image cache limit: $e');
    }
  }
}

/// Custom cache manager with the [ImageCacheManager] mixin to natively handle
/// resizing (memCacheWidth / maxWidth / maxHeight) for anime posters and media.
class AnimeImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = ImageCacheService.animeCacheKey;

  static final AnimeImageCacheManager _instance = AnimeImageCacheManager._();

  factory AnimeImageCacheManager() => _instance;

  AnimeImageCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 1000,
          ),
        );
}
