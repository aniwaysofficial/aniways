import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aniways/core/logger.dart';

/// Manages authentication tokens and user session data using
/// encrypted device storage ([FlutterSecureStorage]).
///
/// All methods are static - no instance management needed.
///
/// ### Typical flow
/// ```
/// 1. User logs in → saveSession(accessToken, refreshToken, userData)
/// 2. API call     → getAccessToken() to read the bearer token
/// 3. 401 response → refreshAccessToken(), retry
/// 4. Logout       → clearSession()
/// ```
class SessionManager {
  static const _storage = FlutterSecureStorage();

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';

  // ── Write ───────────────────────────────────────────────────────────

  /// Persists a full session after a successful login.
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyAccessToken, value: accessToken),
        _storage.write(key: _keyRefreshToken, value: refreshToken),
        _storage.write(key: _keyUserData, value: json.encode(userData)),
      ]);
      log.i('Session saved');
    } catch (e, st) {
      log.e('Failed to save session', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates only the access token (e.g. after a token refresh).
  static Future<void> updateAccessToken(String token) async {
    try {
      await _storage.write(key: _keyAccessToken, value: token);
      log.i('Access token updated');
    } catch (e, st) {
      log.e('Failed to update access token', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates the cached user data.
  static Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _keyUserData, value: json.encode(userData));
      log.i('User data updated');
    } catch (e, st) {
      log.e('Failed to update user data', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Read ────────────────────────────────────────────────────────────

  /// Returns the stored access token, or `null` if not logged in.
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      log.e('Failed to read access token', error: e);
      return null;
    }
  }

  /// Returns the stored refresh token, or `null`.
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      log.e('Failed to read refresh token', error: e);
      return null;
    }
  }

  /// Returns the stored user data as a JSON map, or `null`.
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final raw = await _storage.read(key: _keyUserData);
      if (raw != null) return json.decode(raw) as Map<String, dynamic>;
      return null;
    } catch (e) {
      log.e('Failed to read user data', error: e);
      return null;
    }
  }

  /// Whether the user has a stored session.
  static Future<bool> get isLoggedIn async {
    final token = await getAccessToken();
    return token != null;
  }

  // ── Delete ──────────────────────────────────────────────────────────

  /// Wipes all session data (logout).
  static Future<void> clearSession() async {
    try {
      await _storage.deleteAll();
      log.i('Session cleared');
    } catch (e, st) {
      log.e('Failed to clear session', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Token Refresh ───────────────────────────────────────────────────

  /// Generic authenticated-request wrapper with automatic token refresh.
  ///
  /// [apiCall] receives the current access token. If it throws with a 401
  /// status, [refreshToken] is called to obtain a new access token and the
  /// request is retried once.
  ///
  /// If refresh also fails, [onAuthFailed] is called (typically to navigate
  /// to the login screen) and an exception is thrown.
  ///
  /// ```dart
  /// final result = await SessionManager.authenticatedRequest(
  ///   apiCall: (token) => api.getWatchlist(token),
  ///   refreshToken: () => authApi.refresh(await SessionManager.getRefreshToken()!),
  ///   onAuthFailed: () => navigator.pushReplacementNamed('/login'),
  /// );
  /// ```
  static Future<T> authenticatedRequest<T>({
    required Future<T> Function(String accessToken) apiCall,
    required Future<String?> Function() refreshToken,
    required VoidCallback onAuthFailed,
  }) async {
    String? accessToken = await getAccessToken();
    if (accessToken == null) {
      log.w('No access token for authenticated request');
      onAuthFailed();
      throw Exception('Not authenticated');
    }

    try {
      return await apiCall(accessToken);
    } catch (e) {
      // Check if it's a 401-style error. We check the string representation
      // since the caller may use Dio, http, or any other client.
      final is401 =
          e.toString().contains('401') || e.toString().contains('Unauthorized');

      if (!is401) rethrow;

      log.w('Access token expired (401), attempting refresh…');
      final newToken = await refreshToken();

      if (newToken != null) {
        await updateAccessToken(newToken);
        log.i('Retrying with refreshed token');
        return await apiCall(newToken);
      }

      // Refresh failed - session is dead.
      log.e('Token refresh failed, clearing session');
      await clearSession();
      onAuthFailed();
      throw Exception('Session expired. Please log in again.');
    }
  }
}
