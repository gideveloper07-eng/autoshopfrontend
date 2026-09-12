import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';

class ActivityService {
  static String? _deviceInfo;
  static String? _appVersion;

  // Tracks whether initialize() has been called (even if still in progress)
  static bool _initialized = false;

  // Completer so concurrent callers wait for the same init
  static Future<void>? _initFuture;

  /// Initialize once when app starts. Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initFuture ??= _doInitialize();
    return _initFuture;
  }

  static Future<void> _doInitialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;

      final deviceInfoPlugin = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        _deviceInfo = webInfo.userAgent ?? "Web Browser";
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceInfo = "${androidInfo.brand} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceInfo = "${iosInfo.name} ${iosInfo.systemVersion}";
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        _deviceInfo = "Windows ${windowsInfo.computerName}";
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        _deviceInfo = "macOS ${macInfo.model}";
      } else {
        _deviceInfo = "Unknown Device";
      }

      print("ActivityService — Device Info: $_deviceInfo");
      print("ActivityService — App Version: $_appVersion");
    } catch (e) {
      print("ActivityService Initialize Error: $e");
      _deviceInfo = "Unknown Device";
      _appVersion ??= "Unknown";
    } finally {
      _initialized = true;
    }
  }

  /// Log activity. Automatically ensures device info is initialized first.
  static Future<void> logActivity({
    required String activityType,
    required String activityName,
    String? userName,
    String? screenName,
  }) async {
    // Wait for device info if initialize() hasn't completed yet
    if (!_initialized) {
      await initialize();
    }

    try {
      await ApiService.activityLog(
        activityType: activityType,
        activityName: activityName,
        userName: userName,
        screenName: screenName,
        deviceInfo: _deviceInfo,
        appVersion: _appVersion,
      );
    } catch (e) {
      print("Activity Log Error: $e");
    }
  }
}
