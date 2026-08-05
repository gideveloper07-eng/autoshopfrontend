import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(settings: settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showPendingChallanNotifications(
    List<Map<String, dynamic>> rows, {
    int? totalCount,
  }) async {
    await initialize();

    final count = totalCount ?? rows.length;
    if (count == 0) return;

    const androidDetails = AndroidNotificationDetails(
      'pending_challan_channel',
      'Pending Challan',
      channelDescription: 'Notifications for pending challan records',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      id: 1000,
      title: '$count Pending Challan',
      body: 'Open MyAutoShop to review pending challans',
      notificationDetails: details,
    );
  }
}
