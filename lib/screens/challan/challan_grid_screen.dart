import 'package:flutter/material.dart';

import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import 'challan_edit_new_screen.dart';
import 'challan_form_screen.dart';

/// Challan grid — responsive horizontal-scroll table.
/// Header and body use separate controllers that mirror each other via
/// NotificationListener so they scroll in sync without the "two clients on
/// one ScrollController" error.
class ChallanGridScreen extends StatefulWidget {
  const ChallanGridScreen({super.key});

  @override
  State<ChallanGridScreen> createState() => _ChallanGridScreenState();
}

class _ChallanGridScreenState extends State<ChallanGridScreen> {
  static const Color _primary = Color(0xFF0D3F8A);

  // ── Column minimum widths ──────────────────────────────────────────────────
  static const double _cDate = 82;
  static const double _cNo = 82;
  static const double _cType = 112;
  static const double _cCust = 150;
  static const double _cVin = 142;
  static const double _cVariant = 135;
  static const double _cAmt = 82;
  static const double _cStatus = 75;
  static const double _cAction = 95; // icon-only buttons — compact

  static const double _minW =
      _cDate +
      _cNo +
      _cType +
      _cCust +
      _cVin +
      _cVariant +
      _cAmt +
      _cStatus +
      _cAction;

  // Two controllers that mirror each other
  final ScrollController _hCtrl = ScrollController();
  final ScrollController _bCtrl = ScrollController();
  bool _syncing = false;

  bool loading = true;
  bool searching = false;
  String? error;

  List<Map<String, dynamic>> rows = [];
  int totalRows = 0;
  int currentPage = 1;
  final int pageSize = 10;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ActivityService.logActivity(
      activityType: 'SCREEN',
      activityName: 'ChallanGridScreen',
      screenName: 'ChallanGridScreen',
    );
    _loadInitial();
  }

  @override
  void dispose() {
    searchController.dispose();
    _hCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  // ── Mirror scroll ──────────────────────────────────────────────────────────

  void _onHeaderScroll() {
    if (_syncing) return;
    if (_bCtrl.hasClients && _hCtrl.hasClients) {
      _syncing = true;
      _bCtrl.jumpTo(_hCtrl.offset);
      _syncing = false;
    }
  }

  void _onBodyScroll() {
    if (_syncing) return;
    if (_hCtrl.hasClients && _bCtrl.hasClients) {
      _syncing = true;
      _hCtrl.jumpTo(_bCtrl.offset);
      _syncing = false;
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadInitial() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
      currentPage = 1;
    });
    try {
      final total = await ApiService.getChallanGridTotal(search: '');
      final data = await ApiService.getChallanGrid(
        page: 1,
        pageSize: pageSize,
        search: '',
      );
      if (!mounted) return;
      setState(() {
        totalRows = _int(total);
        rows = _norm(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
        rows = [];
      });
    }
  }

  Future<void> _search() async {
    final q = searchController.text.trim();
    if (q.isEmpty) {
      await _loadInitial();
      return;
    }
    if (!mounted) return;
    setState(() {
      searching = true;
      error = null;
      currentPage = 1;
    });
    try {
      final total = await ApiService.getChallanGridTotal(search: q);
      final data = await ApiService.searchChallanGrid(
        search: q,
        page: 1,
        pageSize: pageSize,
      );
      if (!mounted) return;
      setState(() {
        totalRows = _int(total);
        rows = _norm(data);
        searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        searching = false;
        error = e.toString();
        rows = [];
      });
    }
  }

  Future<void> _changePage(int page) async {
    if (page < 1 || page == currentPage || page > _pageCount) return;
    if (!mounted) return;
    setState(() {
      loading = true;
      currentPage = page;
      error = null;
    });
    try {
      final data = await ApiService.getChallanGridPage(
        page: page,
        pageSize: pageSize,
        search: searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        rows = _norm(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final q = searchController.text.trim();
      final total = await ApiService.getChallanGridTotal(search: q);
      final safeP = currentPage.clamp(
        1,
        ((total + pageSize - 1) ~/ pageSize).clamp(1, 999999),
      );
      final data = q.isEmpty
          ? await ApiService.getChallanGridPage(
              page: safeP,
              pageSize: pageSize,
              search: '',
            )
          : await ApiService.searchChallanGrid(
              search: q,
              page: safeP,
              pageSize: pageSize,
            );
      if (!mounted) return;
      setState(() {
        totalRows = total;
        currentPage = safeP;
        rows = _norm(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = _v(row, 'sp_462');
    if (id.isEmpty) {
      _msg('Challan unique ID is missing.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(
          'Delete Challan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await ApiService.deleteChallanGridRecord(unqId: id);
      final s = res['success'] == true;
      _msg(
        res['message']?.toString() ??
            res['error']?.toString() ??
            (s ? 'Deleted' : 'Delete failed'),
      );
      if (s) await _reload();
    } catch (e) {
      if (mounted) _msg('Delete failed: $e');
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final id = _v(row, 'sp_462');
    if (id.isEmpty) {
      _msg('Challan unique ID is missing.');
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ChallanEdit_New_screen'),
        builder: (_) => ChallanEditNewScreen(sp462: id),
      ),
    );
    if (result == true && mounted) await _reload();
  }

  Future<void> _newChallan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ChallanFormScreen'),
        builder: (_) => const ChallanFormScreen(),
      ),
    );
    if (result == true && mounted) await _reload();
  }

  Future<void> _print(Map<String, dynamic> row) async {
    final id = _v(row, 'sp_462');
    if (id.isEmpty) {
      _msg('Challan unique ID is missing.');
      return;
    }
    await ApiService.printChallan(id);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _norm(dynamic v) {
    if (v is List)
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    if (v is Map) {
      final d = v['data'] ?? v['rows'] ?? v['Table'];
      if (d is List)
        return d
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    }
    return [];
  }

  int _int(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _v(Map<String, dynamic> row, String key) {
    final val = row[key];
    if (val == null || val.toString().trim() == 'null') return '';
    return val.toString().trim();
  }

  String _date(Map<String, dynamic> row) {
    final raw = _v(row, 'sp_467');
    if (raw.isEmpty) return '-';
    final s = raw.contains('T') ? raw.split('T').first : raw;
    final p = s.split('-');
    return p.length == 3 ? '${p[2]}-${p[1]}-${p[0]}' : s;
  }

  int get _pageCount =>
      totalRows <= 0 ? 1 : (totalRows + pageSize - 1) ~/ pageSize;

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
      );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Challan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _searchBar(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? _errorView()
                : _gridCard(),
          ),
          _pager(),
          _newChallanButton(),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      color: AppColors.card(context),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          _loadInitial();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
                filled: true,
                fillColor: AppColors.bg(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: searching ? null : _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Search',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load challans',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid card ──────────────────────────────────────────────────────────────

  Widget _gridCard() {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No challans found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            // If screen is wide enough → expand columns; else → scroll.
            final tableW = constraints.maxWidth >= _minW
                ? constraints.maxWidth
                : _minW;

            return Column(
              children: [
                // ── Header ──
                _SyncScroll(
                  controller: _hCtrl,
                  onScroll: _onHeaderScroll,
                  child: _buildHeader(tableW),
                ),
                // ── Rows ──
                Expanded(
                  child: _SyncScroll(
                    controller: _bCtrl,
                    onScroll: _onBodyScroll,
                    child: SizedBox(
                      width: tableW,
                      child: ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (_, i) => _buildRow(rows[i], i, tableW),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header row ─────────────────────────────────────────────────────────────

  Widget _buildHeader(double tableW) {
    return Container(
      width: tableW,
      color: _primary,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: _tableRow(
        tableW: tableW,
        cells: [
          _cell('Date', align: TextAlign.left),
          _cell('Challan No', align: TextAlign.left),
          _cell('Type', align: TextAlign.left),
          _cell('Customer Name', align: TextAlign.left),
          _cell('Vin No', align: TextAlign.left),
          _cell('Variant', align: TextAlign.left),
          _cell('Net Amount', align: TextAlign.right),
          _cell('Status', align: TextAlign.center),
          _cell('Action', align: TextAlign.center),
        ],
        isHeader: true,
      ),
    );
  }

  Widget _cell(String t, {TextAlign align = TextAlign.left, Color? color}) =>
      Text(
        t,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? Colors.white,
        ),
      );

  // ── Data row ───────────────────────────────────────────────────────────────

  Widget _buildRow(Map<String, dynamic> row, int index, double tableW) {
    final bg = index.isEven ? Colors.white : const Color(0xFFF5F7FB);

    final statusText = _v(row, 'status');
    final statusColor = statusText.toLowerCase() == 'approved'
        ? const Color(0xFF059669)
        : statusText.toLowerCase() == 'reject'
        ? const Color(0xFFDC2626)
        : const Color(0xFFF59E0B);

    return Container(
      width: tableW,
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: _tableRow(
              tableW: tableW,
              isHeader: false,
              cells: [
                // Date
                Text(
                  _date(row),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Challan No
                Text(
                  _v(row, 'sp_468').isEmpty ? '-' : _v(row, 'sp_468'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Type
                Text(
                  _v(row, 'sp_558').isEmpty ? '-' : _v(row, 'sp_558'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Customer Name
                Text(
                  _v(row, 'sp_469').isEmpty ? '-' : _v(row, 'sp_469'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Vin No
                Text(
                  _v(row, 'sp_473').isEmpty ? '-' : _v(row, 'sp_473'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1A56DB),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Variant
                Text(
                  _v(row, 'sp_471').isEmpty ? '-' : _v(row, 'sp_471'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Net Amount
                Text(
                  _v(row, 'sp_521').isEmpty ? '-' : _v(row, 'sp_521'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Status
                statusText.isEmpty
                    ? const SizedBox.shrink()
                    : Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            statusText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                // Action — 3 icon buttons, always fits in _cAction width
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconBtn(
                      Icons.edit_outlined,
                      const Color(0xFF1A56DB),
                      () => _edit(row),
                      'Edit',
                    ),
                    const SizedBox(width: 3),
                    _iconBtn(
                      Icons.print_outlined,
                      const Color(0xFF059669),
                      () => _print(row),
                      'Print',
                    ),
                    const SizedBox(width: 3),
                    _iconBtn(
                      Icons.delete_outline_rounded,
                      const Color(0xFFDC2626),
                      () => _delete(row),
                      'Del',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, indent: 6, endIndent: 6),
        ],
      ),
    );
  }

  /// Lays out exactly 9 widgets in a Row, each in a SizedBox.
  /// Columns are scaled so they fill [tableW] minus the 6+6 px horizontal
  /// padding that surrounds the Row, preventing overflow.
  static const double _rowPadH = 12.0; // 6px left + 6px right

  Widget _tableRow({
    required double tableW,
    required List<Widget> cells,
    required bool isHeader,
  }) {
    assert(cells.length == 9);
    // Usable width = container width minus horizontal padding
    final usable = tableW - _rowPadH;
    final scale = usable / _minW;
    final mins = [
      _cDate,
      _cNo,
      _cType,
      _cCust,
      _cVin,
      _cVariant,
      _cAmt,
      _cStatus,
      _cAction,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(
        9,
        (i) => SizedBox(width: mins[i] * scale, child: cells[i]),
      ),
    );
  }

  /// Compact square icon button — guaranteed to fit in a narrow column.
  Widget _iconBtn(
    IconData icon,
    Color color,
    VoidCallback onTap,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  // ── New Challan button bar ─────────────────────────────────────────────────

  Widget _newChallanButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          border: Border(
            top: BorderSide(color: _primary.withValues(alpha: 0.12)),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _newChallan,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New Challan',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  // ── Pager ──────────────────────────────────────────────────────────────────

  Widget _pager() {
    final pages = _pageCount;
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final total = Text(
            'Total: $totalRows',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          );
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Previous',
                onPressed: currentPage > 1
                    ? () => _changePage(currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$currentPage / $pages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: currentPage < pages
                    ? () => _changePage(currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          );

          return Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              border: Border(
                top: BorderSide(color: _primary.withValues(alpha: 0.12)),
              ),
            ),
            child: constraints.maxWidth < 400
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: total),
                      Center(child: controls),
                    ],
                  )
                : Row(
                    children: [
                      total,
                      Expanded(child: Center(child: controls)),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ── Sync-scrollable wrapper ────────────────────────────────────────────────────
/// Wraps a child in a horizontal SingleChildScrollView and calls [onScroll]
/// whenever the position changes so the paired scrollable can mirror it.
class _SyncScroll extends StatelessWidget {
  final ScrollController controller;
  final VoidCallback onScroll;
  final Widget child;

  const _SyncScroll({
    required this.controller,
    required this.onScroll,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification) onScroll();
        return false;
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: controller,
        child: child,
      ),
    );
  }
}
