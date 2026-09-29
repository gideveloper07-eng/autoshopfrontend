import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import 'acc_cancel_approve_form_screen.dart';

class AccCancelApproveScreen extends StatefulWidget {
  const AccCancelApproveScreen({super.key});

  @override
  State<AccCancelApproveScreen> createState() => _AccCancelApproveScreenState();
}

class _AccCancelApproveScreenState extends State<AccCancelApproveScreen> {
  // ─────────────────────────────────────────────────────────────────────────
  // Theme
  // ─────────────────────────────────────────────────────────────────────────

  static const Color _primary = Color(0xFF0D3F8A);
  static const Color _accent = Color(0xFF2C6CE0);

  // ─────────────────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────────────────

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];

  // ── search ────────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      final name = (_v(r['sp_440'])).toLowerCase();
      final vin  = (_v(r['sp_441'])).toLowerCase();
      return name.contains(q) || vin.contains(q);
    }).toList();
  }

  // ── pagination ────────────────────────────────────────────────────────────
  static const int _pageSize = 10;
  int _currentPage = 1;

  int get _totalPages {
    final total = _filteredRecords.length;
    return total == 0 ? 1 : ((total + _pageSize - 1) ~/ _pageSize);
  }

  List<Map<String, dynamic>> get _pagedRecords {
    final filtered = _filteredRecords;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];

    final end = (start + _pageSize > filtered.length)
        ? filtered.length
        : start + _pageSize;

    return filtered.sublist(start, end);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    ActivityService.logActivity(
      activityType: 'SCREEN',
      activityName: 'AccCancelApproveScreen',
      screenName: 'AccCancelApproveScreen',
    );

    _loadData();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load Data
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getAccCancelApproveGrid();

      if (!mounted) return;

      setState(() {
        _records = data;
        _currentPage = 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Edit action — called when user taps "Edit" on a row
  // ─────────────────────────────────────────────────────────────────────────

  void _onEdit(Map<String, dynamic> record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'AccCancelApproveFormScreen'),
        builder: (_) => AccCancelApproveFormScreen(
          unqid: _v(record['sp_432']),
          slipNo: _v(record['sp_438']),
        ),
      ),
    ).then((_) {
      // Reload the grid when returning — an item may now be fully approved
      if (mounted) _loadData();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),

        title: Builder(
          builder: (context) {
            final width = MediaQuery.sizeOf(context).width;
            return Text(
              'Acc. Cancellation Approval',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: width < 360 ? 14 : 17,
              ),
            );
          },
        ),

        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0A2A5C), Color(0xFF1A4A8C)]
                  : const [_primary, _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),

      body: _buildBody(context),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Loading cancellation requests…',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 14),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: _hPad(constraints.maxWidth),
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(constraints.maxWidth),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 12),
                if (_filteredRecords.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildContent(constraints),
                  const SizedBox(height: 14),
                  _buildPagination(constraints.maxWidth),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Responsive padding
  // ─────────────────────────────────────────────────────────────────────────

  double _hPad(double w) {
    if (w < 360) return 8;
    if (w < 600) return 12;
    if (w < 900) return 16;
    if (w < 1200) return 20;
    return 28;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (val) => setState(() {
        _searchQuery = val.trim();
        _currentPage = 1;
      }),
      decoration: InputDecoration(
        hintText: 'Search by Customer Name or VIN No…',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _searchQuery = '';
                    _currentPage = 1;
                  });
                },
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Summary card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(double width) {
    final compact = width < 600;
    final xl = width >= 1200;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact
            ? 14
            : xl
            ? 24
            : 18,
        vertical: compact
            ? 12
            : xl
            ? 20
            : 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.cancel_presentation_rounded,
              color: Colors.white,
              size: compact ? 21 : 25,
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accessories Cancellation Approval',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact
                        ? 14
                        : xl
                        ? 18
                        : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending accessory cancellation requests',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_records.length}',
              style: TextStyle(
                color: _primary,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No pending cancellation approvals',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'All accessory cancellation requests have been processed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Content router
  //
  // < 600  → cards  (mobile)
  // ≥ 600  → table  (tablet / desktop)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    if (w < 360) return _buildCards(compact: true);
    if (w < 600) return _buildCards(compact: false);
    return _buildTable(compact: w < 900, xl: w >= 1200);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TABLE  — 3 data columns + Edit action
  //
  // Columns: Slip No | Customer Name | VIN No | Action
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTable({bool compact = false, bool xl = false}) {
    final theme = Theme.of(context);
    final hPad = xl
        ? 20.0
        : compact
        ? 10.0
        : 16.0;
    final vPad = xl
        ? 14.0
        : compact
        ? 10.0
        : 12.0;
    final hFs = xl
        ? 13.0
        : compact
        ? 11.0
        : 12.0;
    final dFs = xl
        ? 13.0
        : compact
        ? 11.0
        : 12.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.0), // Slip No
            1: FlexColumnWidth(2.8), // Customer Name
            2: FlexColumnWidth(2.0), // VIN No
            3: IntrinsicColumnWidth(), // Action (Edit button)
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // ── Header ────────────────────────────────────────────
            TableRow(
              decoration: const BoxDecoration(color: _primary),
              children: [
                _th('Slip No', hPad: hPad, vPad: vPad, fs: hFs),
                _th('Customer Name', hPad: hPad, vPad: vPad, fs: hFs),
                _th('VIN No', hPad: hPad, vPad: vPad, fs: hFs),
                _th('Action', hPad: hPad, vPad: vPad, fs: hFs, center: true),
              ],
            ),

            // ── Data rows ─────────────────────────────────────────
            ...List.generate(_pagedRecords.length, (i) {
              final r = _pagedRecords[i];
              final even = i % 2 == 0;

              return TableRow(
                decoration: BoxDecoration(
                  color: even
                      ? theme.cardColor
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.35,
                        ),
                ),
                children: [
                  _td(_v(r['sp_438']), hPad: hPad, vPad: vPad, fs: dFs),
                  _td(
                    _v(r['sp_440']),
                    hPad: hPad,
                    vPad: vPad,
                    fs: dFs,
                    bold: true,
                  ),
                  _td(_v(r['sp_441']), hPad: hPad, vPad: vPad, fs: dFs),
                  // ── Edit button ──────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad * 0.6,
                      vertical: vPad * 0.5,
                    ),
                    child: _editBtn(r, compact: compact),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARDS  — mobile view
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCards({bool compact = false}) {
    return Column(
      children: List.generate(
        _pagedRecords.length,
        (i) => _buildCard(
          ((_currentPage - 1) * _pageSize) + i + 1,
          _pagedRecords[i],
          compact: compact,
        ),
      ),
    );
  }

  Widget _buildCard(int idx, Map<String, dynamic> r, {bool compact = false}) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: index badge + customer name + edit button ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Index badge
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$idx',
                  style: TextStyle(
                    color: _primary,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Customer name
              Expanded(
                child: Text(
                  _v(r['sp_440']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              _editBtn(r, compact: compact),
            ],
          ),

          Divider(height: compact ? 18 : 22, color: Colors.grey.shade200),

          // ── Slip No row ─────────────────────────────────────────
          _infoRow(
            Icons.receipt_outlined,
            'Slip No',
            _v(r['sp_438']),
            compact: compact,
          ),
          SizedBox(height: compact ? 7 : 9),

          // ── VIN No row ──────────────────────────────────────────
          _infoRow(
            Icons.confirmation_number_outlined,
            'VIN No',
            _v(r['sp_441']),
            compact: compact,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pagination
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPagination(double width) {
    final compact = width < 600;

    if (_totalPages <= 1) {
      return _paginationContainer(
        child: Text(
          'Showing ${_filteredRecords.length} of ${_records.length} records',
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final total = _filteredRecords.length;
    final start = ((_currentPage - 1) * _pageSize) + 1;
    final end = (_currentPage * _pageSize > total)
        ? total
        : _currentPage * _pageSize;

    return _paginationContainer(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: [
          _pageButton(
            icon: Icons.chevron_left_rounded,
            label: compact ? null : 'Prev',
            enabled: _currentPage > 1,
            onPressed: () => setState(() => _currentPage--),
            compact: compact,
          ),

          ..._pageNumbers(compact),

          _pageButton(
            icon: Icons.chevron_right_rounded,
            label: compact ? null : 'Next',
            enabled: _currentPage < _totalPages,
            onPressed: () => setState(() => _currentPage++),
            compact: compact,
          ),

          const SizedBox(width: 6),
          Text(
            '$start-$end of $total',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginationContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  List<Widget> _pageNumbers(bool compact) {
    final pages = <int>[];

    if (_totalPages <= 7) {
      for (int i = 1; i <= _totalPages; i++) {
        pages.add(i);
      }
    } else {
      pages.add(1);

      if (_currentPage > 4) {
        // Ellipsis handled below.
      }

      final start = (_currentPage - 1).clamp(2, _totalPages - 1);
      final end = (_currentPage + 1).clamp(2, _totalPages - 1);

      if (_currentPage > 4) {
        pages.add(-1);
      }

      for (int i = start; i <= end; i++) {
        pages.add(i);
      }

      if (_currentPage < _totalPages - 3) {
        pages.add(-1);
      }

      pages.add(_totalPages);
    }

    return pages.map((page) {
      if (page == -1) {
        return SizedBox(
          width: 20,
          child: Text(
            '...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }

      final active = page == _currentPage;

      return SizedBox(
        width: compact ? 32 : 36,
        height: compact ? 30 : 34,
        child: ElevatedButton(
          onPressed: active ? null : () => setState(() => _currentPage = page),
          style: ElevatedButton.styleFrom(
            backgroundColor: active ? _primary : Colors.transparent,
            foregroundColor: active ? Colors.white : _primary,
            disabledBackgroundColor: _primary,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(
              color: active ? _primary : _primary.withOpacity(0.25),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _pageButton({
    required IconData icon,
    required String? label,
    required bool enabled,
    required VoidCallback onPressed,
    required bool compact,
  }) {
    return SizedBox(
      height: compact ? 30 : 34,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: compact ? 17 : 18),
        label: label == null
            ? const SizedBox.shrink()
            : Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
          minimumSize: Size(compact ? 32 : 70, compact ? 30 : 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Edit button widget — green pill matching the screenshot
  // ─────────────────────────────────────────────────────────────────────────

  Widget _editBtn(Map<String, dynamic> record, {bool compact = false}) {
    return SizedBox(
      height: compact ? 28 : 32,
      child: ElevatedButton(
        onPressed: () => _onEdit(record),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          'Edit',
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Info row (mobile cards)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool compact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: compact ? 16 : 18, color: _accent),
        const SizedBox(width: 8),
        SizedBox(
          width: compact ? 58 : 65,
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: compact ? 11 : 12),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Table cell helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _th(
    String text, {
    required double hPad,
    required double vPad,
    required double fs,
    bool center = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: Colors.white,
          fontSize: fs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _td(
    String text, {
    required double hPad,
    required double vPad,
    required double fs,
    bool bold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fs,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _v(dynamic v) {
    if (v == null) return '-';
    final t = v.toString().trim();
    return t.isEmpty ? '-' : t;
  }
}
