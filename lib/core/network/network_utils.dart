import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:aniways/core/logger.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Singleton that monitors network connectivity and provides a convenient
/// [executeRequest] wrapper with automatic retry-on-reconnect behaviour.
///
/// ### Setup
/// ```dart
/// // In your app's root widget initState:
/// NetworkUtils().initialize(context);
///
/// // In your dispose:
/// NetworkUtils().dispose();
/// ```
///
/// ### Usage
/// ```dart
/// final data = await NetworkUtils().executeRequest<AnimeResponse>(
///   context,
///   () => api.fetchAnime(id),
///   autoRetry: true,
/// );
/// ```
class NetworkUtils with WidgetsBindingObserver {
  // ── Singleton ───────────────────────────────────────────────────────
  static final NetworkUtils _instance = NetworkUtils._internal();
  factory NetworkUtils() => _instance;
  NetworkUtils._internal();

  // ── Dependencies ────────────────────────────────────────────────────
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  // ── Subscriptions ───────────────────────────────────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetStatus>? _internetSub;

  // ── State ───────────────────────────────────────────────────────────
  bool _hasInternet = true;
  bool _isShowingDisconnectedUI = false;
  BuildContext? _currentContext;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  // ── Debounce timers ─────────────────────────────────────────────────
  Timer? _connectTimer;
  Timer? _disconnectTimer;
  static const _connectDelay = Duration(seconds: 2);
  static const _disconnectDelay = Duration(seconds: 3);

  // ── Public getters ──────────────────────────────────────────────────

  /// Whether the device currently has internet access (synchronous check).
  bool get hasInternet => _hasInternet;

  /// Asynchronous internet check via the checker library.
  Future<bool> checkConnection() => _internetChecker.hasInternetAccess;

  /// Whether the current connectivity type is Wi-Fi.
  Future<bool> get isWifi async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  // ── Initialisation / Disposal ───────────────────────────────────────

  /// Start monitoring. Call once from your root widget's [initState].
  void initialize(BuildContext context) {
    _currentContext = context;

    _connectivitySub = _connectivity.onConnectivityChanged.listen((_) {
      _recheckInternet();
    });

    _internetSub = _internetChecker.onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        _onConnected();
      } else {
        _onDisconnected();
      }
    });

    // Register lifecycle observer (the class itself is the observer via mixin).
    WidgetsBinding.instance.addObserver(this);

    log.d('NetworkUtils initialised');
  }

  /// Clean up listeners and timers.
  void dispose() {
    _connectivitySub?.cancel();
    _internetSub?.cancel();
    _cancelTimers();
    WidgetsBinding.instance.removeObserver(this);
    _currentContext = null;
  }

  // ── Lifecycle handling ──────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      log.d('App resumed - rechecking connectivity');
      _cancelTimers();
      Future.delayed(const Duration(milliseconds: 500), _recheckInternet);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _cancelTimers();
    }
  }

  // ── Request execution ───────────────────────────────────────────────

  /// Execute a network request with optional automatic retry.
  ///
  /// If [autoRetry] is `true` and the device is offline the method will
  /// wait for the connection to come back and then re-execute [request].
  ///
  /// If [quickCheck] is `true` (default) we skip the up-front internet
  /// verification and only check on failure - this is the fast path.
  Future<T> executeRequest<T>(
    BuildContext context,
    Future<T> Function() request, {
    bool autoRetry = true,
    Duration retryDelay = const Duration(seconds: 1),
    bool quickCheck = true,
  }) async {
    _currentContext = context;

    // Optional upfront check.
    if (!quickCheck) {
      final connected = await _internetChecker.hasInternetAccess;
      if (!connected) {
        _onDisconnected();
        if (autoRetry) {
          return _waitAndRetry<T>(request, retryDelay);
        }
        throw NoInternetException('No internet connection available');
      }
    }

    // Fast path - just try the request.
    try {
      return await request();
    } catch (e) {
      // If the request fails, check whether it's a connectivity issue.
      final results = await _connectivity.checkConnectivity();
      final offline =
          results.isEmpty || results.contains(ConnectivityResult.none);

      if (offline) {
        _onDisconnected();
        if (autoRetry) return _waitAndRetry<T>(request, retryDelay);
      }
      rethrow;
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────

  Future<void> _recheckInternet() async {
    final connected = await _internetChecker.hasInternetAccess;
    if (connected) {
      _onConnected();
    } else {
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    if (_lifecycleState != AppLifecycleState.resumed) return;

    _connectTimer?.cancel();
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(_disconnectDelay, () {
      if (!_isShowingDisconnectedUI && _currentContext != null) {
        _hasInternet = false;
        _isShowingDisconnectedUI = true;
        log.w('No internet connection');

        // Show a persistent snackbar.
        if (_currentContext != null) {
          AniwaysSnackBar.error(
            _currentContext!,
            message: 'No Internet Connection',
            icon: Icons.wifi_off_rounded,
            duration: const Duration(days: 365),
          );
        }
      }
    });
  }

  void _onConnected() {
    _disconnectTimer?.cancel();
    _connectTimer?.cancel();

    if (_lifecycleState != AppLifecycleState.resumed) {
      _hasInternet = true;
      return;
    }

    _connectTimer = Timer(_connectDelay, () {
      if (_isShowingDisconnectedUI && _currentContext != null) {
        _hasInternet = true;
        _isShowingDisconnectedUI = false;

        AniwaysSnackBar.success(
          _currentContext!,
          message: 'Internet Connected',
          icon: Icons.wifi_rounded,
          duration: const Duration(seconds: 2),
        );
      } else if (!_hasInternet) {
        _hasInternet = true;
      }
    });
  }

  Future<T> _waitAndRetry<T>(
    Future<T> Function() request,
    Duration retryDelay,
  ) async {
    final completer = Completer<T>();
    StreamSubscription<InternetStatus>? sub;

    sub = _internetChecker.onStatusChange.listen((status) async {
      if (status == InternetStatus.connected) {
        await sub?.cancel();
        await Future.delayed(retryDelay);
        try {
          final result = await request();
          if (!completer.isCompleted) completer.complete(result);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      }
    });

    return completer.future;
  }

  void _cancelTimers() {
    _connectTimer?.cancel();
    _disconnectTimer?.cancel();
  }
}

/// Thrown when a request cannot proceed due to lack of connectivity.
class NoInternetException implements Exception {
  final String message;
  NoInternetException(this.message);

  @override
  String toString() => 'NoInternetException: $message';
}
