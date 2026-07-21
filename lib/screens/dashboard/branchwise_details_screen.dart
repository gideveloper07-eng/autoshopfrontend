import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/cache_service.dart';

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
    final cacheKey = CacheService.keyBranchwise(widget.reportType, widget.period);

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
    final primaryColor = _isBooking
        ? const Color(0xFF1565C0)
        : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

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
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isBooking
              ? const [Color(0xFF0A3D8F), Color(0xFF1E88E5)]
              : const [Color(0xFF1B5E20), Color(0xFF43A047)],
        ),

        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),

          bottomRight: Radius.circular(28),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            _isBooking ? "Today's Total Booking" : "Today's Total Sale",

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
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch, Color primaryColor) {
    final branchName = branch['branchName']?.toString() ?? "Unknown Branch";

    final count = (branch['count'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),

            blurRadius: 14,

            offset: const Offset(0, 5),
          ),
        ],
      ),

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
                _isBooking ? Icons.bookmark_added_rounded : Icons.sell_rounded,

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
          ],
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
            _isBooking ? "No bookings found today" : "No sales found today",

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
