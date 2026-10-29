import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import 'finance_details_screen.dart';

class FinanceGridScreen extends StatefulWidget {
  const FinanceGridScreen({super.key});

  @override
  State<FinanceGridScreen> createState() => _FinanceGridScreenState();
}

class _FinanceGridScreenState extends State<FinanceGridScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const Color _primary = Color(0xFF12458F);
  static const Color _blue = Color(0xFF286BE0);
  static const Color _pageBackground = Color(0xFFF3F7FD);
  static const int _pageSize = 10;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surfaceColor => _isDark ? const Color(0xFF182333) : Colors.white;
  Color get _raisedSurfaceColor =>
      _isDark ? const Color(0xFF202E40) : const Color(0xFFF8FAFE);
  Color get _mainTextColor =>
      _isDark ? const Color(0xFFF1F5FB) : const Color(0xFF27364B);
  Color get _secondaryTextColor =>
      _isDark ? const Color(0xFFB3C0D2) : const Color(0xFF6C7A90);
  Color get _borderColor =>
      _isDark ? const Color(0xFF39495E) : const Color(0xFFDCE4F0);

  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = false;
  int? _totalRecords;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadGrid(page: 1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _value(Map<String, dynamic> row, String key) {
    for (final entry in row.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) {
        final value = entry.value;
        if (value == null || value.toString() == 'null') return '';
        return value.toString().trim();
      }
    }
    return '';
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Future<void> _loadGrid({int? page}) async {
    final requestedPage = page ?? _page;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please sign in again.');
      }

      final uri = Uri.parse('${ApiService.baseUrl}/api/finance/grid').replace(
        queryParameters: {
          'page': requestedPage.toString(),
          'limit': _pageSize.toString(),
          if (_searchController.text.trim().isNotEmpty)
            'search': _searchController.text.trim(),
        },
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Unable to load finance records.',
        );
      }

      final rawData = decoded['data'];
      final rows = rawData is List
          ? rawData
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
          : <Map<String, dynamic>>[];

      // The API can return any one of these total-count field names.
      final total = _readInt(
        decoded['totalRecords'] ??
            decoded['totalCount'] ??
            decoded['total'] ??
            decoded['count'],
      );

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _page = requestedPage;
        _hasMore =
            decoded['hasMore'] == true ||
            (total != null && requestedPage * _pageSize < total);
        _totalRecords = total;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _rows = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadGrid(page: 1),
    );
  }

  Future<void> _openRecord(String financeId) async {
    if (financeId.isEmpty) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FinanceDetailsScreen(financeId: financeId),
      ),
    );
    if (!mounted) return;
    if (result == true) await _loadGrid();
  }

  Widget _status(String value) {
    final normalized = value.toLowerCase();
    final approved = normalized == 'approved';
    final rejected = normalized == 'rejected';
    final color = approved
        ? const Color(0xFF269653)
        : rejected
        ? const Color(0xFFD84343)
        : const Color(0xFFEF7D13);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        value.isEmpty ? 'Pending' : value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'View and manage customer finance records',
                  style: TextStyle(color: Color(0xFFDCE8FF), fontSize: 12),
                ),
              ],
            ),
          ),
          if (_totalRecords != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_totalRecords',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by customer name...',
        hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: _primary),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  _loadGrid(page: 1);
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: _surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _blue, width: 1.4),
        ),
      ),
    );
  }

  Widget _mobileCard(Map<String, dynamic> row) {
    final customer = _value(row, 'm1_7');
    final amount = _value(row, 'sp_696');

    Widget detail(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(color: _secondaryTextColor, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: _mainTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      color: _surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    customer.isEmpty ? 'Unknown customer' : customer,
                    style: TextStyle(
                      color: _mainTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            detail('Booking date', _value(row, 'sp_686')),
            detail('Arrangement', _value(row, 'sp_687')),
            detail('Financer', _value(row, 'HP_7')),
            detail('Branch', _value(row, 'sp_689')),
            detail('Loan amount', '₹$amount'),
            detail('Expected delivery', _formatDate(_value(row, 'sp_697'))),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _status(_value(row, 'sp_692')),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String value) {
    if (value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final d = parsed.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Widget _desktopTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final table = DataTable(
          horizontalMargin: 18,
          columnSpacing: 20,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 58,
          headingRowHeight: 44,
          headingRowColor: WidgetStateProperty.all(_primary),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          dataTextStyle: TextStyle(color: _mainTextColor, fontSize: 12),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected)
                ? _blue.withValues(alpha: _isDark ? 0.24 : 0.10)
                : null,
          ),
          columns: const [
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Booking Date')),
            DataColumn(label: Text('Arrangement')),
            DataColumn(label: Text('Financer')),
            DataColumn(label: Text('Branch')),
            DataColumn(label: Text('Loan Amount')),
            DataColumn(label: Text('Expected Delivery')),
            DataColumn(label: Text('Status')),
          ],
          rows: _rows.map((row) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                (states) => _rows.indexOf(row).isOdd
                    ? (_isDark
                          ? const Color(0xFF1D2A3B)
                          : const Color(0xFFF6F9FE))
                    : null,
              ),
              cells: [
                DataCell(
                  SizedBox(
                    width: 245,
                    child: Text(
                      _value(row, 'm1_7'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(_formatDate(_value(row, 'sp_686')))),
                DataCell(Text(_value(row, 'sp_687'))),
                DataCell(
                  SizedBox(
                    width: 230,
                    child: Text(
                      _value(row, 'HP_7'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 165,
                    child: Text(
                      _value(row, 'sp_689'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text('₹${_value(row, 'sp_696')}')),
                DataCell(Text(_formatDate(_value(row, 'sp_697')))),
                DataCell(_status(_value(row, 'sp_692'))),
              ],
            );
          }).toList(),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: table,
          ),
        );
      },
    );
  }

  List<int> _visiblePages() {
    if (_totalRecords != null) {
      final totalPages = (_totalRecords! / _pageSize).ceil();
      if (totalPages <= 0) return [];
      final start = (_page - 2).clamp(1, totalPages);
      final end = (start + 4).clamp(1, totalPages);
      final adjustedStart = (end - 4).clamp(1, totalPages);
      return [for (int p = adjustedStart; p <= end; p++) p];
    }

    // When the API only returns hasMore, do not invent a total page count.
    final start = (_page - 2).clamp(1, _page);
    final end = _page + (_hasMore ? 2 : 0);
    return [for (int p = start; p <= end; p++) p];
  }

  Widget _pagination() {
    final startRecord = _rows.isEmpty ? 0 : ((_page - 1) * _pageSize) + 1;
    final endRecord = ((_page - 1) * _pageSize) + _rows.length;
    final totalText = _totalRecords != null
        ? '$startRecord–$endRecord of $_totalRecords'
        : '$startRecord–$endRecord';

    final pages = _visiblePages();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173A69).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _loading || _page <= 1
                ? null
                : () => _loadGrid(page: _page - 1),
            icon: const Icon(Icons.chevron_left, size: 17),
            label: const Text('Prev'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isDark ? const Color(0xFFBBD2FF) : _primary,
              side: BorderSide(color: _borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              minimumSize: const Size(0, 36),
            ),
          ),
          for (final page in pages)
            SizedBox(
              height: 36,
              width: 36,
              child: page == _page
                  ? ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text('$page'),
                    )
                  : OutlinedButton(
                      onPressed: _loading ? null : () => _loadGrid(page: page),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isDark
                            ? const Color(0xFFBBD2FF)
                            : _primary,
                        side: BorderSide(color: _borderColor),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text('$page'),
                    ),
            ),
          OutlinedButton.icon(
            onPressed: _loading || !_hasMore
                ? null
                : () => _loadGrid(page: _page + 1),
            icon: const Icon(Icons.chevron_right, size: 17),
            label: const Text('Next'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isDark ? const Color(0xFFBBD2FF) : _primary,
              side: BorderSide(color: _borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              minimumSize: const Size(0, 36),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              totalText,
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF101722) : _pageBackground,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Finance Grid',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Add finance',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const FinanceDetailsScreen()),
              );
              if (!mounted) return;
              if (result == true) await _loadGrid(page: 1);
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _loadGrid(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isWide ? 20 : 12,
            14,
            isWide ? 20 : 12,
            14,
          ),
          child: Column(
            children: [
              _heroCard(),
              const SizedBox(height: 12),
              _searchBox(),
              if (_loading) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 2,
                  color: _blue,
                  backgroundColor: _isDark
                      ? const Color(0xFF34445A)
                      : const Color(0xFFDCE7F8),
                ),
              ],
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFF3A2228)
                        : const Color(0xFFFFEEEE),
                    border: Border.all(
                      color: _isDark
                          ? const Color(0xFF75404A)
                          : const Color(0xFFFFD2D2),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: _isDark ? const Color(0xFFFF8A8A) : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: _isDark
                                ? const Color(0xFFFFB4AB)
                                : const Color(0xFFB3261E),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _loadGrid(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading && _rows.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: _blue),
                      )
                    : _rows.isEmpty
                    ? Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: _surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.inbox_outlined,
                                size: 42,
                                color: Color(0xFF91A1B8),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _error == null
                                    ? 'No finance records found'
                                    : 'Unable to display finance records',
                                style: TextStyle(
                                  color: _secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF173A69,
                              ).withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        // Use the same horizontally scrollable table on mobile
                        // and desktop instead of switching to stacked cards.
                        // On narrow screens, users can swipe horizontally to
                        // view the remaining finance columns.
                        child: _desktopTable(),
                      ),
              ),
              const SizedBox(height: 10),
              _pagination(),
            ],
          ),
        ),
      ),
    );
  }
}
