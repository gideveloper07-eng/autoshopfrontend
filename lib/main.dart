import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import 'services/activity_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:screen_protector/screen_protector.dart'; // Temporarily disabled
import 'cache/hive_service.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/challan_chat_dialog.dart';
import 'screens/chat/chat_requests_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'package:college_app/database/chat_database.dart';
import 'package:college_app/chat/services/connectivity_service.dart';
import 'services/festival_service.dart';

// ── Global navigator key — lets us navigate from outside widget tree ──────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final AppRouteObserver appRouteObserver = AppRouteObserver();

// ── Local notifications plugin instance ───────────────────────────────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Called when a FCM message arrives while the app is TERMINATED or in background.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Show a local notification so it appears in the system tray
  await _showLocalChatNotification(message);
}
/// Shows a local notification for any incoming FCM message.
/// Routes to the correct notification channel based on message type.
Future<void> _showLocalChatNotification(RemoteMessage message) async {
  final title =
      message.notification?.title ??
      message.data['title'] ??
      message.data['senderName'] ??
      'New message';
  final body =
      message.notification?.body ??
      message.data['body'] ??
      message.data['messageText'] ??
      '';

  final type = message.data['type'] ?? '';
  final challanId = message.data['challanId'] ?? '';
  final challanNo = message.data['challanNo'] ?? '';

  // Challan status notifications use their own channel
  final bool isChallanStatus =
      type == 'CHALLAN_APPROVED' || type == 'CHALLAN_REJECTED';

  final androidDetails = AndroidNotificationDetails(
    isChallanStatus ? 'challan_notifications' : 'chat_messages',
    isChallanStatus ? 'Challan Notifications' : 'Chat Messages',
    channelDescription: isChallanStatus
        ? 'Notifications for challan approval and rejection'
        : 'Push notifications for challan chat messages',
    importance: Importance.max,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('notification'),
  );

  final notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(sound: 'default'),
  );

  // Encode full data as payload so tap handler knows what to open
  final payload = '$type|$challanId|$challanNo';
  final notifId = (type + challanId).hashCode.abs() % 100000;

  await flutterLocalNotificationsPlugin.show(
    notifId,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

/// Routes a notification tap to the correct screen based on type.
void _handleNotificationData(Map<String, dynamic> data) {
  final type = data['type'] ?? '';
  final challanId = data['challanId'] ?? '';
  final challanNo = data['challanNo'] ?? '';

  if (type == 'CHALLAN_APPROVED' || type == 'CHALLAN_REJECTED') {
    // Navigate to notification screen so user sees the approval/rejection
    _openNotificationScreen();
  } else if (type == 'CHAT_REQUEST') {
    // Navigate to chat requests screen so user can accept/reject
    _openChatRequestsScreen();
  } else if (challanId.isNotEmpty) {
    // Chat message — open the challan chat
    _openChatFromNotification(challanId, challanNo: challanNo);
  }
}

/// Opens the Chat Requests screen.
void _openChatRequestsScreen() {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'ChatRequestsScreen'),
      builder: (_) => const ChatRequestsScreen(),
    ),
  );
}

/// Opens the Notification screen.
void _openNotificationScreen() {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'NotificationScreen'),
      builder: (_) => const NotificationScreen(),
    ),
  );
}

/// Opens the chat dialog for [challanId] using the global navigator.
void _openChatFromNotification(String challanId, {String challanNo = ''}) {
  if (challanId.isEmpty) return;
  final context = navigatorKey.currentContext;
  if (context == null) return;

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'ChallanChatDialog'),
      builder: (_) => ChallanChatDialog(
        challanId: challanId,
        challanNo: challanNo.isNotEmpty ? challanNo : challanId,
      ),
    ),
  );
}

void main() {
  // runZonedGuarded must wrap EVERYTHING including ensureInitialized,
  // so that Flutter bindings and runApp are in the same zone.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (!kIsWeb) {
        await ChatDatabase.instance.database;
      }

      await ConnectivityService.instance.initialize();

      await Hive.initFlutter();

      await HiveService.init();

      // ── Install error handler IMMEDIATELY after binding init ────────────
      // This must be the very first thing so it catches viewport errors that
      // fire during Firebase init and the first frame render.
      FlutterError.onError = (FlutterErrorDetails details) {
        if (_isKnownEngineNoise(details.exceptionAsString())) return;
        FlutterError.presentError(details);
      };

      // Disable screenshots for mobile and tablet (Android only)
      if (!kIsWeb) {
        try {
          print("Screenshot blocking enabled via native Android code");
        } catch (e) {
          print("Error enabling screenshot blocking: $e");
        }
      }

      try {
        // WEB - Initialize Firebase with minimal delay for first paint
        if (kIsWeb) {
          // On web, defer Firebase init slightly to let first frame render
          await Future.delayed(const Duration(milliseconds: 50));
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyAWBceq-JXxrWuILWk0rhy6CjpC7o3jS1A",
              appId: "1:754396208118:web:6859824d9b00b2694545d7",
              messagingSenderId: "754396208118",
              projectId: "myautoshop-394f2",
              storageBucket: "myautoshop-394f2.firebasestorage.app",
              authDomain: "myautoshop-394f2.firebaseapp.com",
            ),
          );
        } else {
          // ANDROID / IOS - Initialize immediately
          await Firebase.initializeApp();
        }
        print("FIREBASE INITIALIZED");
      } catch (e) {
        print("FIREBASE INIT ERROR:");
        print(e);
      }

      // ── REGISTER BACKGROUND MESSAGE HANDLER ──────────────────────────────
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // ── INIT LOCAL NOTIFICATIONS ──────────────────────────────────────────
      if (!kIsWeb) {
        const androidInit = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const iosInit = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        await flutterLocalNotificationsPlugin.initialize(
          const InitializationSettings(android: androidInit, iOS: iosInit),
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            final payload = response.payload ?? '';
            final parts = payload.split('|');
            // payload format: 'TYPE|challanId|challanNo'
            final type = parts.isNotEmpty ? parts[0] : '';
            final challanId = parts.length > 1 ? parts[1] : '';
            final challanNo = parts.length > 2 ? parts[2] : '';
            _handleNotificationData({
              'type': type,
              'challanId': challanId,
              'challanNo': challanNo,
            });
          },
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                'chat_messages',
                'Chat Messages',
                description: 'Push notifications for challan chat messages',
                importance: Importance.max,
                playSound: true,
              ),
            );

        // Challan approval / rejection channel
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                'challan_notifications',
                'Challan Notifications',
                description:
                    'Notifications for challan approval and rejection status',
                importance: Importance.max,
                playSound: true,
              ),
            );
      }

      await ActivityService.initialize();

      // Initialize festival service with real-time data
      await FestivalService.initializeWithApi();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MyApp(),
        ),
      );
    },
    // ── Uncaught async / zone errors ────────────────────────────────────────
    (Object error, StackTrace stack) {
      if (_isKnownEngineNoise(error.toString())) return;
      if (kDebugMode) debugPrint('Unhandled error: $error');
    },
  );
}

/// Returns true for Flutter Web engine assertion errors that are caused by
/// Chrome DevTools viewport resizing — not real app bugs.
bool _isKnownEngineNoise(String msg) {
  return msg.contains('ViewOutsets cannot be negative') ||
      msg.contains('physicalSize') ||
      msg.contains('Zone mismatch');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      // ── App FOREGROUND: show local notification ──────────────────────
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("FCM FOREGROUND: ${message.notification?.title}");
        _showLocalChatNotification(message);
      });

      // ── App BACKGROUND → tapped notification ────────────────────────
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final type = message.data['type'] ?? '';
        final challanId = message.data['challanId'] ?? '';
        final challanNo = message.data['challanNo'] ?? '';
        print(
          "NOTIFICATION TAPPED (background): type=$type challanId=$challanId",
        );
        _handleNotificationData({
          'type': type,
          'challanId': challanId,
          'challanNo': challanNo,
        });
      });

      // ── App was TERMINATED → tapped notification ─────────────────────
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          final type = message.data['type'] ?? '';
          final challanId = message.data['challanId'] ?? '';
          final challanNo = message.data['challanNo'] ?? '';
          print(
            "NOTIFICATION TAPPED (terminated): type=$type challanId=$challanId",
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleNotificationData({
              'type': type,
              'challanId': challanId,
              'challanNo': challanNo,
            });
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      title: 'MyAutoShop',

      // Theme
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),

      // Localization configuration
      locale: languageProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LanguageProvider.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return const Locale('en');
      },

      initialRoute: '/',
      navigatorObservers: [appRouteObserver],
      builder: (context, child) {
        // No manual MediaQuery override needed.
        // WindowCompat.setDecorFitsSystemWindows(false) in MainActivity.kt
        // makes Flutter receive live insets from the OS on all devices.
        // Flutter's own Scaffold + resizeToAvoidBottomInset handles the
        // keyboard correctly on every phone (S25 Ultra, older Androids, iOS).
        return ChatBubbleOverlay(
          routeObserver: appRouteObserver,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1F6AE2),
      onPrimary: Colors.white,
      secondary: Color(0xFF4DB7FF),
      onSecondary: Colors.white,
      error: Color(0xFFE53935),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF10253F),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: const Color(0xFF1F6AE2),
      scaffoldBackgroundColor: const Color(0xFFF5F9FF),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE0E0E0),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF10253F),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1F6AE2)),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFF10253F),
        iconColor: Color(0xFF1F6AE2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF1F6AE2)
              : Colors.grey.shade400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF1F6AE2).withOpacity(0.4)
              : Colors.grey.shade300,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF4DB7FF),
      onPrimary: Color(0xFF003258),
      secondary: Color(0xFF8ED2FF),
      onSecondary: Color(0xFF003258),
      error: Color(0xFFEF5350),
      onError: Colors.white,
      surface: Color(0xFF1A2535),
      onSurface: Color(0xFFE8EDF5),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: const Color(0xFF4DB7FF),
      scaffoldBackgroundColor: const Color(0xFF0F1923),
      cardColor: const Color(0xFF1A2535),
      dividerColor: const Color(0xFF2A3A4A),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE8EDF5),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A2535),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF4DB7FF)),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFE8EDF5),
        iconColor: Color(0xFF4DB7FF),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF4DB7FF)
              : Colors.grey.shade600,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF4DB7FF).withOpacity(0.4)
              : Colors.grey.shade800,
        ),
      ),
    );
  }
}

class AppRouteObserver extends NavigatorObserver with ChangeNotifier {
  String? currentRouteName = '/';
  bool _showChatBubble = false;

  bool get showChatBubble => _showChatBubble;

  void _setRoute(Route<dynamic>? route) {
    final routeName = route?.settings.name;
    currentRouteName = routeName;

    if (routeName == '/' ||
        routeName == '/login' ||
        routeName == '/dealership' ||
        routeName == 'ChallanEditDetailsScreen' ||
        routeName == 'ChatListScreen' ||
        routeName == 'DirectChatScreen' ||
        routeName == 'GroupChatScreen' ||
        routeName == 'ChallanChatDialog' ||
        routeName == 'NewChatScreen') {
      _showChatBubble = false;
    } else if (routeName != null) {
      _showChatBubble = true;
    }

    notifyListeners();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setRoute(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setRoute(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _setRoute(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setRoute(previousRoute);
    super.didRemove(route, previousRoute);
  }
}

class ChatBubbleOverlay extends StatelessWidget {
  final AppRouteObserver routeObserver;
  final Widget child;

  const ChatBubbleOverlay({
    super.key,
    required this.routeObserver,
    required this.child,
  });

  void _openChat() {
    if (routeObserver.currentRouteName == 'ChatListScreen') return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ChatListScreen'),
        builder: (_) => const ChatListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedBuilder(
          animation: routeObserver,
          builder: (context, _) {
            if (!routeObserver.showChatBubble) {
              return const SizedBox.shrink();
            }

            final isCompact = MediaQuery.sizeOf(context).width < 600;
            final isChallanDetails =
                routeObserver.currentRouteName == 'ChallanEditDetailsScreen';
            final isHomeScreen =
                routeObserver.currentRouteName == 'HomeScreen';
            final bubbleSize = isCompact ? 56.0 : 64.0;
            final bottomOffset = isChallanDetails
                ? 92.0
                : isHomeScreen && isCompact
                    ? 90.0
                    : 18.0;

            return Positioned(
              left: isCompact && !isChallanDetails ? 18 : null,
              right: isCompact && !isChallanDetails ? null : 18,
              bottom: bottomOffset,
              child: SafeArea(
                minimum: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: Colors.transparent,
                  child: Semantics(
                    button: true,
                    label: 'Open chat',
                    child: InkWell(
                      onTap: _openChat,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: bubbleSize,
                        height: bubbleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1F7BFF), Color(0xFF055DFF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B63FF).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
