import 'package:flutter/foundation.dart';

/// Helper class to manage screenshot blocking across the application
/// Screenshot blocking is now implemented at the native Android level (MainActivity.kt)
/// This class is kept for future compatibility if dynamic toggling is needed
class ScreenshotBlocker {
  static bool _isBlocked = true; // Always blocked via native code

  /// Enable screenshot blocking
  /// Note: Screenshot blocking is permanently enabled in MainActivity.kt
  static Future<void> enableScreenshotBlocking() async {
    if (kIsWeb) {
      // Screenshot blocking is not supported on web
      if (kDebugMode) {
        print('Screenshot blocking is not available on web platform');
      }
      return;
    }

    // Screenshot blocking is handled at native level in MainActivity.kt
    _isBlocked = true;
    if (kDebugMode) {
      print('Screenshot blocking is enabled via native Android code');
    }
  }

  /// Disable screenshot blocking
  /// Note: Currently not supported as blocking is set at native level
  /// You would need to use MethodChannel to dynamically control this
  static Future<void> disableScreenshotBlocking() async {
    if (kIsWeb) {
      return;
    }

    if (kDebugMode) {
      print('Screenshot blocking cannot be disabled dynamically (set in native code)');
      print('To disable, modify MainActivity.kt and rebuild the app');
    }
  }

  /// Check if screenshot blocking is currently enabled
  static bool get isBlocked => _isBlocked;

  /// Toggle screenshot blocking on/off
  /// Note: Currently not supported dynamically
  static Future<void> toggleScreenshotBlocking() async {
    if (kDebugMode) {
      print('Screenshot blocking is permanently enabled at native level');
    }
  }
}
