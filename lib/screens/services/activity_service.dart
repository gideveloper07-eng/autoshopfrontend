import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';

class ActivityService {
  static String? _deviceInfo;
  static String? _appVersion;

  /// Initialize once when app starts
  static Future<void> initialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      _appVersion = packageInfo.version;

      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;

        _deviceInfo = webInfo.userAgent ?? "Web Browser";
      } else {
        final androidInfo = await deviceInfo.androidInfo;

        _deviceInfo = "${androidInfo.brand} ${androidInfo.model}";
      }

      print("Device Info: $_deviceInfo");
      print("App Version: $_appVersion");
    } catch (e) {
      print("ActivityService Initialize Error: $e");
    }
  }

  /// Log activity
  static Future<void> logActivity({
    required String activityType,
    required String activityName,
    String? userName,
    String? screenName,
  }) async {
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
