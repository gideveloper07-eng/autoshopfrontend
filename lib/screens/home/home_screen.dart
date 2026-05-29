import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
//import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import '../challan/challan_screen.dart';
import '../notification/notification_screen.dart';
import '../settings/settings_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  const HomeScreen({super.key, this.userName = "Student", this.userEmail = ""});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _pendingChallanTimer;
  int unreadCount = 0;
  String utg = "";
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadSecurity();
    loadUnreadCount();
    requestNotificationPermission();
    generateFCMToken();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("NOTIFICATION RECEIVED");

      print(message.notification?.title);

      print(message.notification?.body);
    });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingChallanNotifications();
    });
    _pendingChallanTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkPendingChallanNotifications(),
    );
  }

  Future<void> loadSecurity() async {
    utg = await ApiService.getUTG() ?? "";

    print("USER GROUP : $utg");

    setState(() {
      isLoading = false;
    });
  }

  Future<void> generateFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      print("===============");
      print("FCM TOKEN:");
      print(token);
      print("===============");

      if (token != null) {
        await ApiService.saveFCMToken(token);

        print("FCM TOKEN SAVED");
      }
    } catch (e) {
      print("FCM TOKEN ERROR:");
      print(e);
    }
  }

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    print("NOTIFICATION PERMISSION:");

    print(settings.authorizationStatus);
  }

  Future<void> loadUnreadCount() async {
    final count = await ApiService.getUnreadNotificationCount();

    setState(() {
      unreadCount = count;
    });
  }

  @override
  void dispose() {
    _pendingChallanTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingChallanNotifications();
    }
  }

  Future<void> _checkPendingChallanNotifications() async {
    try {
      final pendingChallans = await ApiService.getChallanRetailIncentive();
      final count = pendingChallans.length;

      if (!mounted || count == 0) return;

      final alreadyNotified = await ApiService.getNotifiedPendingChallanIds();
      final newPendingChallans = pendingChallans.where((row) {
        return !alreadyNotified.contains(_pendingChallanId(row));
      }).toList();

      if (newPendingChallans.isEmpty) return;

      await ApiService.saveNotifiedPendingChallanIds({
        ...alreadyNotified,
        ...pendingChallans.map(_pendingChallanId),
      });
    } catch (e) {
      print("PENDING CHALLAN NOTIFICATION ERROR: $e");
    }
  }

  String _pendingChallanId(Map<String, dynamic> row) {
    final id = row['sp_462']?.toString();
    if (id != null && id.isNotEmpty) return id;

    return [
      row['sp_468']?.toString() ?? '',
      row['sp_469']?.toString() ?? '',
      row['date']?.toString() ?? '',
    ].join('|');
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.logout,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(l10n.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // GET TOKEN
        final token = await ApiService.getToken();

        // CALL LOGOUT API
        await ApiService.logout(token ?? "");
      } catch (e) {
        print("LOGOUT ERROR: $e");
      }

      // CLEAR LOCAL SESSION
      await ApiService.clearSession();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF071426),
                  Color(0xFF0E2542),
                  Color(0xFF42A5F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x441565C0),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "MyAutoShop",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              "Your trusted auto service",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // NOTIFICATION BUTTON
                        Stack(
                          children: [
                            // NOTIFICATION BUTTON
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                );

                                // REFRESH UNREAD COUNT
                                await loadUnreadCount();
                              },

                              child: Container(
                                width: 38,
                                height: 38,

                                margin: const EdgeInsets.only(right: 10),

                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),

                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),

                            // UNREAD BADGE
                            if (unreadCount > 0)
                              Positioned(
                                right: 6,
                                top: 2,

                                child: Container(
                                  padding: const EdgeInsets.all(4),

                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),

                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),

                                  child: Text(
                                    unreadCount > 99
                                        ? "99+"
                                        : unreadCount.toString(),

                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),

                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // SETTINGS BUTTON
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },

                          child: Container(
                            width: 38,
                            height: 38,

                            margin: const EdgeInsets.only(right: 10),

                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),

                            child: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),

                        // LOGOUT BUTTON
                        GestureDetector(
                          onTap: _logout,

                          child: Container(
                            width: 38,
                            height: 38,

                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),

                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome row
                  Row(
                    children: [
                      const Text("👋 ", style: TextStyle(fontSize: 22)),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1A1A2E),
                          ),
                          children: [
                            const TextSpan(text: "Welcome, "),
                            TextSpan(
                              text: widget.userName.split(' ').first,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "What would you like to do today?",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // ── DASHBOARD CARDS ───────────────────────────────────
                  Row(
                    children: [
                      if (utg == "4848C835-2A09-4A80-A7E2-383C95926C54")
                        Expanded(
                          child: _dashCard(
                            icon: Icons.receipt_long_rounded,
                            label: "Challan",
                            subtitle: "View & manage challans",
                            gradient: [
                              const Color(0xFF071426),
                              const Color(0xFF0E2542),
                              const Color(0xFF0A2E5C),
                            ],
                            accentColor: const Color(0xFF82B1FF),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChallanScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon bubble
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                // Arrow chip
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.78),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            // Bottom accent bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
