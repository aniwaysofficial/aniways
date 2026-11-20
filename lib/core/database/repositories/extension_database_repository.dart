import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/core/extensions/models/extension_manifest.dart';
import 'package:aniways/core/network/extractor_service.dart';

/// Database repository for managing installed extensions and remote repositories in Drift.
class ExtensionDatabaseRepository {
  ExtensionDatabaseRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  // ═════════════════════════════════════════════════════════════════════════
  // Installed Extensions
  // ═════════════════════════════════════════════════════════════════════════

  /// Stream of all installed extensions ordered by [priorityIndex].
  Stream<List<ExtensionManifest>> watchInstalledExtensions() {
    final query = _db.select(_db.installedExtensions)
      ..orderBy([(t) => OrderingTerm.asc(t.priorityIndex)]);

    return query.watch().map((rows) => rows.map(_rowToManifest).toList());
  }

  /// List of all installed extensions ordered by [priorityIndex].
  Future<List<ExtensionManifest>> getInstalledExtensions() async {
    final query = _db.select(_db.installedExtensions)
      ..orderBy([(t) => OrderingTerm.asc(t.priorityIndex)]);

    final rows = await query.get();
    return rows.map(_rowToManifest).toList();
  }

  /// List of enabled extensions ordered by [priorityIndex].
  Future<List<ExtensionManifest>> getEnabledExtensions() async {
    final query = _db.select(_db.installedExtensions)
      ..where((t) => t.isEnabled.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.priorityIndex)]);

    final rows = await query.get();
    return rows.map(_rowToManifest).toList();
  }

  /// Inserts or updates an extension record.
  Future<void> upsertExtension(ExtensionManifest manifest, String localScriptPath) async {
    final companion = InstalledExtensionsCompanion(
      id: Value(manifest.id),
      name: Value(manifest.name),
      version: Value(manifest.version),
      versionCode: Value(manifest.versionCode),
      author: Value(manifest.author),
      iconUrl: Value(manifest.iconUrl),
      description: Value(manifest.description),
      audio: Value(jsonEncode(manifest.audio.map((a) => a.name).toList())),
      lang: Value(manifest.lang),
      baseUrl: Value(manifest.baseUrl),
      isEnabled: Value(manifest.isEnabled),
      priorityIndex: Value(manifest.priorityIndex),
      localScriptPath: Value(localScriptPath),
      repoUrl: Value(manifest.repoUrl),
      installedAt: Value(manifest.installedAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    await _db.into(_db.installedExtensions).insertOnConflictUpdate(companion);
  }

  /// Toggles whether an extension is enabled.
  Future<void> setExtensionEnabled(String id, bool isEnabled) async {
    await (_db.update(_db.installedExtensions)..where((t) => t.id.equals(id))).write(
      InstalledExtensionsCompanion(isEnabled: Value(isEnabled)),
    );
  }

  /// Updates the priority order of extensions (drag & drop reordering).
  Future<void> updatePriorityOrder(List<String> extensionIds) async {
    await _db.transaction(() async {
      for (int i = 0; i < extensionIds.length; i++) {
        await (_db.update(_db.installedExtensions)
              ..where((t) => t.id.equals(extensionIds[i])))
            .write(InstalledExtensionsCompanion(priorityIndex: Value(i)));
      }
    });
  }

  /// Removes an extension from the database.
  Future<void> deleteExtension(String id) async {
    await (_db.delete(_db.installedExtensions)..where((t) => t.id.equals(id))).go();
  }

  /// Updates icon URL for an installed extension.
  Future<void> updateExtensionIcon(String id, String iconUrl) async {
    final query = _db.update(_db.installedExtensions)
      ..where((t) => t.id.equals(id));
    await query.write(InstalledExtensionsCompanion(iconUrl: Value(iconUrl)));
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Extension Repositories
  // ═════════════════════════════════════════════════════════════════════════

  /// Stream of configured repositories.
  Stream<List<ExtensionRepository>> watchRepositories() {
    return _db.select(_db.extensionRepositories).watch();
  }

  /// List of configured repositories.
  Future<List<ExtensionRepository>> getRepositories() async {
    return _db.select(_db.extensionRepositories).get();
  }

  /// Adds a new repository URL.
  Future<void> addRepository({
    required String id,
    required String name,
    required String url,
  }) async {
    await _db.into(_db.extensionRepositories).insertOnConflictUpdate(
          ExtensionRepositoriesCompanion.insert(
            id: id,
            name: name,
            url: url,
            isEnabled: const Value(true),
          ),
        );
  }

  /// Updates last sync timestamp for a repository.
  Future<void> updateRepositorySync(String id, DateTime lastSynced) async {
    await (_db.update(_db.extensionRepositories)..where((t) => t.id.equals(id))).write(
      ExtensionRepositoriesCompanion(lastSyncedAt: Value(lastSynced)),
    );
  }

  /// Toggles whether a repository is enabled.
  Future<void> setRepositoryEnabled(String id, bool isEnabled) async {
    await (_db.update(_db.extensionRepositories)..where((t) => t.id.equals(id))).write(
      ExtensionRepositoriesCompanion(isEnabled: Value(isEnabled)),
    );
  }

  /// Updates repository name and url.
  Future<void> updateRepository({
    required String id,
    required String name,
    required String url,
  }) async {
    await (_db.update(_db.extensionRepositories)..where((t) => t.id.equals(id))).write(
      ExtensionRepositoriesCompanion(
        name: Value(name),
        url: Value(url),
      ),
    );
  }

  /// Deletes a repository by ID.
  Future<void> deleteRepository(String id) async {
    await (_db.delete(_db.extensionRepositories)..where((t) => t.id.equals(id))).go();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helper
  // ═════════════════════════════════════════════════════════════════════════

  static ExtensionManifest _rowToManifest(InstalledExtension row) {
    final audioList = <StreamAudio>[];
    try {
      final decoded = jsonDecode(row.audio);
      if (decoded is List) {
        for (final item in decoded) {
          audioList.add(
            item.toString().toLowerCase() == 'dub'
                ? StreamAudio.dub
                : StreamAudio.sub,
          );
        }
      }
    } catch (_) {
      audioList.add(StreamAudio.sub);
    }

    if (audioList.isEmpty) audioList.add(StreamAudio.sub);

    return ExtensionManifest(
      id: row.id,
      name: row.name,
      version: row.version,
      versionCode: row.versionCode,
      author: row.author,
      iconUrl: row.iconUrl,
      description: row.description,
      audio: audioList,
      lang: row.lang,
      baseUrl: row.baseUrl,
      isEnabled: row.isEnabled,
      priorityIndex: row.priorityIndex,
      localScriptPath: row.localScriptPath,
      repoUrl: row.repoUrl,
      installedAt: row.installedAt,
      updatedAt: row.updatedAt,
    );
  }
}
