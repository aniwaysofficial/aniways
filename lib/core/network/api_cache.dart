import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:aniways/core/logger.dart';

// ═════════════════════════════════════════════════════════════════════════
// Policy
// ═════════════════════════════════════════════════════════════════════════

/// How long a cached response may be used. Tune the lifetimes below.
///
/// Within [ttl] the response is served straight from the cache, with no
/// network call. After that it is never shown again: the data is fetched anew
/// (the UI shows its normal loading state meanwhile).
///
/// [persist] `false` keeps the entry in memory only (not on disk).
class CachePolicy {
  const CachePolicy(this.ttl, {this.persist = true});

  final Duration ttl;
  final bool persist;

  /// Trending lists: the order shifts through the day.
  static const trending = CachePolicy(Duration(hours: 2));

  /// Current season / recently released: the set of shows changes slowly.
  static const season = CachePolicy(Duration(hours: 6));

  /// Upcoming: slow, but shows leave it once they start airing.
  static const upcoming = CachePolicy(Duration(hours: 12));

  /// All-time rankings (popular, top rated, per-genre): barely move.
  static const ranking = CachePolicy(Duration(days: 1));

  /// The genre list is static.
  static const genres = CachePolicy(Duration(days: 30));

  /// Search results: only worth keeping for back-navigation, never on disk.
  static const search = CachePolicy(Duration(minutes: 5), persist: false);

  /// This week (or a future week): delays and reschedules do happen.
  static const schedule = CachePolicy(Duration(hours: 3));

  /// A week that is already over can't change any more.
  static const pastSchedule = CachePolicy(Duration(days: 30));

  /// Details of a finished show: nothing changes.
  static const detailsFinished = CachePolicy(Duration(days: 7));

  /// Details of an airing show: scores and next episode move.
  static const detailsAiring = CachePolicy(Duration(hours: 3));

  /// Details of a show that hasn't started yet.
  static const detailsUpcoming = CachePolicy(Duration(hours: 12));

  /// Details with any other status (e.g. hiatus).
  static const detailsOther = CachePolicy(Duration(days: 1));
}

/// Picks the policy for a response, looking at the data itself. Returning
/// `null` means "don't cache this one" (e.g. an empty list that is probably a
/// hiccup).
typedef CachePolicyResolver = CachePolicy? Function(Map<String, dynamic> data);

// ═════════════════════════════════════════════════════════════════════════
// Cache
// ═════════════════════════════════════════════════════════════════════════

/// Two-level (memory + disk) cache for decoded JSON responses, with
/// de-duplication of identical in-flight requests.
///
/// The cache never breaks the app: any disk problem is logged and the cache
/// quietly falls back to memory only.
class ApiCache {
  ApiCache({Directory? directory}) : _fixedDirectory = directory;

  /// Shared instance used by the app.
  static final ApiCache instance = ApiCache();

  /// Bumped when the file layout changes; older files are then ignored.
  static const int _formatVersion = 2;
  static const int _maxMemoryEntries = 80;
  static const int _maxFiles = 300;
  static const Duration _maxFileAge = Duration(days: 35);

  final Directory? _fixedDirectory;
  Future<Directory?>? _dir;

  /// Insertion order doubles as LRU order (oldest first).
  final LinkedHashMap<String, _Entry> _memory = LinkedHashMap();
  final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  /// Entries saved before this moment are no longer used (see [invalidate]).
  DateTime _staleBefore = DateTime.fromMillisecondsSinceEpoch(0);
  int _writeSeq = 0;

  // ── Keys ────────────────────────────────────────────────────────────

  /// Cache key for a GraphQL request. Built from a hash of the query text, so
  /// changing a query automatically retires its old entries, plus the
  /// variables in a stable order.
  static String keyFor(String query, [Map<String, dynamic>? variables]) {
    final vars = variables == null
        ? ''
        : jsonEncode(SplayTreeMap<String, dynamic>.from(variables));
    return '${_hash(query)}:$vars';
  }

  // ── Public API ──────────────────────────────────────────────────────

  /// Emits exactly one value for [key]: the stored data while it is within
  /// its lifetime, otherwise the result of [fetch] (errors reach the
  /// listener). Concurrent calls for the same key share one [fetch].
  ///
  /// It is a stream so callers can treat it like the other `watch*` methods;
  /// `await watch(...).last` gives the single value.
  Stream<Map<String, dynamic>> watch(
    String key,
    Future<Map<String, dynamic>> Function() fetch, {
    required CachePolicyResolver policy,
  }) async* {
    final entry = await _read(key);
    if (entry != null && _isUsable(entry, DateTime.now())) {
      yield entry.data;
      return;
    }
    yield await _load(key, fetch, policy);
  }

  /// Makes everything cached so far count as expired, so each item is
  /// fetched again the next time it is used. Call this on pull-to-refresh.
  void invalidate() => _staleBefore = DateTime.now();

  /// Forgets one entry (memory and disk).
  Future<void> remove(String key) async {
    _memory.remove(key);
    final dir = await _directory();
    if (dir != null) await _delete(_fileFor(dir, key));
  }

  /// Deletes everything. Handy for a "Clear cache" button in settings.
  Future<void> clear() async {
    _memory.clear();
    final dir = await _directory();
    if (dir == null) return;
    try {
      await for (final e in dir.list()) {
        if (e is File) await _delete(e);
      }
    } catch (e) {
      log.w('Could not clear the disk cache', error: e);
    }
  }

  // ── Loading ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _load(
    String key,
    Future<Map<String, dynamic>> Function() fetch,
    CachePolicyResolver policy,
  ) {
    // Block body on purpose: `remove` returns the very future we are still
    // building, and whenComplete would wait for it forever.
    return _inFlight[key] ??= _fetchAndStore(key, fetch, policy).whenComplete(
      () {
        _inFlight.remove(key);
      },
    );
  }

  Future<Map<String, dynamic>> _fetchAndStore(
    String key,
    Future<Map<String, dynamic>> Function() fetch,
    CachePolicyResolver policy,
  ) async {
    final data = await fetch();
    final p = policy(data);
    if (p != null) {
      final now = DateTime.now();
      final entry = _Entry(data: data, savedAt: now, expiresAt: now.add(p.ttl));
      _remember(key, entry);
      if (p.persist) unawaited(_write(key, entry));
    }
    return data;
  }

  bool _isExpired(_Entry entry, DateTime now) => !now.isBefore(entry.expiresAt);

  bool _isUsable(_Entry entry, DateTime now) =>
      !_isExpired(entry, now) &&
      // The clock moved back: the entry's age can't be trusted.
      !now.isBefore(entry.savedAt) &&
      !entry.savedAt.isBefore(_staleBefore);

  // ── Memory ──────────────────────────────────────────────────────────

  void _remember(String key, _Entry entry) {
    _memory.remove(key);
    _memory[key] = entry;
    while (_memory.length > _maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  // ── Disk ────────────────────────────────────────────────────────────

  Future<Directory?> _directory() => _dir ??= _openDirectory();

  Future<Directory?> _openDirectory() async {
    try {
      final dir =
          _fixedDirectory ??
          Directory(
            '${(await getApplicationCacheDirectory()).path}/anilist_cache',
          );
      await dir.create(recursive: true);
      unawaited(_prune(dir));
      return dir;
    } catch (e, st) {
      log.w(
        'Disk cache unavailable, using memory only',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  File _fileFor(Directory dir, String key) =>
      File('${dir.path}/${_hash(key)}${_hex(_fnv1a(key, 0x050c5d1f))}.json');

  Future<_Entry?> _read(String key) async {
    final cached = _memory.remove(key);
    if (cached != null) {
      _memory[key] = cached; // most recently used
      return cached;
    }

    final dir = await _directory();
    if (dir == null) return null;
    final file = _fileFor(dir, key);

    try {
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      // A different key can (very rarely) land on the same file name.
      if (json is! Map || json['v'] != _formatVersion || json['key'] != key) {
        return null;
      }
      final entry = _Entry.fromJson(json.cast<String, dynamic>());
      if (_isExpired(entry, DateTime.now())) {
        unawaited(_delete(file));
        return null;
      }
      _remember(key, entry);
      return entry;
    } catch (e) {
      log.w('Dropping unreadable cache file ${file.path}', error: e);
      unawaited(_delete(file));
      return null;
    }
  }

  Future<void> _write(String key, _Entry entry) async {
    final dir = await _directory();
    if (dir == null) return;
    final file = _fileFor(dir, key);
    // Write to a temp file and rename, so a crash mid-write can't leave a
    // half-written cache file behind.
    final tmp = File('${file.path}.${_writeSeq++}.tmp');
    try {
      await tmp.writeAsString(jsonEncode(entry.toJson(key)), flush: true);
      await tmp.rename(file.path);
    } catch (e) {
      log.w('Could not write cache file for $key', error: e);
      await _delete(tmp);
    }
  }

  Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort.
    }
  }

  /// Runs once per launch: removes leftovers, files too old to matter, and
  /// the oldest files beyond [_maxFiles] (details pages pile up as people
  /// browse).
  Future<void> _prune(Directory dir) async {
    try {
      final now = DateTime.now();
      final files = <(File, DateTime)>[];

      await for (final e in dir.list()) {
        if (e is! File) continue;
        final modified = (await e.stat()).modified;
        final isTmp = e.path.endsWith('.tmp');
        final tooOld = modified.isBefore(
          now.subtract(isTmp ? const Duration(hours: 1) : _maxFileAge),
        );
        if (tooOld) {
          await _delete(e);
        } else if (!isTmp) {
          files.add((e, modified));
        }
      }

      if (files.length > _maxFiles) {
        files.sort((a, b) => a.$2.compareTo(b.$2));
        for (final f in files.take(files.length - _maxFiles)) {
          await _delete(f.$1);
        }
      }
    } catch (e) {
      log.w('Cache cleanup failed', error: e);
    }
  }

  // ── Hashing (FNV-1a, stable across launches unlike String.hashCode) ──

  static int _fnv1a(String text, int seed) {
    var hash = seed;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static String _hex(int value) => value.toRadixString(16).padLeft(8, '0');

  static String _hash(String text) => _hex(_fnv1a(text, 0x811c9dc5));
}

class _Entry {
  const _Entry({
    required this.data,
    required this.savedAt,
    required this.expiresAt,
  });

  factory _Entry.fromJson(Map<String, dynamic> json) {
    DateTime at(String field) =>
        DateTime.fromMillisecondsSinceEpoch(json[field] as int);
    return _Entry(
      data: (json['data'] as Map).cast<String, dynamic>(),
      savedAt: at('savedAt'),
      expiresAt: at('expiresAt'),
    );
  }

  final Map<String, dynamic> data;
  final DateTime savedAt;
  final DateTime expiresAt;

  Map<String, dynamic> toJson(String key) => {
    'v': ApiCache._formatVersion,
    'key': key,
    'savedAt': savedAt.millisecondsSinceEpoch,
    'expiresAt': expiresAt.millisecondsSinceEpoch,
    'data': data,
  };
}
