import 'dart:io';
import 'package:flutter/services.dart';
import 'package:aniways/core/logger.dart';

/// Represents a backup file entry located within a Storage Access Framework (SAF) tree directory.
class SafBackupFile {
  const SafBackupFile({
    required this.uri,
    required this.name,
    required this.size,
    required this.lastModified,
  });

  final String uri;
  final String name;
  final int size;
  final DateTime lastModified;
}

/// Service providing direct Storage Access Framework (SAF) tree directory operations
/// matching the Mihon/Tachiyomi architecture on Android.
///
/// Once a folder is picked by the user, persisted URI permissions allow the app to
/// silently read, write, list, and delete files inside that folder without ever prompting
/// the user with system file dialogs again.
class SafStorageService {
  SafStorageService._internal();
  static final SafStorageService instance = SafStorageService._internal();
  factory SafStorageService() => instance;

  static const MethodChannel _channel =
      MethodChannel('com.aniways.app/saf');

  bool get isSupported => Platform.isAndroid;

  /// Launches Android's ACTION_OPEN_DOCUMENT_TREE.
  /// Persists read/write permissions for the chosen folder.
  /// Returns a map with `treeUri` and `displayPath`, or `null` if the user canceled.
  Future<Map<String, String>?> pickDirectory() async {
    if (!isSupported) return null;
    try {
      final res =
          await _channel.invokeMapMethod<String, String>('pickDirectory');
      return res;
    } on PlatformException catch (e) {
      log.w('SAF pickDirectory failed: ${e.message}');
      return null;
    }
  }

  /// Creates and writes a file directly inside the tree URI directory via DocumentFile.
  /// Completely silent, zero prompts, no Google Files picker.
  Future<Map<String, dynamic>?> createFile({
    required String treeUri,
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    if (!isSupported) return null;
    try {
      final res =
          await _channel.invokeMapMethod<String, dynamic>('createFile', {
        'treeUri': treeUri,
        'fileName': fileName,
        'bytes': bytes,
        'mimeType': mimeType,
      });
      return res;
    } on PlatformException catch (e) {
      log.w('SAF createFile failed: ${e.message}');
      return null;
    }
  }

  /// Lists all matching files directly from the tree URI directory via DocumentFile.
  Future<List<SafBackupFile>> listFiles({
    required String treeUri,
    String? extension,
  }) async {
    if (!isSupported) return [];
    try {
      final list = await _channel
          .invokeListMethod<Map<dynamic, dynamic>>('listFiles', {
        'treeUri': treeUri,
        'extension': extension,
      });
      if (list == null) return [];
      return list.map((item) {
        return SafBackupFile(
          uri: item['uri'] as String? ?? '',
          name: item['name'] as String? ?? '',
          size: (item['size'] as num?)?.toInt() ?? 0,
          lastModified: DateTime.fromMillisecondsSinceEpoch(
            (item['lastModified'] as num?)?.toInt() ?? 0,
          ),
        );
      }).toList();
    } on PlatformException catch (e) {
      log.w('SAF listFiles failed: ${e.message}');
      return [];
    }
  }

  /// Reads bytes of a file by its SAF content URI via ContentResolver.
  Future<Uint8List?> readFile(String uri) async {
    if (!isSupported) return null;
    try {
      final bytes =
          await _channel.invokeMethod<Uint8List>('readFile', {'uri': uri});
      return bytes;
    } on PlatformException catch (e) {
      log.w('SAF readFile failed: ${e.message}');
      return null;
    }
  }

  /// Deletes a file by its SAF content URI via DocumentFile.
  Future<bool> deleteFile(String uri) async {
    if (!isSupported) return false;
    try {
      final deleted =
          await _channel.invokeMethod<bool>('deleteFile', {'uri': uri});
      return deleted ?? false;
    } on PlatformException catch (e) {
      log.w('SAF deleteFile failed: ${e.message}');
      return false;
    }
  }
}

