import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Splash screen shown when the application starts.
///
/// Checks for a saved session:
/// - Valid session -> HomeScreen
/// - No valid session -> LoginScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  Timer? _sessionTimer;

  static const Color kSplashDark = Color(0xFF0D3F8A);
  static const Color kSplashMid = Color(0xFF2C6CE0);
  static const Color kSplashLight = Color(0xFF82C9FF);

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------------------
    // Fade animation
    // ------------------------------------------------------------
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);

    _animCtrl.forward();

    // ------------------------------------------------------------
    // Check session after splash is visible
    // ------------------------------------------------------------
    _sessionTimer = Timer(const Duration(milliseconds: 1500), _checkSession);
  }

  // ============================================================
  // CHECK SESSION
  // ============================================================

  Future<void> _checkSession() async {
    try {
      final session = await ApiService.getUserSession();

      if (!mounted) return;

      // Let the current frame finish before navigation.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      final String token = session?['token']?.toString() ?? '';

      if (token.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'HomeScreen'),
            builder: (_) {
              return HomeScreen(
                userName:
                    session?['userName']?.toString() ??
                    session?['userId']?.toString() ??
                    'User',
                userEmail: session?['userEmail']?.toString() ?? '',
              );
            },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/login'),
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Splash session check error: $e');

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/login'),
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Flutter Web can briefly report a tiny viewport
          // during startup or browser resizing.
          if (constraints.maxWidth < 20 || constraints.maxHeight < 20) {
            return const SizedBox.shrink();
          }

          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final bool isMobile = width < 600;
          final bool isTablet = width >= 600 && width < 1000;

          // ------------------------------------------------------
          // Responsive values
          // ------------------------------------------------------

          final double logoSize = isMobile
              ? 118
              : isTablet
              ? 140
              : 158;

          final double iconSize = isMobile
              ? 66
              : isTablet
              ? 76
              : 88;

          final double titleSize = isMobile
              ? 26
              : isTablet
              ? 30
              : 32;

          final double subtitleSize = isMobile ? 14 : 16;

          final double sidePadding = isMobile ? 20 : 32;

          // ------------------------------------------------------
          // Background
          // ------------------------------------------------------

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kSplashDark, kSplashMid, kSplashLight],
                stops: [0.0, 0.45, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),

            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: sidePadding,
                    vertical: 24,
                  ),

                  child: SizedBox(
                    width: width > 600 ? 600 : width,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: height > 48 ? height - 48 : 0,
                      ),

                      child: Center(
                        child: FadeTransition(
                          opacity: _fadeAnim,

                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,

                            children: [
                              // ==================================================
                              // APP LOGO
                              // ==================================================
                              Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,

                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.55),
                                    width: 2.5,
                                  ),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 25,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),

                                child: Icon(
                                  Icons.directions_car_rounded,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ==================================================
                              // APP NAME
                              // ==================================================
                              Text(
                                'MY AUTOSHOP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.5,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ==================================================
                              // SUBTITLE
                              // ==================================================
                              //
                              // IMPORTANT:
                              // No maxLines / ellipsis here.
                              // This avoids the TextPainter debugSize
                              // assertion seen on Flutter Web.
                              //
                              SizedBox(
                                width: isMobile ? 300 : 420,

                                child: Text(
                                  'A smarter way to manage your car service',
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    color: Colors.white70,
                                    letterSpacing: 0.4,
                                    height: 1.4,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 42),

                              // ==================================================
                              // LOADING
                              // ==================================================
                              const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),

                              const SizedBox(height: 14),

                              const Text(
                                'Loading...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
