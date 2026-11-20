import 'dart:io';

/// Represents a downloadable binary asset from a GitHub release.
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.size,
    required this.downloadUrl,
    required this.contentType,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      downloadUrl: json['browser_download_url'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
    );
  }

  final String name;
  final int size;
  final String downloadUrl;
  final String contentType;

  bool get isApk => name.toLowerCase().endsWith('.apk');
  bool get isArm64 => name.toLowerCase().contains('arm64-v8a');
  bool get isUniversal => name.toLowerCase().contains('universal');
  bool get isWindows =>
      name.toLowerCase().endsWith('.exe') ||
      name.toLowerCase().endsWith('.msix') ||
      (name.toLowerCase().contains('windows') &&
          name.toLowerCase().endsWith('.zip'));
  bool get isLinux =>
      name.toLowerCase().endsWith('.appimage') ||
      name.toLowerCase().endsWith('.deb') ||
      (name.toLowerCase().contains('linux') &&
          name.toLowerCase().endsWith('.tar.gz'));
  bool get isMacOS =>
      name.toLowerCase().endsWith('.dmg') ||
      (name.toLowerCase().contains('macos') &&
          name.toLowerCase().endsWith('.zip'));

  String get formattedSize {
    if (size <= 0) return '';
    final mb = size / (1024 * 1024);
    if (mb < 0.1) {
      final kb = size / 1024;
      return '${kb.toStringAsFixed(0)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Represents a release parsed from the GitHub Releases API.
class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.version,
    required this.title,
    required this.changelog,
    required this.publishedAt,
    required this.htmlUrl,
    required this.assets,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    final version = tag.startsWith('v') || tag.startsWith('V')
        ? tag.substring(1)
        : tag;

    final assetsRaw = json['assets'] as List<dynamic>? ?? const [];
    final assets = assetsRaw
        .whereType<Map<String, dynamic>>()
        .map(ReleaseAsset.fromJson)
        .toList(growable: false);

    DateTime published;
    try {
      published = DateTime.parse(json['published_at'] as String? ?? '');
    } catch (_) {
      published = DateTime.now();
    }

    return AppRelease(
      tagName: tag,
      version: version,
      title: json['name'] as String? ?? tag,
      changelog: json['body'] as String? ?? '',
      publishedAt: published,
      htmlUrl: json['html_url'] as String? ?? '',
      assets: assets,
    );
  }

  final String tagName;
  final String version;
  final String title;
  final String changelog;
  final DateTime publishedAt;
  final String htmlUrl;
  final List<ReleaseAsset> assets;

  /// Returns the most suitable asset for the current OS/platform.
  ReleaseAsset? get matchingAsset {
    if (assets.isEmpty) return null;

    if (Platform.isAndroid) {
      // 1. Match arm64-v8a (majority of modern phones)
      final arm64 = assets.firstWhere(
        (a) => a.isApk && a.isArm64,
        orElse: () => assets.firstWhere(
          // 2. Fall back to universal APK
          (a) => a.isApk && a.isUniversal,
          orElse: () => assets.firstWhere(
            // 3. Fall back to any APK
            (a) => a.isApk,
            orElse: () => assets.first,
          ),
        ),
      );
      return arm64;
    }

    if (Platform.isWindows) {
      return assets.cast<ReleaseAsset?>().firstWhere(
            (a) => a != null && a.isWindows,
            orElse: () => null,
          );
    }

    if (Platform.isLinux) {
      return assets.cast<ReleaseAsset?>().firstWhere(
            (a) => a != null && a.isLinux,
            orElse: () => null,
          );
    }

    if (Platform.isMacOS) {
      return assets.cast<ReleaseAsset?>().firstWhere(
            (a) => a != null && a.isMacOS,
            orElse: () => null,
          );
    }

    return null;
  }

  /// Checks if this release version is strictly newer than [currentVersion].
  bool isNewerThan(String currentVersion) {
    return compareSemVer(version, currentVersion) > 0;
  }

  /// Formatted relative publish date (e.g. "Today", "Yesterday", "2 days ago").
  String get relativeDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes.clamp(1, 59)}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  /// Compares two semantic version strings (e.g. "1.0.2" vs "1.0.0+1").
  /// Returns > 0 if v1 > v2, < 0 if v1 < v2, and 0 if equal.
  static int compareSemVer(String v1, String v2) {
    final clean1 = (v1.startsWith('v') || v1.startsWith('V')) ? v1.substring(1) : v1;
    final clean2 = (v2.startsWith('v') || v2.startsWith('V')) ? v2.substring(1) : v2;

    final parts1 = clean1.split('+');
    final parts2 = clean2.split('+');

    final nums1 = parts1[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final nums2 = parts2[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = nums1.length > nums2.length ? nums1.length : nums2.length;
    for (var i = 0; i < maxLen; i++) {
      final n1 = i < nums1.length ? nums1[i] : 0;
      final n2 = i < nums2.length ? nums2[i] : 0;
      if (n1 > n2) return 1;
      if (n1 < n2) return -1;
    }

    // Compare build numbers if base versions are identical
    final build1 = parts1.length > 1 ? int.tryParse(parts1[1]) ?? 0 : 0;
    final build2 = parts2.length > 1 ? int.tryParse(parts2[1]) ?? 0 : 0;
    return build1.compareTo(build2);
  }
}

/// Result of an update check.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.hasUpdate,
    this.release,
    this.errorMessage,
  });

  final bool hasUpdate;
  final AppRelease? release;
  final String? errorMessage;
}

/// Download stream progress snapshot.
class DownloadProgress {
  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;
  final int totalBytes;

  double get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  String get formattedReceived => (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get formattedTotal => (totalBytes / (1024 * 1024)).toStringAsFixed(1);
  int get percentage => (progress * 100).toInt();
}

