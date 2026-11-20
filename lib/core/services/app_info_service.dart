import 'package:package_info_plus/package_info_plus.dart';

/// Service providing platform and package metadata (e.g. version, build number)
/// sourced dynamically from the app bundle and pubspec.yaml.
class AppInfoService {
  AppInfoService._();
  static final AppInfoService instance = AppInfoService._();

  PackageInfo? _info;

  /// Initializes package metadata asynchronously on app startup.
  Future<void> init() async {
    try {
      _info = await PackageInfo.fromPlatform();
    } catch (_) {}
  }

  /// The application name (e.g. "Aniways").
  String get appName =>
      _info?.appName.isNotEmpty == true ? _info!.appName : 'Aniways';

  /// The application semantic version (e.g. "1.0.0").
  String get version =>
      _info?.version.isNotEmpty == true ? _info!.version : '1.0.0';

  /// The build number / version code (e.g. "1").
  String get buildNumber =>
      _info?.buildNumber.isNotEmpty == true ? _info!.buildNumber : '1';
}
