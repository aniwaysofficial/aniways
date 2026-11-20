/// App-wide compile-time constants.
abstract final class AppConstants {
  /// Display name shown in the UI.
  static const String appName = 'Aniways';

  /// GitHub repository for fetching app releases.
  static const String githubRepo = 'aniwaysofficial/aniways';

  /// Brand asset paths
  static const String logoLight = 'assets/logo_light.webp';
  static const String logoDark = 'assets/logo_dark.webp';
  static const String logoMonochrome = 'assets/logo_monochrome.webp';

  /// Duration before a network request is considered timed out.
  static const Duration networkTimeout = Duration(seconds: 30);
}
