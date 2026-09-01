import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import 'branch_booking_details_screen.dart';
import 'BranchSaleDetailsScreen.dart';
import 'modelwise_summary_screen.dart';
import 'scwise_summary_screen.dart';
import '../home/rgb_border_card.dart';

class BranchwiseDetailsScreen extends StatefulWidget {
  final String reportType;
  final String title;
  final String period;

  const BranchwiseDetailsScreen({
    super.key,
    required this.reportType,
    required this.title,
    required this.period,
  });

  @override
  State<BranchwiseDetailsScreen> createState() =>
      _BranchwiseDetailsScreenState();
}

class _BranchwiseDetailsScreenState extends State<BranchwiseDetailsScreen> {
  bool _isLoading = true;

  int _total = 0;

  String? _errorMessage;

  List<Map<String, dynamic>> _branchData = [];

  bool get _isBooking => widget.reportType.toLowerCase() == "booking";

  @override
  void initState() {
    super.initState();

    _loadBranchwiseData();
  }

  Future<void> _loadBranchwiseData() async {
    final cacheKey = CacheService.keyBranchwise(
      widget.reportType,
      widget.period,
    );

    // ── Step 1: Show cached data immediately ─────────────────────────────
    final cached = await CacheService.getMap(
      cacheKey,
      ttlMs: CacheService.ttlDashboard,
    );
    if (cached != null && mounted) {
      final rawBranches = cached['branches'];
      final branches = rawBranches is List
          ? rawBranches
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _total = (cached['total'] as num?)?.toInt() ?? 0;
        _branchData = branches;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    // ── Step 2: Fetch fresh from backend ─────────────────────────────────
    try {
      final result = await ApiService.getDashboardBranchwise(
        widget.reportType,
        widget.period,
      );

      // ── Step 3: Update cache ────────────────────────────────────────────
      await CacheService.setMap(cacheKey, result);

      final rawBranches = result['branches'];
      final branches = rawBranches is List
          ? rawBranches
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _total = (result['total'] as num?)?.toInt() ?? 0;
        _branchData = branches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_branchData.isEmpty) {
          _errorMessage = "Unable to load branchwise data.";
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _isBooking
        ? theme.colorScheme.primary
        : const Color(0xFF3949AB);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,

        foregroundColor: Colors.white,

        backgroundColor: primaryColor,

        title: Text(
          widget.title,

          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: "Refresh",

            onPressed: _loadBranchwiseData,

            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadBranchwiseData,

        child: _buildBody(primaryColor),
      ),
    );
  }

  Widget _buildBody(Color primaryColor) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,

            child: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(24),

        children: [
          const SizedBox(height: 120),

          Icon(Icons.cloud_off_rounded, color: Colors.grey[400], size: 70),

          const SizedBox(height: 15),

          Text(
            _errorMessage!,

            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 15),

          Center(
            child: ElevatedButton.icon(
              onPressed: _loadBranchwiseData,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text("Retry"),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.only(bottom: 24),

      children: [
        _buildSummary(primaryColor),

        const SizedBox(height: 18),

        if (_branchData.isEmpty)
          _buildEmptyState(primaryColor)
        else
          ..._branchData.map(
            (branch) => _buildBranchCard(branch, primaryColor),
          ),
      ],
    );
  }

  Widget _buildSummary(Color primaryColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isBooking
              ? (isDark
                  ? [const Color(0xFF0A2A5C), const Color(0xFF1A4A8C)]
                  : [const Color(0xFF0A3D8F), const Color(0xFF1E88E5)])
              : (isDark
                  ? [const Color(0xFF1A237E), const Color(0xFF283593)]
                  : [const Color(0xFF1A237E), const Color(0xFF3949AB)]),
        ),

        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),

          bottomRight: Radius.circular(28),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: stats text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBooking
                      ? widget.period == 'today'
                            ? "Today's Total Booking"
                            : "Yesterday's Total Booking"
                      : widget.period == 'today'
                      ? "Today's Total Sale"
                      : "Yesterday's Total Sale",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 8),

                Text(
                  _total.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "${_branchData.length} "
                  "${_branchData.length == 1 ? 'Branch' : 'Branches'}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Right: Model Summary button + SC Summary button (sale only)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModelwiseSummaryScreen(
                        reportType: widget.reportType,
                        period: widget.period,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bar_chart_rounded,
                          color: Colors.white, size: 26),
                      SizedBox(height: 4),
                      Text(
                        "Model\nSummary",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // SC Summary button — only for sale type
              if (!_isBooking) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SCwiseSummaryScreen(
                          period: widget.period,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.person_search_rounded,
                            color: Colors.white, size: 26),
                        SizedBox(height: 4),
                        Text(
                          "SC\nSummary",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch, Color primaryColor) {
    final branchName = branch['branchName']?.toString() ?? "Unknown Branch";
    final branchId = branch['branchId']?.toString() ?? "";
    final count = (branch['count'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: RgbBorderCard(
        borderRadius: 18,
        borderWidth: 1.8,
        duration: const Duration(seconds: 4),
        glow: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _isBooking
                        ? BranchBookingDetailsScreen(
                            branchName: branchName,
                            branchId: branchId,
                            period: widget.period,
                            bookingCount: count,
                          )
                        : BranchSaleDetailsScreen(
                            branchName: branchName,
                            branchId: branchId,
                            period: widget.period,
                            saleCount: count,
                          ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _isBooking
                            ? Icons.bookmark_added_rounded
                            : Icons.sell_rounded,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branchName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _isBooking
                                ? "$count ${count == 1 ? 'Booking' : 'Bookings'}"
                                : "$count ${count == 1 ? 'Sale' : 'Sales'}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: primaryColor.withOpacity(0.5),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 90),

      child: Column(
        children: [
          Icon(
            _isBooking ? Icons.bookmark_border_rounded : Icons.sell_outlined,

            color: primaryColor.withOpacity(0.45),

            size: 70,
          ),

          const SizedBox(height: 15),

          Text(
            _isBooking
                ? widget.period == 'today'
                      ? "No bookings found today"
                      : "No bookings found yesterday"
                : widget.period == 'today'
                ? "No sales found today"
                : "No sales found yesterday",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
