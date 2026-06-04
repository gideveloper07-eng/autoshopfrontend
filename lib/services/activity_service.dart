import 'api_service.dart';

class ActivityService {
  static Future<void> logActivity({
    required String activityType,
    required String activityName,
    String? userId,
    String? userName,
    String? screenName,
  }) async {
    try {
      await ApiService.activityLog(
        activityType: activityType,
        activityName: activityName,
        userName: userName,
        screenName: screenName,
      );
    } catch (e) {
      print('Activity Log Error: $e');
    }
  }
}
