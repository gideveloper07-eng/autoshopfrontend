import 'package:flutter/material.dart';
import 'activity_service.dart';

class RouteTracker extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    final screenName = route.settings.name ?? 'Unknown';

    ActivityService.logActivity(
      activityType: "SCREEN",
      activityName: screenName,
      screenName: screenName,
    );

    super.didPush(route, previousRoute);
  }
}
