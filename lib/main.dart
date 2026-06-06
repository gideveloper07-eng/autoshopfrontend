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
  final title = message.notification?.title ?? message.data['senderName'] ?? 'New message';
  final body = message.notification?.body ?? message.data['messageText'] ?? '';
  final challanId = message.data['challanId'] ?? '';

  const androidDetails = AndroidNotificationDetails(
    'chat_messages',          // must match channelId sent from backend
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

  // Use challanId hash as notification ID so same challan groups together
  final notifId = challanId.isNotEmpty ? challanId.hashCode.abs() % 100000 : 9999;

  await flutterLocalNotificationsPlugin.show(
    notifId,
    title,
    body,
    notificationDetails,
    payload: challanId,  // passed back when user taps notification
  );
}

/// Opens the chat dialog for [challanId] using the global navigator.
void _openChatFromNotification(String challanId) {
  if (challanId.isEmpty) return;
  final context = navigatorKey.currentContext;
  if (context == null) return;

  showDialog(
    context: context,
    builder: (_) => ChallanChatDialog(
      challanId: challanId,
      challanNo: challanId,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable screenshots for mobile and tablet (Android only)
  // Screenshot blocking is now implemented in native Android code (MainActivity.kt)
  if (!kIsWeb) {
    try {
      print("Screenshot blocking enabled via native Android code");
    } catch (e) {
      print("Error enabling screenshot blocking: $e");
    }
  }

  try {
    // WEB
    if (kIsWeb) {
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
      // ANDROID / IOS
      await Firebase.initializeApp();
    }

    print("FIREBASE INITIALIZED");
  } catch (e) {
    print("FIREBASE INIT ERROR:");

    print(e);
  }

  // ── REGISTER BACKGROUND MESSAGE HANDLER ────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── INIT LOCAL NOTIFICATIONS ────────────────────────────────────────────────
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
        // User tapped a local notification — open chat
        final challanId = response.payload ?? '';
        _openChatFromNotification(challanId);
      },
    );

    // Create the Android notification channel for chat messages
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
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
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
        print("NOTIFICATION TAPPED (background): challanId=$challanId");
        _openChatFromNotification(challanId);
      });

      // ── App was TERMINATED → tapped notification ─────────────────────
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          final challanId = message.data['challanId'] ?? '';
          print("NOTIFICATION TAPPED (terminated): challanId=$challanId");
          // Slight delay to ensure navigator is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            _openChatFromNotification(challanId);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

      // Hide debug banner in web
      showPerformanceOverlay: false,

      title: 'MyAutoShop',

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
        // Check if the current device locale is supported
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        // Return English as default
        return const Locale('en');
      },

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1E3F),

          brightness: Brightness.light,
        ),

        primaryColor: const Color(0xFF8B1E3F),

        scaffoldBackgroundColor: Colors.white,

        textTheme: GoogleFonts.poppinsTextTheme(),

        appBarTheme: const AppBarTheme(
          elevation: 0,

          centerTitle: true,

          backgroundColor: Colors.transparent,

          foregroundColor: Colors.black,
        ),
      ),
      // navigatorObservers: [RouteTracker()],
      initialRoute: '/',

      routes: {
        '/': (_) => const SplashScreen(),

        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
