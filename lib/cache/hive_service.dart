import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String dashboardBox = 'dashboardBox';
  static const String chatBox = 'chatBox';
  static const String challanBox = 'challanBox';
  static const String notificationBox = 'notificationBox';
  static const String userBox = 'userBox';
  static const String settingsBox = 'settingsBox';

  static Future<void> init() async {
    await Hive.openBox(dashboardBox);
    await Hive.openBox(chatBox);
    await Hive.openBox(challanBox);
    await Hive.openBox(notificationBox);
    await Hive.openBox(userBox);
    await Hive.openBox(settingsBox);
  }
}
