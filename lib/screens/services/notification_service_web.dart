import 'dart:html' as html;

class NotificationService {
  static Future<void> initialize() async {
    if (!html.Notification.supported) return;

    if (html.Notification.permission == 'default') {
      await html.Notification.requestPermission();
    }
  }

  static Future<void> showPendingChallanNotifications(
    List<Map<String, dynamic>> rows, {
    int? totalCount,
  }) async {
    await initialize();

    final count = totalCount ?? rows.length;
    if (count == 0 || html.Notification.permission != 'granted') return;

    html.Notification(
      '$count Pending Challan',
      body: 'Open MyAutoShop to review pending challans',
      icon: 'icons/Icon-192.png',
    );
  }
}
