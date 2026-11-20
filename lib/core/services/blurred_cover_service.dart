import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:aniways/core/services/image_cache_service.dart';

/// Top-level isolate function for processing a cover image with a Gaussian blur.
/// Runs in a background isolate so the main UI thread experiences zero frame drops.
Uint8List _blurImageIsolate(Uint8List rawBytes) {
  try {
    final image = img.decodeImage(rawBytes);
    if (image == null) return Uint8List(0);

    // Downscale to a clean card aspect ratio (width ~260) to keep memory small (~10KB)
    // and blur computation fast (< 20ms).
    final targetWidth = 260;
    final targetHeight = (image.height * (targetWidth / image.width)).round();
    final resized = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    // Authentic Gaussian blur with a rich, soft radius
    final blurred = img.gaussianBlur(resized, radius: 12);

    // Encode as high-quality compressed JPEG (quality: 85)
    return Uint8List.fromList(img.encodeJpg(blurred, quality: 85));
  } catch (e) {
    debugPrint('BlurredCoverService isolate error: $e');
    return Uint8List(0);
  }
}

/// Service that generates and caches authentic high-resolution blurred cover
/// images to disk on background isolates, completely eliminating runtime GPU
/// blur passes and offscreen buffer allocations.
class BlurredCoverService {
  BlurredCoverService._();
  static final BlurredCoverService instance = BlurredCoverService._();

  Directory? _cacheDir;
  final Map<String, File> _diskCache = {};
  final Map<String, Future<File?>> _pendingTasks = {};

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'blurred_covers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _keyForUrl(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  /// Synchronously returns the blurred File if it was already resolved or exists on disk.
  File? getCachedSync(String url) {
    if (url.isEmpty) return null;
    final cached = _diskCache[url];
    if (cached != null) return cached;

    final dir = _cacheDir;
    if (dir != null) {
      final key = _keyForUrl(url);
      final file = File(p.join(dir.path, '$key.jpg'));
      if (file.existsSync()) {
        _diskCache[url] = file;
        return file;
      }
    }
    return null;
  }

  /// Ensures a blurred version of the cover image at [url] exists on disk.
  /// If already on disk, returns the File immediately.
  /// Otherwise, downloads the bytes, blurs them in a background isolate,
  /// writes the file to disk, and returns it.
  Future<File?> getOrBlur(String url) async {
    if (url.isEmpty) return null;

    final syncFile = getCachedSync(url);
    if (syncFile != null) return syncFile;

    if (_pendingTasks.containsKey(url)) {
      return _pendingTasks[url];
    }

    final future = _processUrl(url);
    _pendingTasks[url] = future;
    try {
      final result = await future;
      return result;
    } finally {
      _pendingTasks.remove(url);
    }
  }

  Future<File?> _processUrl(String url) async {
    try {
      final dir = await _getCacheDir();
      final key = _keyForUrl(url);
      final file = File(p.join(dir.path, '$key.jpg'));

      if (await file.exists()) {
        _diskCache[url] = file;
        return file;
      }

      // Retrieve source image bytes from animeImageCache
      Uint8List? rawBytes;
      final cacheManager = ImageCacheService.animeImageCache;
      final fileInfo = await cacheManager.getFileFromCache(url);
      if (fileInfo != null && await fileInfo.file.exists()) {
        rawBytes = await fileInfo.file.readAsBytes();
      } else {
        final downloaded = await cacheManager.downloadFile(url);
        if (await downloaded.file.exists()) {
          rawBytes = await downloaded.file.readAsBytes();
        }
      }

      if (rawBytes == null || rawBytes.isEmpty) return null;

      // Blur in background isolate
      final blurredBytes = await compute(_blurImageIsolate, rawBytes);
      if (blurredBytes.isEmpty) return null;

      // Write atomically via temporary file
      final tempFile = File(p.join(dir.path, '$key.tmp'));
      await tempFile.writeAsBytes(blurredBytes, flush: true);
      if (await file.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      } else {
        await tempFile.rename(file.path);
      }

      _diskCache[url] = file;
      return file;
    } catch (e) {
      debugPrint('BlurredCoverService error for $url: $e');
      return null;
    }
  }

  /// Clears all blurred covers from memory and disk.
  Future<void> clearDiskCache() async {
    _diskCache.clear();
    try {
      final dir = await _getCacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('BlurredCoverService clear error: $e');
    }
  }
}

/// A card background widget that displays an authentic pre-blurred image from disk.
/// If the blurred image is not yet generated, it shows [fallback] while computing
/// the blur completely in the background.
class BlurredCardCover extends StatefulWidget {
  const BlurredCardCover({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String? url;
  final BoxFit fit;
  final Widget? fallback;

  @override
  State<BlurredCardCover> createState() => _BlurredCardCoverState();
}

class _BlurredCardCoverState extends State<BlurredCardCover> {
  File? _file;
  String? _loadedUrl;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoad(isInitial: true);
  }

  @override
  void didUpdateWidget(BlurredCardCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _checkAndLoad(isInitial: false);
    }
  }

  void _checkAndLoad({required bool isInitial}) {
    final url = widget.url;
    if (url == null || url.isEmpty) {
      _file = null;
      _loadedUrl = null;
      _animate = false;
      return;
    }
    _loadedUrl = url;

    // Fast synchronous check if already cached on disk
    final syncFile = BlurredCoverService.instance.getCachedSync(url);
    if (syncFile != null) {
      _file = syncFile;
      _animate = false;
      return;
    }

    // Otherwise compute/load asynchronously and fade in smoothly
    _file = null;
    _animate = true;
    BlurredCoverService.instance.getOrBlur(url).then((file) {
      if (mounted && _loadedUrl == url && file != null) {
        setState(() {
          _file = file;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fallbackWidget = widget.fallback ?? const SizedBox.shrink();

    if (_file == null) {
      return fallbackWidget;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        fallbackWidget,
        Image.file(
          _file!,
          fit: widget.fit,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || !_animate) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: child,
            );
          },
          errorBuilder: (_, _, _) => fallbackWidget,
        ),
      ],
    );
  }
}
