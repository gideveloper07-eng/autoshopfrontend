# Screenshot Blocking Implementation Guide

## Overview
This application implements screenshot blocking to prevent users from taking screenshots on both mobile and tablet devices. This security feature protects sensitive information displayed within the app.

## Platform Support

### ✅ Android
- **Fully Supported** via `FLAG_SECURE` window flag
- Prevents screenshots and screen recording
- Works on phones and tablets
- Hides app content in recent apps/task switcher

### ✅ iOS
- **Fully Supported** via native Swift implementation
- Detects screenshot attempts
- Blurs content in app switcher
- Makes window content secure using TextField layer technique

### ❌ Web
- **Not Supported** - Browser security model doesn't allow this
- Users can use browser screenshot tools or OS-level screenshot functionality

## Implementation Details

### 1. Dependencies
Added to `pubspec.yaml`:
```yaml
flutter_windowmanager: ^0.2.0
```

### 2. Main Application Setup (`main.dart`)
Screenshot blocking is enabled globally when the app starts:
```dart
await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
```

### 3. iOS Native Implementation (`AppDelegate.swift`)
- Detects screenshot attempts via notifications
- Adds blur effect when app enters background
- Makes window secure using UITextField layer technique

### 4. Utility Helper (`utils/screenshot_blocker.dart`)
Provides convenient methods to manage screenshot blocking:
- `enableScreenshotBlocking()` - Enable blocking
- `disableScreenshotBlocking()` - Disable blocking (if needed)
- `toggleScreenshotBlocking()` - Toggle on/off
- `isBlocked` - Check current state

## Usage

### Global Blocking (Current Implementation)
Screenshot blocking is enabled by default when the app launches. No additional code needed.

### Conditional Blocking (Optional)
If you need to enable/disable blocking for specific screens:

```dart
import 'package:college_app/utils/screenshot_blocker.dart';

// In your screen's initState or build method
class SensitiveScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    ScreenshotBlocker.enableScreenshotBlocking();
  }

  @override
  void dispose() {
    ScreenshotBlocker.disableScreenshotBlocking();
    super.dispose();
  }
}
```

## Testing

### Android Testing
1. Open the app on an Android device or emulator
2. Try to take a screenshot (Power + Volume Down)
3. You should see a message: "Can't take screenshot due to security policy"
4. Check recent apps - the app preview should be blank/black

### iOS Testing
1. Open the app on an iOS device or simulator
2. Try to take a screenshot (Power + Volume Up on newer devices)
3. Screenshot will be taken but detection is logged
4. Press Home button to background the app
5. Open app switcher - content should be blurred

### Verification Checklist
- [ ] Screenshot blocked on Android phone
- [ ] Screenshot blocked on Android tablet
- [ ] Screenshot detection working on iOS
- [ ] App content blurred in iOS app switcher
- [ ] App content hidden in Android recent apps
- [ ] No impact on app performance

## Security Considerations

### What's Protected
✅ All screens and content within the app  
✅ App preview in task switcher/recent apps  
✅ System screenshot functionality  

### What's NOT Protected
❌ Physical photos of the screen  
❌ Screen recording on jailbroken/rooted devices  
❌ Web version of the app  
❌ Screenshots taken via ADB or development tools  

## Troubleshooting

### Issue: Screenshots still working on Android
**Solution:** 
- Ensure you've run `flutter pub get` after adding the dependency
- Rebuild the app completely: `flutter clean && flutter build apk`
- Check that FLAG_SECURE is being set in main.dart

### Issue: iOS not detecting screenshots
**Solution:**
- Verify AppDelegate.swift has been updated correctly
- Check Xcode console for "Screenshot attempt detected" message
- Ensure iOS deployment target is 11.0 or higher

### Issue: App crashing on startup
**Solution:**
- Check for import errors in main.dart
- Ensure flutter_windowmanager is properly installed
- Run `flutter doctor` to check for issues

## Additional Security Recommendations

1. **Implement User Alerts**: Show a warning when screenshot attempts are detected
2. **Audit Logging**: Log screenshot attempts for security monitoring
3. **User Education**: Inform users about the security policy
4. **Compliance**: Ensure this meets your organization's security requirements

## Related Files
- `lib/main.dart` - Main app initialization with screenshot blocking
- `lib/utils/screenshot_blocker.dart` - Utility helper class
- `ios/Runner/AppDelegate.swift` - iOS native implementation
- `pubspec.yaml` - Package dependencies

## Commands

Install dependencies:
```bash
flutter pub get
```

Build Android APK:
```bash
flutter build apk
```

Build iOS:
```bash
flutter build ios
```

Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

## Version Information
- Implementation Date: June 3, 2026
- Flutter SDK: ^3.11.4
- flutter_windowmanager: ^0.2.0
