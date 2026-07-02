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
// import 'package:screen_protector/screen_protector.dart'; // Temporarily disabled

import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chat/challan_chat_dialog.dart';

// ── Global navigator key — lets us navigate from outside widget tree ──────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

/// Shows a local notification for a chat message.
Future<void> _showLocalChatNotification(RemoteMessage message) async {
  // With data-only FCM messages, title/body come from data map, not notification block
  final title = message.notification?.title
      ?? message.data['title']
      ?? message.data['senderName']
      ?? 'New message';
  final body = message.notification?.body
      ?? message.data['body']
      ?? message.data['messageText']
      ?? '';
  final challanId = message.data['challanId'] ?? '';
  final challanNo = message.data['challanNo'] ?? '';

  const androidDetails = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    channelDescription: 'Push notifications for challan chat messages',
    importance: Importance.max,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(sound: 'default'),
  );

  final notifId = challanId.isNotEmpty ? challanId.hashCode.abs() % 100000 : 9999;
  // Store both IDs in payload so tap handler can open correct chat with correct title
  final payload = '$challanId|$challanNo';

  await flutterLocalNotificationsPlugin.show(
    notifId,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

/// Opens the chat dialog for [challanId] using the global navigator.
void _openChatFromNotification(String challanId, {String challanNo = ''}) {
  if (challanId.isEmpty) return;
  final context = navigatorKey.currentContext;
  if (context == null) return;

  navigatorKey.currentState?.push(
    MaterialPageRoute(
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
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // ── INIT LOCAL NOTIFICATIONS ──────────────────────────────────────────
      if (!kIsWeb) {
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
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
            final challanId = parts.isNotEmpty ? parts[0] : '';
            final challanNo = parts.length > 1 ? parts[1] : '';
            _openChatFromNotification(challanId, challanNo: challanNo);
          },
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                'chat_messages',
                'Chat Messages',
                description: 'Push notifications for challan chat messages',
                importance: Importance.max,
                playSound: true,
              ),
            );
      }

      await ActivityService.initialize();

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
  return msg.contains('viewInsets') ||
      msg.contains('ViewOutsets cannot be negative') ||
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
        final challanId = message.data['challanId'] ?? '';
        final challanNo = message.data['challanNo'] ?? '';
        print("NOTIFICATION TAPPED (background): challanId=$challanId challanNo=$challanNo");
        _openChatFromNotification(challanId, challanNo: challanNo);
      });

      // ── App was TERMINATED → tapped notification ─────────────────────
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          final challanId = message.data['challanId'] ?? '';
          final challanNo = message.data['challanNo'] ?? '';
          print("NOTIFICATION TAPPED (terminated): challanId=$challanId challanNo=$challanNo");
          Future.delayed(const Duration(milliseconds: 500), () {
            _openChatFromNotification(challanId, challanNo: challanNo);
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
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1F6AE2),
        brightness: Brightness.light,
      ),
      primaryColor: const Color(0xFF1F6AE2),
      scaffoldBackgroundColor: const Color(0xFFF5F9FF),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE0E0E0),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1F6AE2),
        brightness: Brightness.dark,
      ),
      primaryColor: const Color(0xFF4DB7FF),
      scaffoldBackgroundColor: const Color(0xFF0F1923),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardColor: const Color(0xFF1A2535),
      dividerColor: const Color(0xFF2A3A4A),
    );
  }
}
