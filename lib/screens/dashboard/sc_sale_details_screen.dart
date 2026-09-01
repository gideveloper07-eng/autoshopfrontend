import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/rgb_border_card.dart';

/// Shows sale detail cards for a specific SC, swiped one-by-one.
/// Same swipeable PageView style as BranchSaleDetailsScreen.
class SCSaleDetailsScreen extends StatefulWidget {
  final String scId;
  final String scName;
  final String period; // 'today' or 'yesterday'
  final int saleCount;

  const SCSaleDetailsScreen({
    super.key,
    required this.scId,
    required this.scName,
    required this.period,
    required this.saleCount,
  });

  @override
  State<SCSaleDetailsScreen> createState() => _SCSaleDetailsScreenState();
}

class _SCSaleDetailsScreenState extends State<SCSaleDetailsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  late final PageController _pageController;

  static const Color _primary = Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.94);
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _rows = [];
    });

    try {
      final data = await ApiService.getSCSaleDetails(
        period: widget.period,
        scId: widget.scId,
        scName: widget.scName,
      );
      if (!mounted) return;
      setState(() {
        _rows = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _val(Map<String, dynamic> row, String key) {
    final v = row[key];
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final periodLabel = widget.period == 'today' ? "Today's" : "Yesterday's";
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.scName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '$periodLabel Sales',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }
    if (_error != null) return _buildError();
    if (_rows.isEmpty) return _buildEmpty();

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _rows.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildSaleCard(_rows[i], i),
            ),
          ),
        ),
        _buildPageIndicator(),
        const SizedBox(height: 18),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A237E), const Color(0xFF283593)]
              : [const Color(0xFF1A237E), const Color(0xFF3949AB)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell_rounded, color: Colors.white70, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_rows.length} Sale${_rows.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.scName,
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
                    'Sale ${_currentPage + 1} of ${_rows.length}',
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

  // ── Page indicator ─────────────────────────────────────────────────────────

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_rows.length, (i) {
          final selected = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: selected ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: selected ? _primary : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }

  // ── Info tile ──────────────────────────────────────────────────────────────

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
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
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
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

  // ── Sale card ──────────────────────────────────────────────────────────────

  Widget _buildSaleCard(Map<String, dynamic> row, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final valueColor = theme.colorScheme.onSurface;
    final customerName = _val(row, 'Customer Name');

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
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF222222), const Color(0xFF111111)]
                    : [Colors.white, const Color(0xFFF4FBFF)],
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(22),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Customer header ───────────────────────────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _primary,
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : 'C',
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
                            customerName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: valueColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sale #${index + 1}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    // Delivery date badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _val(row, 'Delivery Date'),
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Vehicle ───────────────────────────────────────
                _infoTile(Icons.directions_car, 'Model', _val(row, 'Model')),
                _infoTile(Icons.category, 'Variant', _val(row, 'Variant')),
                _infoTile(Icons.palette, 'Color', _val(row, 'Color')),
                _infoTile(Icons.tag, 'Challan No', _val(row, 'Challan No')),
                _infoTile(
                  Icons.calendar_today,
                  'Challan Date',
                  _val(row, 'Challan Date'),
                ),
                _infoTile(
                  Icons.event,
                  'Booking Date',
                  _val(row, 'Booking Date'),
                ),
                _infoTile(
                  Icons.local_shipping,
                  'Delivery Date',
                  _val(row, 'Delivery Date'),
                ),
                _infoTile(
                  Icons.sell,
                  'Booking Type',
                  _val(row, 'Booking Type'),
                ),
                _infoTile(Icons.person, 'Sales Consultant', _val(row, 'SC')),
                _infoTile(Icons.groups, 'Team Leader', _val(row, 'TL')),
                _infoTile(
                  Icons.location_city,
                  'Branch',
                  _val(row, 'Branch'),
                ),
                _infoTile(
                  Icons.account_balance,
                  'Finance',
                  _val(row, 'Finance'),
                ),
                _infoTile(Icons.qr_code, 'VIN No', _val(row, 'VIN No')),
                _infoTile(
                  Icons.receipt,
                  'Invoice No',
                  _val(row, 'Invoice No'),
                ),
                _infoTile(
                  Icons.calendar_month,
                  'Invoice Date',
                  _val(row, 'Invoice Date'),
                ),

                const Divider(height: 28),

                // ── Contact ───────────────────────────────────────
                _infoTile(Icons.phone, 'Mobile No', _val(row, 'Mobile No')),
                _infoTile(Icons.email, 'Mail Id', _val(row, 'Mail Id')),

                const Divider(height: 28),

                // ── Financials ────────────────────────────────────
                _infoTile(
                  Icons.currency_rupee,
                  'Ex Show Room',
                  _val(row, 'Ex Show Room'),
                ),
                _infoTile(
                  Icons.discount,
                  'Discount',
                  _val(row, 'Discount'),
                ),
                _infoTile(
                  Icons.calculate,
                  'Net Amount',
                  _val(row, 'Net Amount'),
                ),
                _infoTile(
                  Icons.shield,
                  'Insurance',
                  _val(row, 'Insurance Amount'),
                ),
                _infoTile(
                  Icons.map,
                  'RTO Amount',
                  _val(row, 'RTO Amount'),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  // ── Empty / Error ──────────────────────────────────────────────────────────

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
            onPressed: _load,
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
        Icon(
          Icons.sell_outlined,
          size: 64,
          color: _primary.withOpacity(0.4),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            widget.period == 'today'
                ? 'No sales found today'
                : 'No sales found yesterday',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
