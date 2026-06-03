import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

/// Helper class to manage screenshot blocking across the application
class ScreenshotBlocker {
  static bool _isBlocked = false;

  /// Enable screenshot blocking
  /// Works on Android and iOS (with native implementation)
  static Future<void> enableScreenshotBlocking() async {
    if (kIsWeb) {
      // Screenshot blocking is not supported on web
      if (kDebugMode) {
        print('Screenshot blocking is not available on web platform');
      }
      return;
    }

    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      _isBlocked = true;
      if (kDebugMode) {
        print('Screenshot blocking enabled successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error enabling screenshot blocking: $e');
      }
    }
  }

  /// Disable screenshot blocking
  /// Use this if you need to temporarily allow screenshots
  static Future<void> disableScreenshotBlocking() async {
    if (kIsWeb) {
      return;
    }

    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      _isBlocked = false;
      if (kDebugMode) {
        print('Screenshot blocking disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disabling screenshot blocking: $e');
      }
    }
  }

  /// Check if screenshot blocking is currently enabled
  static bool get isBlocked => _isBlocked;

  /// Toggle screenshot blocking on/off
  static Future<void> toggleScreenshotBlocking() async {
    if (_isBlocked) {
      await disableScreenshotBlocking();
    } else {
      await enableScreenshotBlocking();
    }
  }
}
