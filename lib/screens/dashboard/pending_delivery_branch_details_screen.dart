import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/rgb_border_card.dart';

class PendingDeliveryBranchDetailsScreen extends StatefulWidget {
  final String branchName;
  final String branchId;
  final int count;

  const PendingDeliveryBranchDetailsScreen({
    super.key,
    required this.branchName,
    required this.branchId,
    required this.count,
  });

  @override
  State<PendingDeliveryBranchDetailsScreen> createState() =>
      _PendingDeliveryBranchDetailsScreenState();
}

class _PendingDeliveryBranchDetailsScreenState
    extends State<PendingDeliveryBranchDetailsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;
  String? _error;
  final PageController _pageController = PageController(viewportFraction: 0.94);
  int _currentPage = 0;

  static const Color _primary = Color(0xFF4A148C);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _error = null;
      });

    try {
      final data = await ApiService.getPendingDeliveryBranchDetails(
        branchId: widget.branchId,
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

  String _val(Map<String, dynamic> row, String key) {
    final v = row[key];
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: _primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.branchName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Pending Deliveries',
              style: TextStyle(fontSize: 12, color: Colors.white70),
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
      return const Center(child: CircularProgressIndicator(color: _primary));
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
            itemBuilder: (ctx, i) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildCard(_rows[i], i),
              ),
            ),
          ),
        ),
        _buildPageIndicator(),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A0060), const Color(0xFF4A0080)]
              : [const Color(0xFF4A148C), const Color(0xFF9C27B0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white70,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_rows.length} Pending ${_rows.length == 1 ? 'Delivery' : 'Deliveries'}',
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
                    'Record ${_currentPage + 1} of ${_rows.length}',
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

  Widget _buildPageIndicator() {
    // For large record sets show "X / Y" text instead of overflowing dots
    if (_rows.length > 12) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '${_currentPage + 1} / ${_rows.length}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> row, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerName = _val(row, 'customer');
    final initial = customerName != '—' && customerName.isNotEmpty
        ? customerName[0].toUpperCase()
        : 'P';

    // Avatar background colors cycling through a palette
    const avatarColors = [
      Color(0xFF1E3A5F),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFF00695C),
      Color(0xFFBF360C),
      Color(0xFF283593),
    ];
    final avatarColor = avatarColors[index % avatarColors.length];

    // Date badge value
    final dateVal = _val(row, 'expectedDeliveryDate') != '—'
        ? _val(row, 'expectedDeliveryDate')
        : _val(row, 'bookingDate') != '—'
            ? _val(row, 'bookingDate')
            : null;

    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final tileBg = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5);
    final labelColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final valueColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF444466);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 20),
      child: RgbBorderCard(
        borderRadius: 28,
        borderWidth: 2.0,
        glow: true,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: cardBg,
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // ── Customer Header ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: avatarColor,
                        child: Text(
                          initial,
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
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date badge (replaces Approved badge)
                      if (dateVal != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A5F)
                                : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            dateVal,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.lightBlueAccent
                                  : const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Detail Tiles ─────────────────────────────────
                  _infoTile(
                    Icons.directions_car_rounded,
                    'Model',
                    _val(row, 'model'),
                    tileBg,
                    labelColor,
                    valueColor,
                    iconColor,
                  ),
                  _infoTile(
                    Icons.category_rounded,
                    'Variant',
                    _val(row, 'variant'),
                    tileBg,
                    labelColor,
                    valueColor,
                    iconColor,
                  ),
                  _infoTile(
                    Icons.palette_rounded,
                    'Color',
                    _val(row, 'color'),
                    tileBg,
                    labelColor,
                    valueColor,
                    iconColor,
                  ),
                  _infoTile(
                    Icons.label_rounded,
                    'Booking Type',
                    _val(row, 'bookingType'),
                    tileBg,
                    labelColor,
                    valueColor,
                    iconColor,
                  ),
                  _infoTile(
                    Icons.storefront_rounded,
                    'Branch',
                    _val(row, 'branch'),
                    tileBg,
                    labelColor,
                    valueColor,
                    iconColor,
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
    Color tileBg,
    Color labelColor,
    Color valueColor,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: tileBg,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: labelColor),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
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
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
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
        const Icon(Icons.local_shipping_rounded, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No pending deliveries found',
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
