import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aniways/core/logger.dart';

/// Platform-specific installer interface.
class UpdateInstaller {
  static const MethodChannel _channel = MethodChannel('com.aniways.app/app_installer');

  /// Checks if the app currently has permission to install unknown APKs (Android 8.0+).
  static Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return res ?? true;
    } catch (e) {
      log.w('Could not query package install permission: $e');
      return true;
    }
  }

  /// Opens the system settings screen for "Install unknown apps" targeting Aniways.
  static Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('openInstallPermissionSettings');
      return res ?? false;
    } catch (e) {
      log.e('Failed to open install permission settings: $e');
      return false;
    }
  }

  /// Launches the system package installer for the downloaded APK file.
  static Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return res ?? false;
    } catch (e) {
      log.e('Failed to launch APK package installer: $e');
      return false;
    }
  }

  /// Launches the given release download link or GitHub release page in the system browser.
  static Future<bool> openReleaseUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      log.e('Could not launch release URL: $e');
    }
    return false;
  }
}

