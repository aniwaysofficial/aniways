import 'dart:async';
import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:aniways/core/logger.dart';
import 'bridges/crypto_bridge.dart';
import 'bridges/http_bridge.dart';
import 'bridges/logger_bridge.dart';
import 'js_bridge.dart';

/// Wraps the QuickJS engine and manages extension lifecycle, bridge routing,
/// and safe async execution.
class ExtensionRuntime {
  ExtensionRuntime({
    HttpBridge? httpBridge,
    CryptoBridge? cryptoBridge,
    LoggerBridge? loggerBridge,
  })  : _httpBridge = httpBridge ?? HttpBridge(),
        _cryptoBridge = cryptoBridge ?? const CryptoBridge(),
        _loggerBridge = loggerBridge ?? const LoggerBridge();

  final HttpBridge _httpBridge;
  final CryptoBridge _cryptoBridge;
  final LoggerBridge _loggerBridge;

  JavascriptRuntime? _runtime;
  final Set<String> _loadedExtensions = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Set<String> get loadedExtensionIds => Set.unmodifiable(_loadedExtensions);

  /// Initializes the QuickJS runtime and binds native host bridges.
  Future<void> init() async {
    if (_isInitialized) return;

    final runtime = getJavascriptRuntime(xhr: false);
    runtime.enableHandlePromises();

    // 1. Logger Channel
    void onLog(dynamic args) {
      try {
        final list = args is List ? args : jsonDecode(args.toString()) as List;
        _loggerBridge.logMessage(list);
      } catch (e) {
        log.d('[Extension Log Error] $e: $args');
      }
    }
    runtime.onMessage('aniways_logger', onLog);

    // 2. HTTP Channel
    Future<void> onHttp(dynamic args) async {
      try {
        final Map<String, dynamic> req = args is Map
            ? args.cast<String, dynamic>()
            : (jsonDecode(args.toString()) as Map).cast<String, dynamic>();

        final String id = req['id'] as String;
        final res = await _httpBridge.execute(req);
        _dispatchCallback(id, null, res);
      } catch (e) {
        log.w('Extension HTTP bridge error: $e');
        if (args is Map && args['id'] != null) {
          _dispatchCallback(args['id'].toString(), e.toString(), null);
        }
      }
    }
    runtime.onMessage('aniways_http', onHttp);

    // 3. Crypto Channel
    void onCrypto(dynamic args) {
      try {
        final Map<String, dynamic> req = args is Map
            ? args.cast<String, dynamic>()
            : (jsonDecode(args.toString()) as Map).cast<String, dynamic>();

        final String id = req['id'] as String;
        final String action = req['action'] as String;
        final Map<String, dynamic> payload =
            (req['payload'] as Map?)?.cast<String, dynamic>() ?? {};

        dynamic result;
        switch (action) {
          case 'aesDecryptCbc':
            result = _cryptoBridge.aesDecryptCbc(
              ciphertext: payload['ciphertext'],
              key: payload['key'],
              iv: payload['iv'],
            );
            break;
          case 'hmacSha256':
            result = _cryptoBridge.hmacSha256(
              data: payload['data']?.toString() ?? '',
              key: payload['key']?.toString() ?? '',
              encoding: payload['encoding']?.toString() ?? 'hex',
            );
            break;
          case 'base64UrlEncode':
            result = _cryptoBridge.base64UrlEncode(payload['input']?.toString() ?? '');
            break;
          case 'base64UrlDecode':
            result = _cryptoBridge.base64UrlDecode(payload['input']?.toString() ?? '');
            break;
          case 'md5':
            result = _cryptoBridge.md5Hash(payload['input']?.toString() ?? '');
            break;
          case 'sha256':
            result = _cryptoBridge.sha256Hash(payload['input']?.toString() ?? '');
            break;
          default:
            throw UnsupportedError('Unknown crypto action: $action');
        }

        _dispatchCallback(id, null, result);
      } catch (e) {
        log.w('Extension Crypto bridge error: $e');
        if (args is Map && args['id'] != null) {
          _dispatchCallback(args['id'].toString(), e.toString(), null);
        }
      }
    }
    runtime.onMessage('aniways_crypto', onCrypto);

    _runtime = runtime;

    // Evaluate the bootstrap script
    final evalBoot = runtime.evaluate(JsBridge.bootstrapScript);
    if (evalBoot.isError) {
      log.e('Failed to bootstrap JsBridge: ${evalBoot.stringResult}');
      throw Exception('JsBridge bootstrap error: ${evalBoot.stringResult}');
    }

    _isInitialized = true;
    log.i('ExtensionRuntime initialized successfully with QuickJS.');
  }

  void _dispatchCallback(String id, String? error, dynamic result) {
    if (_runtime == null) return;
    final errJson = error != null ? jsonEncode(error) : 'null';
    final resJson = result != null ? jsonEncode(result) : 'null';

    final evalRes = _runtime!.evaluate('globalThis.__aniways_cb("$id", $errJson, $resJson);');
    if (evalRes.isError) {
      log.e('ExtensionRuntime: __aniways_cb failed with error: ${evalRes.stringResult}');
    }
    _runtime!.executePendingJob();
  }

  /// Evaluates an extension's bundled JavaScript code and registers it.
  Future<bool> loadExtension(String id, String scriptCode) async {
    if (!_isInitialized) await init();
    final runtime = _runtime;
    if (runtime == null) return false;

    try {
      final res = runtime.evaluate(scriptCode);
      if (res.isError) {
        log.e('Error loading extension [$id]: ${res.stringResult}');
        return false;
      }

      // Check if registered
      final check = runtime.evaluate('Boolean(globalThis.__aniways_extensions["$id"])');
      if (check.stringResult == 'true') {
        _loadedExtensions.add(id);
        log.i('Extension [$id] successfully registered.');
        return true;
      } else {
        log.w('Extension [$id] script evaluated, but did not call registerExtension() with id "$id".');
        return false;
      }
    } catch (e) {
      log.e('Exception loading extension [$id]: $e');
      return false;
    }
  }

  /// Unloads an extension from memory.
  void unloadExtension(String id) {
    if (_runtime == null) return;
    _runtime!.evaluate('delete globalThis.__aniways_extensions["$id"];');
    _loadedExtensions.remove(id);
  }

  /// Fetches episodes list for an anime via extension [id].
  Future<List<Map<String, dynamic>>> getEpisodes(
    String id,
    Map<String, dynamic> animeMeta,
  ) async {
    if (!_isInitialized) await init();
    final runtime = _runtime;
    if (runtime == null) return [];

    final metaJson = jsonEncode(animeMeta);
    final evalCode = '''
      (async function() {
        var ext = globalThis.__aniways_extensions["$id"];
        if (!ext) throw new Error("Extension $id is not loaded.");
        var meta = $metaJson;
        var eps = await ext.getEpisodes(meta);
        return JSON.stringify(eps || []);
      })()
    ''';

    try {
      final promise = await runtime.evaluateAsync(evalCode);
      runtime.executePendingJob();
      final result = await runtime.handlePromise(promise);

      if (result.isError) {
        log.w('Extension [$id] getEpisodes error: ${result.stringResult}');
        return [];
      }

      final parsed = jsonDecode(result.stringResult);
      if (parsed is List) {
        return parsed.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
      return [];
    } catch (e) {
      log.w('Extension [$id] getEpisodes failed: $e');
      return [];
    }
  }

  /// Resolves video streaming sources for an episode via extension [id].
  Future<Map<String, dynamic>?> getStreams(
    String id,
    String episodeRef,
    String audio,
  ) async {
    if (!_isInitialized) await init();
    final runtime = _runtime;
    if (runtime == null) return null;

    final refEscaped = jsonEncode(episodeRef);
    final audioEscaped = jsonEncode(audio);
    final evalCode = '''
      (async function() {
        var ext = globalThis.__aniways_extensions["$id"];
        if (!ext) throw new Error("Extension $id is not loaded.");
        var res = await ext.getStreams($refEscaped, $audioEscaped);
        return JSON.stringify(res || { streams: [] });
      })()
    ''';

    try {
      final promise = await runtime.evaluateAsync(evalCode);
      runtime.executePendingJob();
      final result = await runtime.handlePromise(promise);

      if (result.isError) {
        log.w('Extension [$id] getStreams error: ${result.stringResult}');
        return null;
      }

      final parsed = jsonDecode(result.stringResult);
      if (parsed is Map) {
        return parsed.cast<String, dynamic>();
      }
      return null;
    } catch (e) {
      log.w('Extension [$id] getStreams failed: $e');
      return null;
    }
  }

  /// Disposes the JS runtime.
  void dispose() {
    _loadedExtensions.clear();
    _runtime?.dispose();
    _runtime = null;
    _isInitialized = false;
  }
}

