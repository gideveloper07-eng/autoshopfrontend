import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../home/rgb_border_card.dart';

/// Shows all booking detail rows for a given branch & period.
class BranchBookingDetailsScreen extends StatefulWidget {
  final String branchName;
  final String branchId;
  final String period; // 'today' or 'yesterday'
  final int bookingCount;

  const BranchBookingDetailsScreen({
    super.key,
    required this.branchName,
    required this.branchId,
    required this.period,
    required this.bookingCount,
  });

  @override
  State<BranchBookingDetailsScreen> createState() =>
      _BranchBookingDetailsScreenState();
}

class _BranchBookingDetailsScreenState
    extends State<BranchBookingDetailsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;
  String? _error;
  final PageController _pageController = PageController(viewportFraction: 0.94);

  int _currentPage = 0;
  static const Color _primary = Color(0xFF1565C0);
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  String get _cacheKey => 'branch_booking_${widget.branchId}_${widget.period}';

  Future<void> _loadDetails() async {
    // Remove old cache
    await CacheService.delete(_cacheKey);

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _rows = [];
    });

    try {
      print("========== BRANCH DETAILS ==========");
      print("Branch Name : ${widget.branchName}");
      print("Branch Id   : ${widget.branchId}");
      print("Period      : ${widget.period}");
      print("Cache Key   : $_cacheKey");
      print("====================================");

      final data = await ApiService.getBranchBookingDetails(
        period: widget.period,
        branchId: widget.branchId,
        branchName: widget.branchName,
      );

      print("========== API RESULT ==========");
      print("Rows Received : ${data.length}");

      if (data.isNotEmpty) {
        print("First Record : ${data.first}");

        // Cache latest data
        await CacheService.setListMap(_cacheKey, data);
      } else {
        print("No records found.");
      }

      if (!mounted) return;

      setState(() {
        _rows = data;
        _isLoading = false;
      });

      print("================================");
    } catch (e, stackTrace) {
      print("========== ERROR ==========");
      print(e);
      print(stackTrace);
      print("===========================");

      if (!mounted) return;

      setState(() {
        _rows = [];
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _val(Map<String, dynamic> row, String key) {
    final v = row[key];
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final periodLabel = widget.period == 'today' ? "Today's" : "Yesterday's";
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.branchName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '$periodLabel Bookings',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadDetails, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_rows.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: [
        _buildHeader(),

        const SizedBox(height: 12),

        Expanded(
          child: PageView.builder(
            controller: _pageController,

            itemCount: _rows.length,

            physics: const BouncingScrollPhysics(),

            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },

            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildBookingCard(_rows[index], index),
              );
            },
          ),
        ),

        _buildPageIndicator(),

        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildPageIndicator() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_rows.length, (index) {
          final selected = index == _currentPage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),

            margin: const EdgeInsets.symmetric(horizontal: 4),

            width: selected ? 26 : 8,
            height: 8,

            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A2A5C), const Color(0xFF1A4A8C)]
              : [const Color(0xFF0A3D8F), const Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bookmark_added_rounded,
            color: Colors.white70,
            size: 30,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_rows.length} Booking${_rows.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.branchName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    "Booking ${_currentPage + 1} of ${_rows.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.grey.withOpacity(.08),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primary, size: 24),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> row, int index) {
    final cardColor = Theme.of(context).cardColor;
    final valueColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 20),
      child: RgbBorderCard(
        borderRadius: 28,
        borderWidth: 2.0,
        glow: true,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(28),
          color: Colors.transparent,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xff222222), const Color(0xff111111)]
                    : [Colors.white, const Color(0xffF4F9FF)],
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(22),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //---------------------------------------------------
                // CUSTOMER HEADER
                //---------------------------------------------------
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _primary,

                      child: Text(
                        _val(
                          row,
                          'Customer Name',
                        ).substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _val(row, 'Customer Name'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: valueColor,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Booking #${index + 1}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _val(row, 'Booking Date'),
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                //---------------------------------------------------
                // DETAILS
                //---------------------------------------------------
                _infoTile(Icons.directions_car, "Model", _val(row, "Model")),

                _infoTile(Icons.category, "Variant", _val(row, "Variant")),

                _infoTile(Icons.palette, "Color", _val(row, "Color")),

                _infoTile(
                  Icons.sell,
                  "Booking Type",
                  _val(row, "Booking Type"),
                ),

                _infoTile(Icons.person, "Sales Consultant", _val(row, "SC")),

                _infoTile(Icons.groups, "Team Leader", _val(row, "TL")),

                _infoTile(
                  Icons.calendar_today,
                  "Receipt Date",
                  _val(row, "Receipt Date"),
                ),

                _infoTile(
                  Icons.event_available,
                  "Expected Delivery",
                  _val(row, "Ex Date"),
                ),

                _infoTile(
                  Icons.local_shipping,
                  "Delivery Date",
                  _val(row, "Delivery Date"),
                ),

                _infoTile(
                  Icons.account_balance,
                  "Finance",
                  _val(row, "Finance"),
                ),

                _infoTile(Icons.qr_code, "VIN Number", _val(row, "VIN No")),

                _infoTile(Icons.inventory, "Package", _val(row, "Package")),

                if (_val(row, "Remark") != "—") ...[
                  const SizedBox(height: 20),

                  Text(
                    "Remark",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _val(row, "Remark"),
                      style: TextStyle(color: valueColor),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _detailGrid(
    Map<String, dynamic> row,
    Color labelColor,
    Color valueColor,
  ) {
    final fields = [
      ('Model', _val(row, 'Model')),
      ('Variant', _val(row, 'Variant')),
      ('Color', _val(row, 'Color')),
      ('Booking Type', _val(row, 'Booking Type')),
      ('SC', _val(row, 'SC')),
      ('TL', _val(row, 'TL')),
      ('Receipt Date', _val(row, 'Receipt Date')),
      ('Ex Date', _val(row, 'Ex Date')),
      ('Delivery Date', _val(row, 'Delivery Date')),
      ('Finance', _val(row, 'Finance')),
      ('VIN No', _val(row, 'VIN No')),
      ('Package', _val(row, 'Package')),
    ];

    // Remark full width at bottom if present
    final remark = _val(row, 'Remark');

    return Column(
      children: [
        // 2-column grid
        Wrap(
          spacing: 0,
          runSpacing: 0,
          children: fields.map((f) {
            return SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 30,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.$1,
                      style: TextStyle(
                        fontSize: 10,
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 13,
                        color: valueColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // Remark full width
        if (remark != '—') ...[
          const Divider(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remark: ',
                style: TextStyle(
                  fontSize: 11,
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  remark,
                  style: TextStyle(
                    fontSize: 12,
                    color: valueColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          _error ?? 'Failed to load data',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _loadDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
