import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
//import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import '../challan/challan_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/challan_chat_dialog.dart';
import '../chat/group_chat_screen.dart';
import '../notification/notification_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/dealership_selector_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../theme/app_colors.dart';
import '../../services/activity_service.dart';
import 'package:intl/intl.dart';
import '../chat/task_dashboard_screen.dart';

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
  int _todayBooking = 0;
  int _todaySale = 0;
  List<dynamic> _accessibleDatabases = []; // â† for switch company button
  String _currentCompanyName = ""; // â† shown in header subtitle
  bool _webPermissionRequested = false;
  bool _showWelcome = true; // hides after 5 s // â† request once on first web tap

  // â”€â”€ Chat preview state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Map<String, dynamic>> _previewChallans = [];
  final Map<String, _HomeChatMeta> _previewMeta = {};
  List<dynamic> _previewGroups = [];
  bool _chatPreviewLoading = false;

  static const Color _chatGreen = Color(0xFF075E54);

  @override
  void initState() {
    super.initState();
    ActivityService.logActivity(
      activityType: "SCREEN",
      activityName: "HomeScreen",
      screenName: "HomeScreen",
    );

    // Stagger all initialization to prevent forced reflow violations
    // Load security info first (needed for UI rendering)
    loadSecurity();

    // Stagger other startup API calls with increased delays to reduce
    // simultaneous JavaScript thread operations on Flutter Web
    Future.delayed(const Duration(milliseconds: 150), loadUnreadCount);
    Future.delayed(const Duration(milliseconds: 300), loadDashboardStats);
    Future.delayed(const Duration(milliseconds: 450), _loadChatPreview);
    Future.delayed(const Duration(milliseconds: 600), _loadCompanyInfo);

    // Defer Firebase operations to after initial paint
    Future.delayed(const Duration(milliseconds: 750), () {
      // On mobile: request immediately. On Web: Chrome requires a user gesture
      // first, so we defer until after the first frame interaction.
      if (!kIsWeb) {
        requestNotificationPermission();
      }
      generateFCMToken();
    });
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
    // Hide welcome message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showWelcome = false);
    });
  }

  Future<void> loadDashboardStats() async {
    final stats = await ApiService.getDashboardStats();
    if (mounted) {
      setState(() {
        _todayBooking = stats['todayBooking'] ?? 0;
        _todaySale = stats['todaySale'] ?? 0;
      });
    }
  }

  // â”€â”€ Load accessible databases + current company name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _loadCompanyInfo() async {
    final databases = await ApiService.getAccessibleDatabases();
    final session = await ApiService.getUserSession();
    final currentDb = session?['databaseName'] ?? '';

    // Try to find current company name from the accessible list
    String companyName = '';
    for (final db in databases) {
      if ((db['propertydb'] ?? '').toString().toUpperCase() ==
          currentDb.toUpperCase()) {
        companyName = (db['propertyname'] ?? '').toString();
        break;
      }
    }

    if (mounted) {
      setState(() {
        _accessibleDatabases = databases;
        _currentCompanyName = companyName;
      });
    }
  }

  // â”€â”€ Open dealership selector and refresh home on return â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _switchCompany() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DealershipSelectorScreen(fromHome: true),
      ),
    );
    // When user returns (after picking a company), reload everything
    if (!mounted) return;
    _loadCompanyInfo();
    loadDashboardStats();
    _loadChatPreview();
    loadUnreadCount();
  }

  // â”€â”€ Chat preview loader â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _loadChatPreview() async {
    setState(() => _chatPreviewLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getChallanRetailIncentive(),
        ApiService.getMyGroups(),
      ]);

      final challanList = results[0] as List<Map<String, dynamic>>;
      final groupList = results[1] as List<dynamic>;

      if (!mounted) return;
      setState(() {
        // Show up to 3 most recent challans
        _previewChallans = challanList.take(3).toList();
        // Show up to 3 most recent groups
        _previewGroups = groupList.take(3).toList();
        _chatPreviewLoading = false;
      });

      // Load last message + unread for each preview challan
      for (final c in _previewChallans) {
        final challanId = c['sp_462']?.toString() ?? '';
        if (challanId.isEmpty) continue;
        final msgs = await ApiService.getChatMessages(challanId);
        final unread = 0; //await ApiService.getUnreadChatCount(challanId);
        String lastMsg = '';
        String lastTime = '';
        if (msgs.isNotEmpty) {
          final last = msgs.last;
          lastMsg = last['MessageText']?.toString() ?? '';
          if ((last['MessageType']?.toString() ?? 'TEXT') == 'DOCUMENT') {
            lastMsg =
                'ðŸ“„ ${last['DocumentType'] ?? ''} #${last['DocumentNo'] ?? ''}';
          }
          lastTime = last['MessageTime']?.toString() ?? '';
        }
        if (mounted) {
          setState(() {
            _previewMeta[challanId] = _HomeChatMeta(
              lastMessage: lastMsg,
              lastTime: lastTime,
              unreadCount: unread,
            );
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _chatPreviewLoading = false);
    }
  }

  String _fmtTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return DateFormat('hh:mm a').format(dt);
      }
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return '';
    }
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
    _removeAccountOverlay();
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
              backgroundColor: AppColors.primary,
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
        final token = await ApiService.getToken();

        // LOG USER ACTIVITY
        await ActivityService.logActivity(
          activityType: "LOGOUT",
          activityName: "User Logout",

          userName: await ApiService.getUserName(),
          screenName: "HomeScreen",
        );

        // YOUR EXISTING LOGOUT API
        await ApiService.logout(token ?? "");
      } catch (e) {
        print("LOGOUT ERROR: $e");
      }

      await ApiService.clearSession();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  // â”€â”€ Reusable square icon button for the header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _headerIconBtn(IconData icon, {EdgeInsets margin = EdgeInsets.zero}) {
    return Container(
      width: 36,
      height: 36,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  // â”€â”€ Account top dropdown overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  OverlayEntry? _accountOverlay;

  void _showAccountSheet() {
    if (_accountOverlay != null) {
      _removeAccountOverlay();
      return;
    }
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final entry = OverlayEntry(
      builder: (ctx) => _AccountDropdown(
        userName: widget.userName,
        userEmail: widget.userEmail,
        companyName: _currentCompanyName,
        isDark: themeProvider.isDark,
        onToggleTheme: () {
          themeProvider.toggleTheme();
          // Rebuild overlay to reflect new toggle state
          _accountOverlay?.markNeedsBuild();
        },
        onClose: _removeAccountOverlay,
        onSettings: () {
          _removeAccountOverlay();
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'SettingsScreen'),
              builder: (_) => const SettingsScreen(),
            ),
          );
        },
        onLogout: () {
          _removeAccountOverlay();
          _logout();
        },
      ),
    );
    _accountOverlay = entry;
    Overlay.of(context).insert(entry);
  }

  void _removeAccountOverlay() {
    _accountOverlay?.remove();
    _accountOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.vibrantGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowPrimary,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // â”€â”€ Single Row: car icon | app name | notification â”€â”€â”€â”€â”€â”€
                    Row(
                      children: [
                        // Car icon â€” opens account dropdown
                        GestureDetector(
                          onTap: _showAccountSheet,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // App name + company subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "MyAutoShop",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  height: 1.1,
                                ),
                              ),
                              if (_currentCompanyName.isNotEmpty)
                                Text(
                                  _currentCompanyName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.75),
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Switch pill (if multiple companies)
                        if (_accessibleDatabases.length > 1) ...[
                          GestureDetector(
                            onTap: _switchCompany,
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Switch",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        // Notification bell
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (kIsWeb && !_webPermissionRequested) {
                                  _webPermissionRequested = true;
                                  await requestNotificationPermission();
                                }
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(
                                      name: 'NotificationScreen',
                                    ),
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                );
                                await loadUnreadCount();
                              },
                              child: _headerIconBtn(Icons.notifications),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 4,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 99
                                        ? "99+"
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // â”€â”€ BODY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome banner — visible for 5 s after login
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: _showWelcome
                        ? Column(
                            key: const ValueKey('welcome'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text("👋 ", style: TextStyle(fontSize: 22)),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                      children: [
                                        const TextSpan(text: "Welcome, "),
                                        TextSpan(
                                          text: widget.userName.split(' ').first,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('hidden')),
                  ),

                  // â”€â”€ TODAY STATS ROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.bookmark_added_rounded,
                          label: "Today Booking",
                          value: _todayBooking.toString(),
                          gradient: const [
                            Color(0xFF0A3D8F),
                            Color(0xFF1565C0),
                            Color(0xFF1E88E5),
                          ],
                          accentColor: const Color(0xFF82CFFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.sell_rounded,
                          label: "Today Sale",
                          value: _todaySale.toString(),
                          gradient: const [
                            Color(0xFF1B5E20),
                            Color(0xFF2E7D32),
                            Color(0xFF43A047),
                          ],
                          accentColor: const Color(0xFF80E27E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // â”€â”€ DASHBOARD CARDS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  if (utg == "4848C835-2A09-4A80-A7E2-383C95926C54")
                    Column(
                      children: [
                        // Row 1: Challan + Chat
                        Row(
                          children: [
                            Expanded(
                              child: _dashCard(
                                icon: Icons.receipt_long_rounded,
                                label: "Challan",
                                subtitle: "View & manage challans",
                                gradient: const [
                                  Color(0xFF0A2E5C),
                                  Color(0xFF3B2A96),
                                  Color(0xFF6A4BD8),
                                ],
                                accentColor: AppColors.secondary,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dashCard(
                                icon: Icons.chat_rounded,
                                label: "Chat",
                                subtitle: "Open chats & groups",
                                gradient: const [
                                  Color(0xFF4A148C),
                                  Color(0xFF7B1FA2),
                                  Color(0xFFAB47BC),
                                ],
                                accentColor: Color(0xFFE1BEE7),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ChatListScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 2: Tasks full width
                        _dashCard(
                          icon: Icons.task_alt,
                          label: "Tasks",
                          subtitle: "View assigned tasks",
                          gradient: const [
                            Color(0xFF00695C),
                            Color(0xFF00897B),
                            Color(0xFF26A69A),
                          ],
                          accentColor: Colors.tealAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TaskDashboardScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                  if (utg != "4848C835-2A09-4A80-A7E2-383C95926C54" &&
                      !isLoading)
                    _buildChatPreviewCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Chat preview card (WhatsApp-style on home screen) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildChatPreviewCard() {
    final hasChallans = _previewChallans.isNotEmpty;
    final hasGroups = _previewGroups.isNotEmpty;
    final isEmpty = !hasChallans && !hasGroups;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF075E54).withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // â”€â”€ Header row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'ChatListScreen'),
                  builder: (_) => const ChatListScreen(),
                ),
              );
              _loadChatPreview();
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF075E54), Color(0xFF128C7E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: Radius.circular(
                    (isEmpty || _chatPreviewLoading) ? 20 : 0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Chat",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  // Search icon
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          settings: const RouteSettings(name: 'ChatListScreen'),
                          builder: (_) => const ChatListScreen(),
                        ),
                      );
                      _loadChatPreview();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Three-dot menu
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: "Menu",
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (v) {
                      if (v == 'open') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            settings: const RouteSettings(
                              name: 'ChatListScreen',
                            ),
                            builder: (_) => const ChatListScreen(),
                          ),
                        ).then((_) => _loadChatPreview());
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(
                              Icons.open_in_new,
                              size: 18,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 10),
                            Text("Open Chat", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // â”€â”€ Loading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_chatPreviewLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          // â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          else if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: Colors.grey.withOpacity(0.4),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "No chats yet",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[
            // â”€â”€ Individual Chats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (hasChallans) ...[
              _previewSectionHeader(
                icon: Icons.person_outline,
                label: "Individual Chats",
              ),
              ..._previewChallans.map((challan) {
                final challanId = challan['sp_462']?.toString() ?? '';
                final challanNo = challan['sp_468']?.toString() ?? '';
                final customerName = challan['sp_469']?.toString() ?? '';
                final meta = _previewMeta[challanId];
                final lastMsg = meta?.lastMessage ?? '';
                final unread = meta?.unreadCount ?? 0;
                final timeLabel = _fmtTime(meta?.lastTime);
                final avatarLetter = customerName.isNotEmpty
                    ? customerName[0].toUpperCase()
                    : 'C';

                return _previewChatTile(
                  avatarLetter: avatarLetter,
                  avatarColor: const Color(0xFF075E54),
                  title: customerName.isNotEmpty
                      ? customerName
                      : "Challan #$challanNo",
                  subtitle: lastMsg.isNotEmpty
                      ? lastMsg
                      : "Challan #$challanNo",
                  timeLabel: timeLabel,
                  unreadCount: unread,
                  isLast: _previewChallans.last == challan && !hasGroups,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChallanChatDialog(
                          challanId: challanId,
                          challanNo: challanNo,
                          customerName: customerName,
                        ),
                      ),
                    );
                    _loadChatPreview();
                  },
                );
              }),
            ],

            // â”€â”€ Groups â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (hasGroups) ...[
              _previewSectionHeader(
                icon: Icons.groups_outlined,
                label: "Groups",
              ),
              ..._previewGroups.asMap().entries.map((entry) {
                final idx = entry.key;
                final group = entry.value;
                final groupId = group['GroupId']?.toString() ?? '';
                final groupName = group['GroupName']?.toString() ?? 'Group';
                final memberCount =
                    (group['MemberCount'] as num?)?.toInt() ?? 0;
                final lastMsgTime = group['LastMessageTime']?.toString() ?? '';
                final lastMsg = group['LastMessage']?.toString() ?? '';
                final avatarLetter = groupName.isNotEmpty
                    ? groupName[0].toUpperCase()
                    : 'G';
                final timeLabel = _fmtTime(
                  lastMsgTime.isNotEmpty ? lastMsgTime : null,
                );

                return _previewChatTile(
                  avatarLetter: avatarLetter,
                  avatarColor: const Color(0xFF1565C0),
                  title: groupName,
                  subtitle: lastMsg.isNotEmpty
                      ? lastMsg
                      : "$memberCount member${memberCount == 1 ? '' : 's'}",
                  timeLabel: timeLabel,
                  unreadCount: 0,
                  isLast: idx == _previewGroups.length - 1,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          groupId: groupId,
                          groupName: groupName,
                        ),
                      ),
                    );
                    _loadChatPreview();
                  },
                );
              }),
            ],

            // â”€â”€ "View all" footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: 'ChatListScreen'),
                    builder: (_) => const ChatListScreen(),
                  ),
                );
                _loadChatPreview();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.15)),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "View all chats â†’",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF075E54),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewSectionHeader({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.15)),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF075E54)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF555555),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewChatTile({
    required String avatarLetter,
    required Color avatarColor,
    required String title,
    required String subtitle,
    required String timeLabel,
    required int unreadCount,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: unreadCount > 0 ? _chatGreen : Colors.grey,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? const Color(0xFF222222)
                                : Colors.grey,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _chatGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.88),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale down elements when card is narrow (e.g. three cards on small screen)
          final w = constraints.maxWidth;
          final pad = w < 100
              ? 10.0
              : w < 130
              ? 14.0
              : 20.0;
          final iconSize = w < 100
              ? 30.0
              : w < 130
              ? 38.0
              : 48.0;
          final iconInner = w < 100
              ? 16.0
              : w < 130
              ? 20.0
              : 26.0;
          final arrowSize = w < 100
              ? 20.0
              : w < 130
              ? 24.0
              : 28.0;
          final arrowIconSize = w < 100
              ? 9.0
              : w < 130
              ? 11.0
              : 13.0;
          final labelSize = w < 100
              ? 12.0
              : w < 130
              ? 14.0
              : 17.0;
          final subSize = w < 100
              ? 9.0
              : w < 130
              ? 10.0
              : 11.0;

          return Container(
            padding: EdgeInsets.all(pad),
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
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: iconInner),
                    ),
                    // Arrow chip
                    Container(
                      width: arrowSize,
                      height: arrowSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: arrowIconSize,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w < 100 ? 8 : 18),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: w < 100 ? 2 : 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subSize,
                    color: Colors.white.withOpacity(0.78),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: w < 100 ? 8 : 14),
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
          );
        },
      ),
    );
  }
}

// â”€â”€ Simple holder for per-challan chat metadata shown on home screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HomeChatMeta {
  final String lastMessage;
  final String lastTime;
  final int unreadCount;

  const _HomeChatMeta({
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
  });
}

// â”€â”€ Account dropdown that slides in from the top â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AccountDropdown extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String companyName;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onClose;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _AccountDropdown({
    required this.userName,
    required this.userEmail,
    required this.companyName,
    required this.isDark,
    required this.onToggleTheme,
    required this.onClose,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  State<_AccountDropdown> createState() => _AccountDropdownState();
}

class _AccountDropdownState extends State<_AccountDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  Future<void> _close() async {
    await _ctrl.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.userName.isNotEmpty
        ? widget.userName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : 'U';

    return Material(
      color: Colors.transparent,
      child: Stack(
      children: [
        // Dimmed backdrop â€” tap to close
        FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _close,
            child: Container(
              color: Colors.black.withOpacity(0.45),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        // Side drawer slides in from left
        AnimatedBuilder(
          animation: _slideAnim,
          builder: (_, child) => FractionalTranslation(
            translation: Offset(_slideAnim.value, 0),
            child: child,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 300,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 32,
                    offset: Offset(8, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // â”€â”€ Profile header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Close button top-right
                          Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: _close,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Avatar circle with initials
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.7),
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Name
                          Text(
                            widget.userName.isNotEmpty
                                ? widget.userName
                                : "User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          // Email
                          if (widget.userEmail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.userEmail,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          // Company badge
                          if (widget.companyName.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.companyName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // â”€â”€ Menu items â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                    // Theme toggle
                    GestureDetector(
                      onTap: () {
                        setState(() => _isDark = !_isDark);
                        widget.onToggleTheme();
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _isDark
                                    ? const Color(0xFF1E2D3D)
                                    : const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: _isDark
                                    ? const Color(0xFF90CAF9)
                                    : const Color(0xFFFFA000),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isDark ? "Dark Mode" : "Light Mode",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _isDark
                                        ? "Switch to light theme"
                                        : "Switch to dark theme",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Animated toggle switch
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 44,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _isDark
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey.shade300,
                              ),
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    left: _isDark ? 22 : 2,
                                    top: 2,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                            Divider(height: 1, indent: 72, endIndent: 20, color: Colors.grey.shade100),
                            _DropdownMenuItem(
                              icon: Icons.settings_rounded,
                              iconBg: const Color(0xFFE3F2FD),
                              iconColor: const Color(0xFF1565C0),
                              label: "Settings",
                              subtitle: "App preferences & configuration",
                              onTap: widget.onSettings,
                            ),
                            Divider(height: 1, indent: 72, endIndent: 20, color: Colors.grey.shade100),
                            _DropdownMenuItem(
                              icon: Icons.logout_rounded,
                              iconBg: const Color(0xFFFFEBEE),
                              iconColor: Colors.red.shade600,
                              label: "Logout",
                              subtitle: "Sign out of your account",
                              labelColor: Colors.red.shade600,
                              onTap: widget.onLogout,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }
}

class _DropdownMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? labelColor;

  const _DropdownMenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: labelColor ?? const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use
