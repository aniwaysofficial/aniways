import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:aniways/core/logger.dart';

/// Provides cryptographic functions required by video stream extractors
/// (e.g. MegaPlay / Vidstreaming AES-256-CBC, HMAC-SHA256, Base64Url).
class CryptoBridge {
  const CryptoBridge();

  /// Converts a string or list to Uint8List.
  static Uint8List toBytes(dynamic input, {int? targetLength}) {
    Uint8List bytes;
    if (input is List<int>) {
      bytes = Uint8List.fromList(input);
    } else if (input is String) {
      // Check if input is hex
      if (input.length.isEven && RegExp(r'^[0-9a-fA-F]+$').hasMatch(input)) {
        try {
          final result = <int>[];
          for (var i = 0; i < input.length; i += 2) {
            result.add(int.parse(input.substring(i, i + 2), radix: 16));
          }
          bytes = Uint8List.fromList(result);
        } catch (_) {
          bytes = Uint8List.fromList(utf8.encode(input));
        }
      } else {
        bytes = Uint8List.fromList(utf8.encode(input));
      }
    } else {
      bytes = Uint8List(0);
    }

    if (targetLength != null) {
      if (bytes.length == targetLength) return bytes;
      final padded = Uint8List(targetLength);
      final copyLen = bytes.length < targetLength ? bytes.length : targetLength;
      padded.setRange(0, copyLen, bytes);
      return padded;
    }
    return bytes;
  }

  /// AES-256-CBC Decryption.
  ///
  /// Matches Node.js `crypto.createDecipheriv("aes-256-cbc", key, iv)`.
  /// [ciphertext]: Base64 or Hex encoded string.
  /// [key]: UTF-8 or Hex string (padded/truncated to 32 bytes).
  /// [iv]: UTF-8 or Hex string (padded/truncated to 16 bytes).
  String? aesDecryptCbc({
    required dynamic ciphertext,
    required dynamic key,
    required dynamic iv,
  }) {
    try {
      final keyBytes = toBytes(key, targetLength: 32);
      final ivBytes = toBytes(iv, targetLength: 16);

      Uint8List cipherBytes;
      if (ciphertext is List<int>) {
        cipherBytes = Uint8List.fromList(ciphertext);
      } else if (ciphertext is String) {
        var normalized = ciphertext.replaceAll('-', '+').replaceAll('_', '/');
        while (normalized.length % 4 != 0) {
          normalized += '=';
        }
        try {
          cipherBytes = Uint8List.fromList(base64.decode(normalized));
        } catch (_) {
          cipherBytes = toBytes(ciphertext);
        }
      } else {
        return null;
      }

      final encKey = enc.Key(keyBytes);
      final encIv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(
        enc.AES(encKey, mode: enc.AESMode.cbc, padding: 'PKCS7'),
      );

      return encrypter.decrypt(enc.Encrypted(cipherBytes), iv: encIv);
    } catch (e) {
      log.d('CryptoBridge aesDecryptCbc failed: $e');
      return null;
    }
  }

  /// HMAC-SHA256 signature calculation.
  ///
  /// [encoding]: 'base64', 'base64url', or 'hex' (default).
  String hmacSha256({
    required String data,
    required String key,
    String encoding = 'hex',
  }) {
    final hmac = dart_crypto.Hmac(dart_crypto.sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));

    return switch (encoding.toLowerCase()) {
      'base64' => base64.encode(digest.bytes),
      'base64url' => base64Url.encode(digest.bytes).replaceAll('=', ''),
      _ => digest.toString(),
    };
  }

  /// Base64 URL encoder without padding.
  String base64UrlEncode(String input) {
    return base64Url.encode(utf8.encode(input)).replaceAll('=', '');
  }

  /// Base64 URL decoder.
  String base64UrlDecode(String input) {
    var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return utf8.decode(base64.decode(normalized));
  }

  /// MD5 hash of string.
  String md5Hash(String input) {
    return dart_crypto.md5.convert(utf8.encode(input)).toString();
  }

  /// SHA-256 hash of string.
  String sha256Hash(String input) {
    return dart_crypto.sha256.convert(utf8.encode(input)).toString();
  }
}

