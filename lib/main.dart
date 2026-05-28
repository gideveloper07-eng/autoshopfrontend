import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/language_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  try {

    // WEB
    if (kIsWeb) {

      await Firebase.initializeApp(

        options: const FirebaseOptions(

          apiKey:
              "AIzaSyAWBceq-JXxrWuILWk0rhy6CjpC7o3jS1A",

          appId:
              "1:754396208118:web:6859824d9b00b2694545d7",

          messagingSenderId:
              "754396208118",

          projectId:
              "myautoshop-394f2",

          storageBucket:
              "myautoshop-394f2.firebasestorage.app",

          authDomain:
              "myautoshop-394f2.firebaseapp.com",
        ),
      );

    } else {

      // ANDROID / IOS
      await Firebase.initializeApp();
    }

    print(
      "FIREBASE INITIALIZED"
    );

  } catch (e) {

    print(
      "FIREBASE INIT ERROR:"
    );

    print(e);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(

      debugShowCheckedModeBanner: false,

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

        colorScheme:
            ColorScheme.fromSeed(

          seedColor:
              const Color(0xFF8B1E3F),

          brightness:
              Brightness.light,
        ),

        primaryColor:
            const Color(0xFF8B1E3F),

        scaffoldBackgroundColor:
            Colors.white,

        textTheme:
            GoogleFonts.poppinsTextTheme(),

        appBarTheme:
            const AppBarTheme(

          elevation: 0,

          centerTitle: true,

          backgroundColor:
              Colors.transparent,

          foregroundColor:
              Colors.black,
        ),
      ),

      initialRoute: '/',

      routes: {

        '/':
            (_) => const SplashScreen(),

        '/login':
            (_) => const LoginScreen(),
      },
    );
  }
}