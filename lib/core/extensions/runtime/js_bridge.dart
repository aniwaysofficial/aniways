/// JavaScript bootstrap script injected into QuickJS before any extension runs.
///
/// Sets up:
/// - `globalThis.aniways.http`
/// - `globalThis.aniways.crypto`
/// - `globalThis.fetch` (standard Fetch API polyfill)
/// - `globalThis.console` (logging to Dart AppLogger)
/// - `globalThis.registerExtension(ext)` (extension registration table)
class JsBridge {
  static const String bootstrapScript = r'''
(function(global) {
  if (global.__aniways_initialized) return;
  global.__aniways_initialized = true;

  // Request callback dispatchers
  global.__aniways_callbacks = {};
  global.__aniways_cb = function(id, err, res) {
    var cb = global.__aniways_callbacks[id];
    if (cb) {
      delete global.__aniways_callbacks[id];
      if (err) {
        cb.reject(new Error(err));
      } else {
        cb.resolve(res);
      }
    }
  };

  // Generate unique request IDs
  var reqCounter = 0;
  function nextId() {
    return 'h_' + (++reqCounter) + '_' + Math.random().toString(36).substring(7);
  }

  // 1. Logger Bridge
  global.console = {
    log: function() {
      var args = Array.prototype.slice.call(arguments);
      sendMessage('aniways_logger', JSON.stringify(['info'].concat(args)));
    },
    info: function() {
      var args = Array.prototype.slice.call(arguments);
      sendMessage('aniways_logger', JSON.stringify(['info'].concat(args)));
    },
    warn: function() {
      var args = Array.prototype.slice.call(arguments);
      sendMessage('aniways_logger', JSON.stringify(['warn'].concat(args)));
    },
    error: function() {
      var args = Array.prototype.slice.call(arguments);
      sendMessage('aniways_logger', JSON.stringify(['error'].concat(args)));
    },
    debug: function() {
      var args = Array.prototype.slice.call(arguments);
      sendMessage('aniways_logger', JSON.stringify(['debug'].concat(args)));
    }
  };

  // 2. HTTP Bridge
  function httpRequest(options) {
    return new Promise(function(resolve, reject) {
      var id = nextId();
      global.__aniways_callbacks[id] = { resolve: resolve, reject: reject };
      var payload = Object.assign({}, options, { id: id });
      sendMessage('aniways_http', JSON.stringify(payload));
    });
  }

  // 3. Crypto Bridge
  function cryptoCall(action, payload) {
    return new Promise(function(resolve, reject) {
      var id = nextId();
      global.__aniways_callbacks[id] = { resolve: resolve, reject: reject };
      sendMessage('aniways_crypto', JSON.stringify({
        id: id,
        action: action,
        payload: payload
      }));
    });
  }

  global.aniways = {
    http: {
      request: httpRequest,
      get: function(url, opts) {
        return httpRequest(Object.assign({ method: 'GET', url: url }, opts || {}));
      },
      post: function(url, body, opts) {
        return httpRequest(Object.assign({ method: 'POST', url: url, body: body }, opts || {}));
      }
    },
    crypto: {
      aesDecryptCbc: function(ciphertext, key, iv) {
        return cryptoCall('aesDecryptCbc', { ciphertext: ciphertext, key: key, iv: iv });
      },
      hmacSha256: function(data, key, encoding) {
        return cryptoCall('hmacSha256', { data: data, key: key, encoding: encoding || 'hex' });
      },
      base64UrlEncode: function(str) {
        return cryptoCall('base64UrlEncode', { input: str });
      },
      base64UrlDecode: function(str) {
        return cryptoCall('base64UrlDecode', { input: str });
      },
      md5: function(str) {
        return cryptoCall('md5', { input: str });
      },
      sha256: function(str) {
        return cryptoCall('sha256', { input: str });
      }
    }
  };

  // 4. Fetch API Polyfill
  global.fetch = function(url, options) {
    options = options || {};
    var method = (options.method || 'GET').toUpperCase();
    var headers = options.headers || {};
    var body = options.body;

    return httpRequest({
      url: url,
      method: method,
      headers: headers,
      body: body
    }).then(function(res) {
      return {
        ok: res.status >= 200 && res.status < 300,
        status: res.status,
        statusText: res.statusText || 'OK',
        url: res.url || url,
        headers: {
          get: function(key) {
            if (!res.headers) return null;
            var lower = key.toLowerCase();
            for (var k in res.headers) {
              if (k.toLowerCase() === lower) return res.headers[k];
            }
            return null;
          }
        },
        text: function() {
          return Promise.resolve(res.data || '');
        },
        json: function() {
          try {
            return Promise.resolve(JSON.parse(res.data || '{}'));
          } catch (e) {
            return Promise.reject(e);
          }
        }
      };
    });
  };

  // 5. Extension Registry
  global.__aniways_extensions = {};
  global.registerExtension = function(extension) {
    if (!extension || !extension.id) {
      throw new Error('Extension must provide an id.');
    }
    global.__aniways_extensions[extension.id] = extension;
    console.log('[Aniways] Registered extension: ' + extension.name + ' (' + extension.id + ') v' + extension.version);
  };

})(typeof globalThis !== 'undefined' ? globalThis : this);
''';
}

