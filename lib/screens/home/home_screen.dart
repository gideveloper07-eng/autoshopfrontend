import 'dart:async';
import 'dart:math' as math;
import '../ai/ai_chat_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../services/recurring_task_scheduler.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
//import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import '../challan/challan_screen.dart';
import '../chat/chat_list_screen.dart';
import '../notification/notification_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/dealership_selector_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../theme/app_colors.dart';
import '../../services/activity_service.dart';
import 'package:intl/intl.dart';
import '../chat/task_dashboard_screen.dart';
import '../chat/chat_requests_screen.dart';
import '../dashboard/branchwise_details_screen.dart';
import '../dashboard/pending_delivery_branchwise_screen.dart';
import '../dashboard/sales_comparison_screen.dart';
import '../dashboard/sales_performance_screen.dart';
import '../../widgets/dashboard/dashboard_comparison_card.dart';
import '../../widgets/dashboard/performance_trends_section.dart';
import '../../widgets/festival_banner.dart';
import '../../widgets/daily_quote_widget.dart';
import '../../services/quote_service.dart';
import '../chat/my_contact_requests_screen.dart';
import 'global_task_screen.dart';
import '../../services/festival_service.dart';
import '../../main.dart' show pendingTaskCompletionCount;

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  const HomeScreen({super.key, this.userName = "Student", this.userEmail = ""});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _pendingChallanTimer;
  int unreadCount = 0;
  String utg = "";
  bool isLoading = true;
  int _todayBooking = 0;
  int _yesterdayBooking = 0;
  double _bookingGrowth = 0;

  int _todaySale = 0;
  int _yesterdaySale = 0;
  double _saleGrowth = 0;

  int _pendingDelivery = 0; // pending delivery count

  List<double> _bookingTrend = [];
  List<double> _saleTrend = [];

  // PageController for the stats card swipe (Bookings / Sales / Pending Delivery)
  final PageController _statsPageController = PageController();

  List<dynamic> _accessibleDatabases = []; // â† for switch company button
  String _currentCompanyName = ""; // â† shown in header subtitle
  bool _webPermissionRequested = false;
  bool _showWelcome =
      true; // hides after 5 s // â† request once on first web tap
  // Chat request badge (non-admin only)
  bool _isAdmin = false;
  int _pendingRequestCount = 0;
  late AnimationController _requestBlink;
  late Animation<double> _requestBlinkAnim;

  // â”€â”€ Chat preview state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Map<String, dynamic>> _previewChallans = [];
  final Map<String, _HomeChatMeta> _previewMeta = {};
  List<dynamic> _previewGroups = [];
  bool _chatPreviewLoading = false;

  static const Color _chatGreen = Color(0xFF075E54);

  // ── Assign Task dialog state (used directly from home purple card) ────────
  final _assignTitleCtrl = TextEditingController();
  final _assignDescCtrl = TextEditingController();
  String _assignPriority = 'Medium';
  DateTime? _assignStartDate;
  DateTime? _assignDueDate;
  List<Map<String, dynamic>> _assignUsers = [];
  String? _assignSelectedUserId;
  bool _assignUsersLoaded = false;
  String? _assignFrequency; // null = one-time, 'Weekly', 'Monthly', 'Yearly'

  // Festival banner state
  bool _showFestivalBanner = true;
  Timer? _festivalUpdateTimer;

  // Daily quote state — hidden until dismiss check completes
  bool _showDailyQuote = false;

  @override
  void initState() {
    super.initState();
    // Check if quote was dismissed less than 1 hour ago
    QuoteService.isDismissed().then((dismissed) {
      if (mounted) setState(() => _showDailyQuote = !dismissed);
    });

    // ── Blink animation for chat request icon ──────────────────────────────
    _requestBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false);
    _requestBlinkAnim = CurvedAnimation(
      parent: _requestBlink,
      curve: Curves.easeInOut,
    );

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
    Future.delayed(const Duration(milliseconds: 500), _loadRequestInfo);

    // Process any due recurring tasks scheduled from previous assign-task actions
    Future.delayed(const Duration(milliseconds: 800), () async {
      final created = await RecurringTaskScheduler.processDueSlots();
      if (created > 0) {
        debugPrint(
          'RecurringTaskScheduler: created $created task(s) on home init',
        );
      }
    });

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

    // Initialize periodic festival updates for real-time data
    _festivalUpdateTimer = Timer.periodic(
      const Duration(hours: 24), // Update festival dates daily
      (_) async {
        await FestivalService.schedulePeriodicUpdates();
        if (mounted) {
          setState(() {
            _showFestivalBanner = FestivalService.isTodayFestival();
          });
        }
      },
    );
  }

  /*Future<void> loadDashboardStats() async {
    final stats = await ApiService.getDashboardStats();
    if (mounted) {
      setState(() {
        _todayBooking = stats['todayBooking'] ?? 0;
        _todaySale = stats['todaySale'] ?? 0;
      });
    }
  }*/
  Future<void> loadDashboardStats() async {
    // ── Step 1: Show cached stats immediately ─────────────────────────────
    final cached = await CacheService.getMap(
      CacheService.keyDashboardStats,
      ttlMs: CacheService.ttlDashboard,
    );
    if (cached != null && mounted) {
      _applyDashboardStats(cached);
    }

    // ── Step 2: Fetch fresh from backend ─────────────────────────────────
    final stats = await ApiService.getDashboardStats();
    if (stats.isNotEmpty) {
      await CacheService.setMap(CacheService.keyDashboardStats, stats);
    }
    print("Booking Trend: ${stats['bookingTrend']}");
    print("Sale Trend: ${stats['saleTrend']}");
    if (!mounted) return;
    _applyDashboardStats(stats);
  }

  void _applyDashboardStats(Map<String, dynamic> stats) {
    setState(() {
      _todayBooking = stats["todayBooking"] ?? 0;

      _yesterdayBooking = stats["yesterdayBooking"] ?? 0;

      _bookingGrowth = (stats["bookingGrowth"] ?? 0).toDouble();

      _todaySale = stats["todaySale"] ?? 0;

      _yesterdaySale = stats["yesterdaySale"] ?? 0;

      _saleGrowth = (stats["saleGrowth"] ?? 0).toDouble();

      _bookingTrend = stats['bookingTrend'] != null
          ? List<double>.from(
              (stats['bookingTrend'] as List).map((e) => (e as num).toDouble()),
            )
          : [];

      _saleTrend = stats['saleTrend'] != null
          ? List<double>.from(
              (stats['saleTrend'] as List).map((e) => (e as num).toDouble()),
            )
          : [];

      _pendingDelivery = (stats['pendingDelivery'] as num? ?? 0).toInt();
    });
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
        settings: const RouteSettings(name: '/dealership'),
        builder: (_) => const DealershipSelectorScreen(fromHome: true),
      ),
    );
    // When user returns (after picking a company), clear chat cache and reload everything
    if (!mounted) return;
    // Chat messages/groups/contacts are all company-specific — clear them
    await CacheService.clearChatCache();
    // Also clear company-specific dashboard and challan caches
    await Future.wait([
      CacheService.delete(CacheService.keyDashboardStats),
      CacheService.delete(CacheService.keyChallanList),
      CacheService.delete(CacheService.keyDirectChats),
      CacheService.delete(CacheService.keyGroups),
      CacheService.delete(CacheService.keyMergedUsers),
      CacheService.delete(CacheService.keyContacts),
    ]);
    _loadCompanyInfo();
    loadDashboardStats();
    _loadChatPreview();
    loadUnreadCount();
  }

  // â”€â”€ Chat preview loader â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _loadChatPreview() async {
    // ── Step 1: Show cached preview immediately ──────────────────────────
    final cachedChallans = await CacheService.getListMap(
      CacheService.keyChallanList,
    );
    final cachedGroups = await CacheService.getList(CacheService.keyGroups);
    if ((cachedChallans != null || cachedGroups != null) && mounted) {
      setState(() {
        if (cachedChallans != null) {
          _previewChallans = cachedChallans.take(3).toList();
        }
        if (cachedGroups != null) {
          _previewGroups = cachedGroups.take(3).toList();
        }
        _chatPreviewLoading = false;
      });
    } else {
      setState(() => _chatPreviewLoading = true);
    }

    // ── Step 2: Fetch fresh from backend ─────────────────────────────────
    try {
      final results = await Future.wait([
        ApiService.getChallanRetailIncentive(),
        ApiService.getMyGroups(),
      ]);

      final challanList = results[0] as List<Map<String, dynamic>>;
      final groupList = results[1] as List<dynamic>;

      // Update cache
      await Future.wait([
        CacheService.setListMap(CacheService.keyChallanList, challanList),
        CacheService.setList(CacheService.keyGroups, groupList),
      ]);

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
        // Use cached messages if available to avoid extra network calls
        final cached = await CacheService.getList(
          CacheService.keyChatMessages(challanId),
        );
        final msgs = cached ?? await ApiService.getChatMessages(challanId);
        if (msgs.isNotEmpty && cached == null) {
          await CacheService.setList(
            CacheService.keyChatMessages(challanId),
            msgs,
          );
        }
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

  // ── Chat request info (non-admin only) ──────────────────────────────────
  Future<void> _loadRequestInfo() async {
    final adminFlag = await ApiService.isAdmin();
    if (!adminFlag) {
      final requests = await ApiService.getChatRequests();
      if (mounted) {
        final hasPending = requests.isNotEmpty;
        setState(() {
          _isAdmin = false;
          _pendingRequestCount = requests.length;
        });
        // Start blinking when there are pending requests, stop when none
        if (hasPending) {
          if (!_requestBlink.isAnimating) _requestBlink.repeat(reverse: false);
        } else {
          _requestBlink.stop();
          _requestBlink.value = 1.0;
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = true;
          _pendingRequestCount = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _pendingChallanTimer?.cancel();
    _festivalUpdateTimer?.cancel();
    _requestBlink.dispose();
    _statsPageController.dispose();
    _removeAccountOverlay();
    _assignTitleCtrl.dispose();
    _assignDescCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingChallanNotifications();
      // Check for festival updates when app resumes
      FestivalService.autoRefreshIfNeeded();
      setState(() {
        _showFestivalBanner = FestivalService.isTodayFestival();
      });
      // Re-check quote visibility on resume — quote changes daily at midnight
      QuoteService.isDismissed().then((dismissed) {
        if (mounted) setState(() => _showDailyQuote = !dismissed);
      });
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
      // Clear all cached data on logout so the next user sees a clean state
      await CacheService.clearAll();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/login'),
          builder: (_) => const LoginScreen(),
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.vibrantGradientAdaptive(context),
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
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyContactRequestsScreen(),
                              ),
                            );
                          },
                          child: _headerIconBtn(
                            Icons.people_alt_outlined,
                            margin: const EdgeInsets.only(right: 8),
                          ),
                        ),
                        // Chat request icon (non-admin only)
                        if (!_isAdmin)
                          _ChatRequestIconButton(
                            pendingCount: _pendingRequestCount,
                            animation: _requestBlinkAnim,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatRequestsScreen(),
                                ),
                              );
                              _loadRequestInfo();
                            },
                          ),
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
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                MediaQuery.of(context).size.width >= 600 ? 140 : 100,
              ),
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
                                  const Text(
                                    "👋 ",
                                    style: TextStyle(fontSize: 22),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                      children: [
                                        const TextSpan(text: "Welcome, "),
                                        TextSpan(
                                          text: widget.userName
                                              .split(' ')
                                              .first,
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

                  // Festival banner — shows on festival days
                  if (_showFestivalBanner && FestivalService.isTodayFestival())
                    FestivalBanner(
                      onClose: () {
                        setState(() {
                          _showFestivalBanner = false;
                        });
                      },
                    ),

                  // Daily quote widget
                  if (_showDailyQuote)
                    DailyQuoteWidget(
                      onClose: () {
                        QuoteService.dismiss(); // persist 1-hour hide
                        setState(() {
                          _showDailyQuote = false;
                        });
                      },
                    ),

                  // ── STATS CARDS — swipeable: Bookings / Sales / Pending Delivery ──
                  SizedBox(
                    height: 170,
                    child: PageView(
                      controller: _statsPageController,
                      children: [
                        // ── Page 1: Bookings ──────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: DashboardComparisonCard(
                            compact: true,
                            title: "Bookings",
                            icon: Icons.bookmark_added_rounded,
                            today: _todayBooking,
                            yesterday: _yesterdayBooking,
                            growth: _bookingGrowth,
                            trend: _bookingTrend,
                            gradient: const [
                              Color(0xFF0A3D8F),
                              Color(0xFF1565C0),
                              Color(0xFF1E88E5),
                            ],
                            onTodayTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BranchwiseDetailsScreen(
                                    reportType: "booking",
                                    period: "today",
                                    title: "Today's Booking",
                                  ),
                                ),
                              );
                            },
                            onYesterdayTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BranchwiseDetailsScreen(
                                    reportType: "booking",
                                    period: "yesterday",
                                    title: "Yesterday's Booking",
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // ── Page 2: Sales ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: DashboardComparisonCard(
                            compact: true,
                            title: "Sales",
                            icon: Icons.sell_rounded,
                            today: _todaySale,
                            yesterday: _yesterdaySale,
                            growth: _saleGrowth,
                            trend: _saleTrend,
                            gradient: const [
                              Color(0xFF1B5E20),
                              Color(0xFF2E7D32),
                              Color(0xFF43A047),
                            ],
                            onPerformanceTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SalesPerformanceScreen(),
                                ),
                              );
                            },
                            onComparisonTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SalesComparisonScreen(),
                                ),
                              );
                            },
                            onTodayTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BranchwiseDetailsScreen(
                                    reportType: "sale",
                                    period: "today",
                                    title: "Today's Sale",
                                  ),
                                ),
                              );
                            },
                            onYesterdayTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BranchwiseDetailsScreen(
                                    reportType: "sale",
                                    period: "yesterday",
                                    title: "Yesterday's Sale",
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // ── Page 3: Pending Delivery ──────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PendingDeliveryBranchwiseScreen(),
                              ),
                            ),
                            child: _PendingDeliveryCard(count: _pendingDelivery),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatsPageDots(controller: _statsPageController, count: 3),

                  const SizedBox(height: 24),

                  PerformanceTrendsSection(
                    bookingGrowth: _bookingGrowth,
                    bookingTrend: _bookingTrend,

                    saleGrowth: _saleGrowth,
                    saleTrend: _saleTrend,
                  ),

                  const SizedBox(height: 24),

                  // â”€â”€ DASHBOARD CARDS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  // Admin: Challan + Tasks (assign & view all)
                  if (utg == "4848C835-2A09-4A80-A7E2-383C95926C54")
                    Column(
                      children: [
                        // Row 1: Challan full width
                        _dashCard(
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
                        const SizedBox(height: 12),
                        // Row 2: Task Dashboard (green) — admin only
                        ValueListenableBuilder<int>(
                          valueListenable: pendingTaskCompletionCount,
                          builder: (context, count, _) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _dashCard(
                                  icon: Icons.task_alt,
                                  label: "Task Dashboard Screen",
                                  subtitle: count > 0
                                      ? "$count task${count > 1 ? 's' : ''} completed by user"
                                      : "View assigned tasks",
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
                                        builder: (_) =>
                                            const TaskDashboardScreen(),
                                      ),
                                    );
                                  },
                                ),
                                if (count > 0)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Row 3: Assign Task (purple) — admin only
                        _dashCard(
                          icon: Icons.assignment_ind_rounded,
                          label: "Assign Task",
                          subtitle: "Assign and track task",
                          gradient: const [
                            Color(0xFF4A148C),
                            Color(0xFF6A1B9A),
                            Color(0xFF8E24AA),
                          ],
                          accentColor: Colors.purpleAccent,
                          onTap: () => _showAssignTaskDialog(),
                        ),
                      ],
                    ),

                  // Assign Task card — non-admin only
                  if (utg != "4848C835-2A09-4A80-A7E2-383C95926C54" &&
                      !isLoading)
                    _dashCard(
                      icon: Icons.assignment_ind_rounded,
                      label: "Assigned task",
                      subtitle: "Assigned Task",
                      gradient: const [
                        Color(0xFF4A148C),
                        Color(0xFF6A1B9A),
                        Color(0xFF8E24AA),
                      ],
                      accentColor: Colors.purpleAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GlobalTaskScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: MediaQuery.of(context).size.width >= 600
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.width >= 600 ? 24 : 0,
        ),
        child: Theme(
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: Colors.transparent,
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
        ),
        child: _AiGlobeButton(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIChatScreen()),
            );
          },
        ),
      ),
      ),
    );
  }

  // â”€â”€ Chat preview card (WhatsApp-style on home screen) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildChatPreviewCard() {
    final hasChallans = _previewChallans.isNotEmpty;
    final hasGroups = _previewGroups.isNotEmpty;
    final isEmpty = !hasChallans && !hasGroups;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A2535) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: cardBg,
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
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0A3D35), const Color(0xFF0E5D5E)]
                      : [const Color(0xFF075E54), const Color(0xFF128C7E)],
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
                        settings: const RouteSettings(name: 'ChatListScreen'),
                        builder: (_) => const ChatListScreen(),
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
                        settings: const RouteSettings(name: 'ChatListScreen'),
                        builder: (_) => const ChatListScreen(),
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0F1923)
                      : const Color(0xFFF5F5F5),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F0F0),
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF8A9BB0) : const Color(0xFF555555),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF1A2535) : Colors.white;
    final titleColor = isDark
        ? const Color(0xFFE8EDF5)
        : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? const Color(0xFF8A9BB0) : Colors.grey;
    final subtitleUnreadColor = isDark
        ? const Color(0xFFCDD5E0)
        : const Color(0xFF222222);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: tileBg,
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
                            color: titleColor,
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
                            color: unreadCount > 0 ? _chatGreen : subtitleColor,
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
                                ? subtitleUnreadColor
                                : subtitleColor,
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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

                  Row(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),

                      const SizedBox(width: 5),

                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
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
        ),
      ),
    );
  }

  // ── Assign Task Dialog (shown directly from home purple card) ─────────────
  Future<void> _showAssignTaskDialog() async {
    // Load users if not already loaded
    if (!_assignUsersLoaded) {
      try {
        final users = await ApiService.getMergedUsers();
        if (mounted) {
          setState(() {
            _assignUsers = users;
            _assignUsersLoaded = true;
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;

    // Reset dialog state
    _assignTitleCtrl.clear();
    _assignDescCtrl.clear();
    _assignPriority = 'Medium';
    _assignStartDate = null;
    _assignDueDate = null;
    _assignSelectedUserId = null;
    _assignFrequency = null;

    String fmtDate(DateTime? d) {
      if (d == null) return 'Select date';
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
    }

    Color priorityColor(String p) {
      switch (p) {
        case 'High':
          return const Color(0xFFE53935);
        case 'Medium':
          return const Color(0xFFFB8C00);
        case 'Low':
          return const Color(0xFF43A047);
        default:
          return const Color(0xFFFB8C00);
      }
    }

    IconData priorityIcon(String p) {
      switch (p) {
        case 'High':
          return Icons.keyboard_double_arrow_up_rounded;
        case 'Medium':
          return Icons.remove_rounded;
        case 'Low':
          return Icons.keyboard_double_arrow_down_rounded;
        default:
          return Icons.remove_rounded;
      }
    }

    // Input decoration factory
    InputDecoration _fieldDecor({
      required String label,
      required IconData icon,
      Widget? suffix,
    }) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF7B5EA7)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF7B5EA7)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F0FF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5C5F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7B5EA7), width: 1.8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final screenW = MediaQuery.sizeOf(ctx).width;
          final screenH = MediaQuery.sizeOf(ctx).height;
          final isNarrow = screenW < 500;
          final isTabletOrLarge = screenW >= 700;

          // On tablet/large screens: wider dialog, generous padding, centered
          final dialogWidth = isTabletOrLarge
              ? (screenW * 0.55).clamp(520.0, 680.0)
              : isNarrow
                  ? double.infinity
                  : 480.0;

          return Dialog(
            backgroundColor: Colors.transparent,
            alignment: Alignment.center,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isTabletOrLarge
                  ? screenW * 0.18
                  : isNarrow
                      ? 12
                      : 40,
              vertical: isTabletOrLarge ? screenH * 0.06 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenH * (isTabletOrLarge ? 0.82 : 0.88),
              ),
              child: Container(
                width: dialogWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A148C).withOpacity(0.22),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Gradient header ───────────────────────────────
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        isTabletOrLarge ? 32 : 24,
                        isTabletOrLarge ? 26 : 22,
                        isTabletOrLarge ? 28 : 20,
                        isTabletOrLarge ? 24 : 20,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4A148C),
                            Color(0xFF6A1B9A),
                            Color(0xFF9C27B0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment_ind_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assign Task',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Create & assign a new task',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Form body ─────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          isTabletOrLarge ? 28 : 20,
                          isTabletOrLarge ? 24 : 20,
                          isTabletOrLarge ? 28 : 20,
                          8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task Title
                            TextField(
                              controller: _assignTitleCtrl,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _fieldDecor(
                                label: 'Task Title',
                                icon: Icons.title_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Description
                            TextField(
                              controller: _assignDescCtrl,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 14),
                              decoration: _fieldDecor(
                                label: 'Description',
                                icon: Icons.notes_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Assign To
                            DropdownButtonFormField<String>(
                              value: _assignSelectedUserId,
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _fieldDecor(
                                label: 'Assign To',
                                icon: Icons.person_outline_rounded,
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              items: _assignUsers.map((u) {
                                final id =
                                    u['UserId']?.toString() ??
                                    u['id']?.toString() ??
                                    '';
                                final name =
                                    u['UserName']?.toString() ??
                                    u['name']?.toString() ??
                                    id;
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setDlg(() => _assignSelectedUserId = v),
                            ),
                            const SizedBox(height: 14),

                            // Priority — chip row
                            const Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7B5EA7),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: ['Low', 'Medium', 'High'].map((p) {
                                final selected = _assignPriority == p;
                                final c = priorityColor(p);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setDlg(() => _assignPriority = p),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? c
                                              : c.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? c
                                                : c.withOpacity(0.3),
                                            width: selected ? 2 : 1,
                                          ),
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: c.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              priorityIcon(p),
                                              size: 18,
                                              color: selected
                                                  ? Colors.white
                                                  : c,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              p,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: selected
                                                    ? Colors.white
                                                    : c,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Frequency
                            DropdownButtonFormField<String?>(
                              value: _assignFrequency,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _fieldDecor(
                                label: 'Frequency',
                                icon: Icons.repeat_rounded,
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('One-time'),
                                ),
                                DropdownMenuItem(
                                  value: 'Weekly',
                                  child: Text('Weekly'),
                                ),
                                DropdownMenuItem(
                                  value: 'Monthly',
                                  child: Text('Monthly'),
                                ),
                                DropdownMenuItem(
                                  value: 'Yearly',
                                  child: Text('Yearly'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setDlg(() => _assignFrequency = v),
                            ),
                            const SizedBox(height: 14),

                            // Date row
                            Row(
                              children: [
                                // Start Date
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: ctx,
                                        initialDate:
                                            _assignStartDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null)
                                        setDlg(() => _assignStartDate = picked);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F0FF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _assignStartDate != null
                                              ? const Color(0xFF7B5EA7)
                                              : const Color(0xFFD5C5F0),
                                          width: _assignStartDate != null
                                              ? 1.8
                                              : 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_month_rounded,
                                                size: 14,
                                                color: Color(0xFF7B5EA7),
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                'Start Date',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF7B5EA7),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            fmtDate(_assignStartDate),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _assignStartDate != null
                                                  ? const Color(0xFF2D1B5E)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Due Date
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: ctx,
                                        initialDate:
                                            _assignDueDate ??
                                            (_assignStartDate ??
                                                DateTime.now()),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null)
                                        setDlg(() => _assignDueDate = picked);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F0FF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _assignDueDate != null
                                              ? const Color(0xFF7B5EA7)
                                              : const Color(0xFFD5C5F0),
                                          width: _assignDueDate != null
                                              ? 1.8
                                              : 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.event_rounded,
                                                size: 14,
                                                color: Color(0xFF7B5EA7),
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                'Due Date',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF7B5EA7),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            fmtDate(_assignDueDate),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _assignDueDate != null
                                                  ? const Color(0xFF2D1B5E)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),

                    // ── Action buttons ────────────────────────────────
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        isTabletOrLarge ? 28 : 20,
                        12,
                        isTabletOrLarge ? 28 : 20,
                        isTabletOrLarge ? 28 : 20,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFF0E6FF), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFD5C5F0),
                                  width: 1.5,
                                ),
                                foregroundColor: const Color(0xFF6A1B9A),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6A1B9A),
                                    Color(0xFF9C27B0),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6A1B9A,
                                    ).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_assignTitleCtrl.text.trim().isEmpty ||
                                      _assignSelectedUserId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill title and select a user',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final navigator = Navigator.of(ctx);

                                  // ── Build recurring slots ────────────────────
                                  final List<(DateTime, DateTime)> allSlots =
                                      [];

                                  if (_assignFrequency != null &&
                                      _assignStartDate != null &&
                                      _assignDueDate != null) {
                                    DateTime slotStart = _assignStartDate!;
                                    final rangeEnd = _assignDueDate!;

                                    while (!slotStart.isAfter(rangeEnd)) {
                                      DateTime slotEnd;
                                      if (_assignFrequency == 'Weekly') {
                                        slotEnd = slotStart.add(
                                          const Duration(days: 6),
                                        );
                                      } else if (_assignFrequency ==
                                          'Monthly') {
                                        final nextMonth = DateTime(
                                          slotStart.month == 12
                                              ? slotStart.year + 1
                                              : slotStart.year,
                                          slotStart.month == 12
                                              ? 1
                                              : slotStart.month + 1,
                                          slotStart.day,
                                        );
                                        slotEnd = nextMonth.subtract(
                                          const Duration(days: 1),
                                        );
                                      } else {
                                        // Yearly
                                        slotEnd = DateTime(
                                          slotStart.year + 1,
                                          slotStart.month,
                                          slotStart.day,
                                        ).subtract(const Duration(days: 1));
                                      }
                                      if (slotEnd.isAfter(rangeEnd)) {
                                        slotEnd = rangeEnd;
                                      }
                                      allSlots.add((slotStart, slotEnd));

                                      if (_assignFrequency == 'Weekly') {
                                        slotStart = slotStart.add(
                                          const Duration(days: 7),
                                        );
                                      } else if (_assignFrequency ==
                                          'Monthly') {
                                        slotStart = DateTime(
                                          slotStart.month == 12
                                              ? slotStart.year + 1
                                              : slotStart.year,
                                          slotStart.month == 12
                                              ? 1
                                              : slotStart.month + 1,
                                          slotStart.day,
                                        );
                                      } else {
                                        slotStart = DateTime(
                                          slotStart.year + 1,
                                          slotStart.month,
                                          slotStart.day,
                                        );
                                      }
                                    }
                                  }

                                  // ── Create first slot now ────────────────────
                                  final firstStart = allSlots.isNotEmpty
                                      ? allSlots.first.$1
                                      : _assignStartDate;
                                  final firstEnd = allSlots.isNotEmpty
                                      ? allSlots.first.$2
                                      : _assignDueDate;

                                  final ok = await ApiService.createGlobalTask(
                                    receiverId: _assignSelectedUserId!,
                                    taskTitle: _assignTitleCtrl.text.trim(),
                                    taskDescription: _assignDescCtrl.text
                                        .trim(),
                                    priority: _assignPriority,
                                    startDate: firstStart?.toIso8601String(),
                                    dueDate: firstEnd?.toIso8601String(),
                                  );

                                  // ── Schedule future slots ────────────────────
                                  if (ok && allSlots.length > 1) {
                                    await RecurringTaskScheduler.addGlobalPendingSlots(
                                      receiverId: _assignSelectedUserId!,
                                      taskTitle: _assignTitleCtrl.text.trim(),
                                      taskDescription: _assignDescCtrl.text
                                          .trim(),
                                      priority: _assignPriority,
                                      futureSlots: allSlots.sublist(1),
                                    );
                                  }

                                  if (!mounted) return;
                                  navigator.pop();
                                  messenger.showSnackBar(
                                    ok
                                        ? SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  allSlots.length > 1
                                                      ? 'Task assigned. ${allSlots.length - 1} future ${_assignFrequency!.toLowerCase()} task(s) scheduled.'
                                                      : 'Task assigned successfully',
                                                ),
                                              ],
                                            ),
                                            backgroundColor: const Color(
                                              0xFF2E7D32,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          )
                                        : const SnackBar(
                                            content: Text(
                                              'Failed to assign task',
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Assign Task',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
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
          );
        },
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

// -- Animated chat-request icon button for the home header -------------------
/// Shows a pulsing ripple ring when there are pending requests (red),
/// and a calm green glow when idle. The icon itself gently scales up/down.
class _ChatRequestIconButton extends StatelessWidget {
  const _ChatRequestIconButton({
    required this.pendingCount,
    required this.animation,
    required this.onTap,
  });

  final int pendingCount;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    final rippleColor = hasPending
        ? const Color(0xFFFF5252)
        : const Color(0xFF43A047);
    final badgeColor = hasPending
        ? const Color(0xFFE53935)
        : const Color(0xFF43A047);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final scale = hasPending ? 0.92 + (0.16 * animation.value) : 1.0;
          final rippleRadius = hasPending
              ? 18.0 + (14.0 * animation.value)
              : 0.0;
          final rippleOpacity = hasPending
              ? (1.0 - animation.value) * 0.55
              : 0.0;

          return SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (hasPending)
                  Container(
                    width: rippleRadius * 2,
                    height: rippleRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rippleColor.withOpacity(rippleOpacity),
                    ),
                  ),
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasPending
                          ? Color.lerp(
                              Colors.white.withOpacity(0.15),
                              const Color(0xFFE53935).withOpacity(0.35),
                              animation.value,
                            )
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: hasPending
                            ? Color.lerp(
                                Colors.white.withOpacity(0.35),
                                const Color(0xFFFF5252).withOpacity(0.8),
                                animation.value,
                              )!
                            : Colors.white.withOpacity(0.35),
                        width: 1.2,
                      ),
                      boxShadow: hasPending
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF5252,
                                ).withOpacity(0.4 * animation.value),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(
                                  0xFF43A047,
                                ).withOpacity(0.35),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                    ),
                    child: const Icon(
                      Icons.mark_chat_unread_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                if (hasPending)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Opacity(
                      opacity: 0.6 + (0.4 * animation.value),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            pendingCount > 9 ? '9+' : '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!hasPending)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF43A047).withOpacity(0.6),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDark;
        final drawerBg = isDark ? const Color(0xFF1A2535) : Colors.white;
        final textHighColor = isDark
            ? const Color(0xFFE8EDF5)
            : const Color(0xFF1A1A2E);
        final textMidColor = isDark
            ? const Color(0xFF8A9BB0)
            : Colors.grey.shade500;
        final dividerColor = isDark
            ? const Color(0xFF2A3A4A)
            : Colors.grey.shade100;

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Dimmed backdrop - tap to close
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
                    decoration: BoxDecoration(
                      color: drawerBg,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(24),
                      ),
                      boxShadow: const [
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
                          // Profile header (gradient - adaptive)
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF0A3A6C),
                                        const Color(0xFF2A5A8C),
                                      ]
                                    : [
                                        const Color(0xFF1565C0),
                                        const Color(0xFF42A5F5),
                                      ],
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
                          // Menu items
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  // Theme toggle
                                  Consumer<ThemeProvider>(
                                    builder: (ctx, tp, _) {
                                      final autoOn = tp.isAuto;
                                      return GestureDetector(
                                        onTap: autoOn
                                            ? widget.onSettings
                                            : widget.onToggleTheme,
                                        child: Container(
                                          color: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 13,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF1E2D3D)
                                                      : const Color(0xFFFFF8E1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  autoOn
                                                      ? Icons
                                                            .auto_awesome_rounded
                                                      : isDark
                                                      ? Icons.dark_mode_rounded
                                                      : Icons
                                                            .light_mode_rounded,
                                                  color: autoOn
                                                      ? const Color(0xFF1A56DB)
                                                      : isDark
                                                      ? const Color(0xFF90CAF9)
                                                      : const Color(0xFFFFA000),
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          autoOn
                                                              ? "Auto Theme"
                                                              : isDark
                                                              ? "Dark Mode"
                                                              : "Light Mode",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                textHighColor,
                                                          ),
                                                        ),
                                                        if (autoOn) ...[
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFF1A56DB,
                                                                  ).withOpacity(
                                                                    0.12,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              isDark
                                                                  ? '🌙 Night'
                                                                  : '☀️ Day',
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                  0xFF1A56DB,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 1),
                                                    Text(
                                                      autoOn
                                                          ? '${tp.sunriseLabel} sunrise · ${tp.sunsetLabel} sunset'
                                                          : isDark
                                                          ? "Switch to light theme"
                                                          : "Switch to dark theme",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: textMidColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Animated toggle switch
                                              AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                width: 44,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: autoOn
                                                      ? const Color(0xFF1A56DB)
                                                      : isDark
                                                      ? const Color(0xFF1565C0)
                                                      : Colors.grey.shade300,
                                                ),
                                                child: Stack(
                                                  children: [
                                                    AnimatedPositioned(
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      curve: Curves.easeInOut,
                                                      left: (autoOn || isDark)
                                                          ? 22
                                                          : 2,
                                                      top: 2,
                                                      child: Container(
                                                        width: 20,
                                                        height: 20,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Color(
                                                                    0x33000000,
                                                                  ),
                                                                  blurRadius: 4,
                                                                  offset:
                                                                      Offset(
                                                                        0,
                                                                        1,
                                                                      ),
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
                                      );
                                    },
                                  ),
                                  Divider(
                                    height: 1,
                                    indent: 72,
                                    endIndent: 20,
                                    color: dividerColor,
                                  ),
                                  _DropdownMenuItem(
                                    icon: Icons.settings_rounded,
                                    iconBg: isDark
                                        ? const Color(0xFF1E3A5F)
                                        : const Color(0xFFE3F2FD),
                                    iconColor: const Color(0xFF1565C0),
                                    label: "Settings",
                                    subtitle: "App preferences & configuration",
                                    labelColor: textHighColor,
                                    subtitleColor: textMidColor,
                                    onTap: widget.onSettings,
                                  ),
                                  Divider(
                                    height: 1,
                                    indent: 72,
                                    endIndent: 20,
                                    color: dividerColor,
                                  ),
                                  _DropdownMenuItem(
                                    icon: Icons.logout_rounded,
                                    iconBg: isDark
                                        ? const Color(0xFF3B1A1A)
                                        : const Color(0xFFFFEBEE),
                                    iconColor: Colors.red.shade400,
                                    label: "Logout",
                                    subtitle: "Sign out of your account",
                                    labelColor: Colors.red.shade400,
                                    subtitleColor: textMidColor,
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
      },
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
  final Color? subtitleColor;

  const _DropdownMenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.labelColor,
    this.subtitleColor,
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
                      color: subtitleColor ?? Colors.grey.shade500,
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

// ── AI Globe Floating Button ─────────────────────────────────────────────────
class _AiGlobeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AiGlobeButton({required this.onTap});

  @override
  State<_AiGlobeButton> createState() => _AiGlobeButtonState();
}

class _AiGlobeButtonState extends State<_AiGlobeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => ClipOval(
            child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.3),
                radius: 0.9,
                colors: [Color(0xFF1a1040), Color(0xFF0a0520)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFb040ff).withOpacity(0.55),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF00d4ff).withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _GlobePainter(angle: _ctrl.value * 2 * math.pi),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Color(0xFF00d4ff), blurRadius: 12),
                      Shadow(color: Color(0xFFb040ff), blurRadius: 18),
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
  }
}

class _GlobePainter extends CustomPainter {
  final double angle;
  _GlobePainter({required this.angle});

  // Fixed node positions on a unit sphere (longitude, latitude) in radians
  static final List<List<double>> _nodes = [
    [0.0, 0.0],
    [1.05, 0.52],
    [2.09, 0.0],
    [3.14, 0.52],
    [4.19, 0.0],
    [5.24, 0.52],
    [0.52, 1.05],
    [1.57, 1.05],
    [2.62, 1.05],
    [3.67, 1.05],
    [4.71, 1.05],
    [0.0, -1.05],
    [1.05, -0.52],
    [2.09, -1.05],
    [3.14, -0.52],
    [4.19, -1.05],
    [5.24, -0.52],
    [0.52, -1.05],
    [1.57, -1.05],
    [2.62, -1.05],
    [3.67, -1.05],
    [4.71, -1.05],
    [0.79, 0.0],
    [1.57, 0.0],
    [2.36, 0.0],
    [3.14, 0.0],
    [3.93, 0.0],
    [4.71, 0.0],
    [0.0, 1.57],
    [3.14, 1.57],
    [0.0, -1.57],
    [3.14, -1.57],
  ];

  // Which nodes connect (indices)
  static final List<List<int>> _edges = [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 0],
    [0, 6],
    [1, 6],
    [1, 7],
    [2, 7],
    [2, 8],
    [3, 8],
    [3, 9],
    [4, 9],
    [4, 10],
    [5, 10],
    [5, 6],
    [0, 12],
    [12, 1],
    [1, 13],
    [2, 14],
    [14, 3],
    [3, 15],
    [4, 16],
    [16, 5],
    [5, 17],
    [6, 28],
    [7, 28],
    [8, 28],
    [9, 29],
    [10, 29],
    [11, 30],
    [12, 30],
    [13, 30],
    [14, 31],
    [15, 31],
    [22, 23],
    [23, 24],
    [24, 25],
    [25, 26],
    [26, 27],
    [6, 22],
    [7, 23],
    [8, 24],
    [9, 25],
    [10, 26],
  ];

  Offset _project(double lon, double lat, double cx, double cy, double r) {
    final rotLon = lon + angle;
    final x = math.cos(lat) * math.cos(rotLon);
    final y = math.sin(lat);
    final z = math.cos(lat) * math.sin(rotLon);
    // Simple perspective
    final scale = (z + 2.5) / 3.5;
    return Offset(cx + x * r * scale, cy - y * r * scale);
  }

  double _depth(double lon, double lat) {
    final rotLon = lon + angle;
    return math.cos(lat) * math.sin(rotLon);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    // Draw edges
    for (final edge in _edges) {
      final n1 = _nodes[edge[0]];
      final n2 = _nodes[edge[1]];
      final d1 = _depth(n1[0], n1[1]);
      final d2 = _depth(n2[0], n2[1]);
      final avgDepth = (d1 + d2) / 2;
      // Only draw edges on the front hemisphere (partially)
      final alpha = ((avgDepth + 1) / 2).clamp(0.08, 0.7);

      final p1 = _project(n1[0], n1[1], cx, cy, r);
      final p2 = _project(n2[0], n2[1], cx, cy, r);

      // Gradient from magenta to cyan based on longitude
      final t = ((n1[0] + angle) % (2 * math.pi)) / (2 * math.pi);
      final edgeColor = Color.lerp(
        const Color(0xFFcc44ff),
        const Color(0xFF00ddff),
        t,
      )!.withOpacity(alpha);

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = edgeColor
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    // Draw nodes
    for (final node in _nodes) {
      final d = _depth(node[0], node[1]);
      if (d < -0.2) continue; // skip back nodes
      final alpha = ((d + 1) / 2).clamp(0.2, 1.0);
      final pos = _project(node[0], node[1], cx, cy, r);
      final t = ((node[0] + angle) % (2 * math.pi)) / (2 * math.pi);
      final nodeColor = Color.lerp(
        const Color(0xFFee55ff),
        const Color(0xFF00eeff),
        t,
      )!.withOpacity(alpha);

      final dotR = 1.8 * ((d + 2.5) / 3.5).clamp(0.5, 1.2);

      // Glow
      canvas.drawCircle(
        pos,
        dotR + 1.5,
        Paint()
          ..color = nodeColor.withOpacity(alpha * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      // Core dot
      canvas.drawCircle(pos, dotR, Paint()..color = nodeColor);
    }
  }

  @override
  bool shouldRepaint(_GlobePainter old) => old.angle != angle;
}

// ── Pending Delivery Card ─────────────────────────────────────────────────────
// ── Pending Delivery Card ─────────────────────────────────────────────────────
class _PendingDeliveryCard extends StatelessWidget {
  final int count;

  const _PendingDeliveryCard({required this.count});

  @override
  Widget build(BuildContext context) {
    const gradient = [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF9C27B0)];

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A148C).withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pending Delivery',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Approved · Awaiting Delivery',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Count ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Pending',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 2),

                AnimatedFlipCounter(
                  value: count,
                  duration: const Duration(milliseconds: 700),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot indicator for the stats PageView ──────────────────────────────────────
class _StatsPageDots extends StatefulWidget {
  final PageController controller;
  final int count;
  const _StatsPageDots({required this.controller, required this.count});

  @override
  State<_StatsPageDots> createState() => _StatsPageDotsState();
}

class _StatsPageDotsState extends State<_StatsPageDots> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPage);
  }

  void _onPage() {
    final p = widget.controller.page?.round() ?? 0;
    if (p != _page && mounted) setState(() => _page = p);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.count, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
