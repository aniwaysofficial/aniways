import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:aniways/core/constants.dart';
import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/extensions/models/extension_manifest.dart';
import 'package:aniways/core/logger.dart';

/// Item in the online extension catalog with installation/update status.
class CatalogExtensionItem {
  const CatalogExtensionItem({
    required this.manifest,
    required this.pkgUrl,
    required this.repoId,
    required this.repoName,
    this.isInstalled = false,
    this.hasUpdate = false,
    this.installedVersion,
  });

  final ExtensionManifest manifest;
  final String pkgUrl;
  final String repoId;
  final String repoName;
  final bool isInstalled;
  final bool hasUpdate;
  final String? installedVersion;
}

/// Service to fetch and sync remote extension repository catalogs (`index.json`).
class RepoSyncService {
  RepoSyncService({Dio? dio}) : _dio = dio ?? Dio(
          BaseOptions(
            connectTimeout: AppConstants.networkTimeout,
            receiveTimeout: AppConstants.networkTimeout,
            sendTimeout: AppConstants.networkTimeout,
          ),
        );

  final Dio _dio;

  /// Fetches an extension catalog from [repoUrl] and cross-references against [installed].
  Future<List<CatalogExtensionItem>> fetchCatalog({
    required String repoId,
    required String repoName,
    required String repoUrl,
    required List<ExtensionManifest> installed,
  }) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final separator = repoUrl.contains('?') ? '&' : '?';
      final requestUrl = '$repoUrl${separator}_t=$cacheBuster';

      final res = await _dio.get<dynamic>(
        requestUrl,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );
      dynamic data = res.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (e) {
          log.w('RepoSyncService: Failed to parse JSON string from $repoUrl: $e');
        }
      }

      final rawList = data is List
          ? data
          : (data is Map && data['extensions'] is List ? data['extensions'] as List : []);

      final installedMap = {for (final ext in installed) ext.id: ext};
      final result = <CatalogExtensionItem>[];

      for (final item in rawList) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();

        final lastSlash = repoUrl.lastIndexOf('/');
        final base = lastSlash != -1 ? repoUrl.substring(0, lastSlash + 1) : repoUrl;

        String pkgUrl = (map['pkgUrl'] as String?) ?? (map['file'] as String?) ?? '';
        if (pkgUrl.isNotEmpty && !pkgUrl.startsWith('http')) {
          pkgUrl = '$base$pkgUrl';
        }

        String? rawIcon = (map['icon'] as String?) ?? (map['iconUrl'] as String?);
        String? resolvedIcon;
        if (rawIcon != null && rawIcon.isNotEmpty) {
          resolvedIcon = rawIcon.startsWith('http') ? rawIcon : '$base$rawIcon';
        }

        final manifest = ExtensionManifest.fromJson({
          ...map,
          'iconUrl': resolvedIcon,
          'repoUrl': repoUrl,
        });

        final local = installedMap[manifest.id];
        final isInstalled = local != null;
        final hasUpdate = local != null && manifest.versionCode > local.versionCode;

        if (local != null && resolvedIcon != null && local.iconUrl != resolvedIcon) {
          extensionManager.dbRepository.updateExtensionIcon(manifest.id, resolvedIcon);
        }

        result.add(CatalogExtensionItem(
          manifest: manifest,
          pkgUrl: pkgUrl,
          repoId: repoId,
          repoName: repoName,
          isInstalled: isInstalled,
          hasUpdate: hasUpdate,
          installedVersion: local?.version,
        ));
      }

      return result;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        log.w('RepoSyncService: Repository not found (404) at $repoUrl');
      } else {
        log.w('RepoSyncService: Failed to fetch catalog from $repoUrl: $e');
      }
      return [];
    }
  }

  /// Downloads script content for an extension from [pkgUrl].
  Future<String?> downloadScript(String pkgUrl) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final separator = pkgUrl.contains('?') ? '&' : '?';
      final requestUrl = '$pkgUrl${separator}_t=$cacheBuster';

      final res = await _dio.get<String>(
        requestUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );
      return res.data;
    } catch (e) {
      log.e('RepoSyncService: Failed to download script from $pkgUrl: $e');
      return null;
    }
  }
}

