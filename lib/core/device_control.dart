import 'dart:io';
import 'package:flutter/services.dart';
import 'package:aniways/core/logger.dart';

/// Provides platform-level control for system media volume and screen brightness.
class DeviceControl {
  static const _channel =
      MethodChannel('com.aniways.app/device_control');

  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// Returns current system media volume between 0.0 and 1.0.
  static Future<double> getVolume() async {
    if (!_isAndroid) return 0.5;
    try {
      final val = await _channel.invokeMethod<double>('getVolume');
      return (val ?? 0.5).clamp(0.0, 1.0);
    } catch (e) {
      log.w('DeviceControl.getVolume error: $e');
      return 0.5;
    }
  }

  /// Sets system media volume between 0.0 and 1.0.
  static Future<void> setVolume(double volume) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (e) {
      log.w('DeviceControl.setVolume error: $e');
    }
  }

  /// Returns current window or system brightness between 0.0 and 1.0.
  static Future<double> getBrightness() async {
    if (!_isAndroid) return 0.5;
    try {
      final val = await _channel.invokeMethod<double>('getBrightness');
      return (val ?? 0.5).clamp(0.0, 1.0);
    } catch (e) {
      log.w('DeviceControl.getBrightness error: $e');
      return 0.5;
    }
  }

  /// Sets window screen brightness between 0.0 and 1.0.
  static Future<void> setBrightness(double brightness) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('setBrightness', {
        'brightness': brightness.clamp(0.0, 1.0),
      });
    } catch (e) {
      log.w('DeviceControl.setBrightness error: $e');
    }
  }

  /// Resets window brightness override to restore system default brightness.
  static Future<void> resetBrightness() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('resetBrightness');
    } catch (e) {
      log.w('DeviceControl.resetBrightness error: $e');
    }
  }

  /// Ensures that native BetterPlayer static references (textureRegistry, activity)
  /// are valid and attached to the active MainActivity FlutterEngine.
  /// This prevents video playback freezes / timeouts after background workers detach.
  static Future<void> ensureBetterPlayerReady() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('ensureBetterPlayerReady');
    } catch (e) {
      log.w('DeviceControl.ensureBetterPlayerReady error: $e');
    }
  }
}

