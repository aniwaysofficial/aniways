import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:aniways/core/logger.dart';

/// Manages filesystem storage for downloaded JavaScript extension bundles.
class ExtensionFileStorage {
  ExtensionFileStorage({Directory? baseDir}) : _customBaseDir = baseDir;

  final Directory? _customBaseDir;
  Directory? _resolvedDir;

  Future<Directory> _getExtensionsDirectory() async {
    final custom = _customBaseDir;
    if (custom != null) return custom;
    final resolved = _resolvedDir;
    if (resolved != null) return resolved;

    final appDocs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDocs.path, 'extensions'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _resolvedDir = dir;
    return dir;
  }

  /// Writes the JavaScript script content for [extensionId].
  /// Returns the absolute path of the written file.
  Future<String> saveScript(String extensionId, String scriptContent) async {
    final dir = await _getExtensionsDirectory();
    final file = File(p.join(dir.path, '$extensionId.js'));
    await file.writeAsString(scriptContent, flush: true);
    log.d('ExtensionFileStorage: saved $extensionId to ${file.path}');
    return file.path;
  }

  /// Reads the script content for [extensionId] from local storage.
  /// Returns null if the file does not exist.
  Future<String?> readScript(String extensionId) async {
    final dir = await _getExtensionsDirectory();
    final file = File(p.join(dir.path, '$extensionId.js'));
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }

  /// Deletes the local script file for [extensionId].
  Future<bool> deleteScript(String extensionId) async {
    try {
      final dir = await _getExtensionsDirectory();
      final file = File(p.join(dir.path, '$extensionId.js'));
      if (await file.exists()) {
        await file.delete();
        log.d('ExtensionFileStorage: deleted ${file.path}');
        return true;
      }
    } catch (e) {
      log.w('ExtensionFileStorage: failed to delete $extensionId: $e');
    }
    return false;
  }
}
