import 'package:flutter/material.dart';

import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AccCancelApproveFormScreen
//
// Opened when the user taps "Edit" on a row in AccCancelApproveScreen.
// Mirrors frm_mannul_requisition_cancel_approve_slip.aspx:
//   • Header fields  — date, customer, slip no, address, vin, model, variant,
//                      color, docket amounts
//   • GridView 3     — Docket/package grid  (Category · Qty · MRP · Status)
//   • GridView 1     — Accessories grid     (S.No · Spares Name · Part No ·
//                                            Qty · MRP · Approve / Reject)
//     Each accessories row shows green "Approve" and red "Reject" buttons.
//     Approve is disabled once cancelappdate is already set (year != 1900).
// ─────────────────────────────────────────────────────────────────────────────

class AccCancelApproveFormScreen extends StatefulWidget {
  final String unqid; // sp_432 — primary key of rh_sp_43
  final String slipNo; // sp_438 — shown in AppBar title

  const AccCancelApproveFormScreen({
    super.key,
    required this.unqid,
    required this.slipNo,
  });

  @override
  State<AccCancelApproveFormScreen> createState() =>
      _AccCancelApproveFormScreenState();
}

class _AccCancelApproveFormScreenState
    extends State<AccCancelApproveFormScreen> {
  // ── theme ────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF0D3F8A);
  static const Color _accent = Color(0xFF2C6CE0);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _red = Color(0xFFD32F2F);

  // ── state ────────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _header;
  List<Map<String, dynamic>> _docketRows = [];
  List<Map<String, dynamic>> _detailRows = [];

  // tracks which child-unqids are currently being acted on
  final Set<String> _processingIds = {};

  // ── Spares Entry form controllers ─────────────────────────────────────
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _partNoCtrl = TextEditingController();
  final TextEditingController _sparesCtrl = TextEditingController();
  final TextEditingController _issueQtyCtrl = TextEditingController();
  final TextEditingController _mrpCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  // ── lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    ActivityService.logActivity(
      activityType: 'SCREEN',
      activityName: 'AccCancelApproveFormScreen',
      screenName: 'AccCancelApproveFormScreen',
    );

    _loadAll();
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _partNoCtrl.dispose();
    _sparesCtrl.dispose();
    _issueQtyCtrl.dispose();
    _mrpCtrl.dispose();
    _discountCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ── load ─────────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. fetch header first so we can get the customer unqid for docket
      final header = await ApiService.getAccCancelSlipHeader(widget.unqid);

      if (!mounted) return;

      final custUnq = _sv(header?['sp_440']);

      // 2. fetch details + docket in parallel.
      //
      // Amounts are taken directly from the requisition header:
      //   sp_445 = Accessories Amount
      //   sp_446 = Discount %
      //   sp_447 = Discount Amount
      //   sp_448 = Total Amount
      final results = await Future.wait([
        ApiService.getAccCancelDetails(widget.unqid),
        custUnq.isNotEmpty
            ? ApiService.getAccCancelDocket(custUnq)
            : Future.value(<Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _header = header;
        _detailRows = results[0] as List<Map<String, dynamic>>;
        _docketRows = results[1] as List<Map<String, dynamic>>;
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

  // ── approve / reject ─────────────────────────────────────────────────────

  Future<void> _approve(Map<String, dynamic> row) async {
    final childUnq = _sv(row['childunq']);
    if (childUnq.isEmpty) return;

    final confirm = await _showConfirm(
      title: 'Approve Cancellation',
      message: 'Approve cancellation for\n${_sv(row['sp_451'])}?',
      confirmLabel: 'Approve',
      confirmColor: _green,
    );
    if (confirm != true || !mounted) return;

    setState(() => _processingIds.add(childUnq));

    try {
      await ApiService.approveAccCancel(childUnq);
      if (!mounted) return;

      _showSnack('Approved: ${_sv(row['sp_451'])}', _green);
      // Navigate back to the grid so the user sees the updated list
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Error: ${e.toString().replaceFirst('Exception: ', '')}',
        _red,
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(childUnq));
    }
  }

  Future<void> _reject(Map<String, dynamic> row) async {
    final childUnq = _sv(row['childunq']);
    if (childUnq.isEmpty) return;

    final reason = await _showRejectDialog();
    if (reason == null || !mounted) return; // cancelled

    setState(() => _processingIds.add(childUnq));

    try {
      await ApiService.rejectAccCancel(childUnq, reason);
      if (!mounted) return;

      _showSnack('Rejected: ${_sv(row['sp_451'])}', _red);
      // Navigate back to the grid so the user sees the updated list
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Error: ${e.toString().replaceFirst('Exception: ', '')}',
        _red,
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(childUnq));
    }
  }

  // ── dialogs ──────────────────────────────────────────────────────────────

  Future<bool?> _showConfirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Rejection Reason',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter rejection reason…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final txt = ctrl.text.trim();
              if (txt.isEmpty) return;
              Navigator.pop(context, txt);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit Rejection'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  void _showSnack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
        title: Text(
          'Cancel Approve — Slip ${widget.slipNo}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
            onPressed: _loading ? null : _loadAll,
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Loading slip data…', style: TextStyle(fontSize: 14)),
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
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hPad = _hPad(constraints.maxWidth);
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header fields ────────────────────────────────────
                _buildHeaderCard(constraints.maxWidth),

                const SizedBox(height: 20),

                // ── Docket / package grid ────────────────────────────
                if (_docketRows.isNotEmpty) ...[
                  _sectionTitle('Docket Package Details'),
                  const SizedBox(height: 8),
                  _buildDocketTable(constraints.maxWidth),
                  const SizedBox(height: 20),
                ],

                // ── Spares Entry input form ───────────────────────────
                _sectionTitle('Spares Entry'),
                const SizedBox(height: 8),
                _buildSparesEntryForm(constraints.maxWidth),
                const SizedBox(height: 8),
                _buildTotalsBar(constraints.maxWidth),
                const SizedBox(height: 20),

                // ── Accessories (cancel-pending) grid ─────────────────
                _sectionTitle('Spares Entry — Pending Cancellation Approval'),
                const SizedBox(height: 8),
                if (_detailRows.isEmpty)
                  _buildEmptyDetails()
                else
                  _buildDetailsGrid(constraints),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Computed totals  (task #2)
  // ─────────────────────────────────────────────────────────────────────────

  /// Safely converts a database/API value to a number.
  double _num(dynamic value) {
    if (value == null) return 0;

    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }

  /// Accessories Amount from requisition header: sp_445.
  double get _accessoriesTotal {
    return _num(_header?['sp_445']);
  }

  /// Discount Amount from requisition header: sp_447.
  double get _discountTotal {
    return _num(_header?['sp_447']);
  }

  /// Total Amount from requisition header: sp_448.
  double get _grandTotal {
    return _num(_header?['sp_448']);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section title
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeaderCard(double width) {
    final h = _header;
    final compact = width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: _primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cancel Approve Requisition Slip',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 22),

          // Row 1: Date | Customer Name | Slip No
          if (compact)
            _fieldCol([
              _field('Date', _sv(h?['sp_437'])),
              _field('Customer Name', _sv(h?['sp_440_name'])),
              _field('Slip No', _sv(h?['sp_438'])),
            ])
          else
            Row(
              children: [
                Expanded(child: _field('Date', _sv(h?['sp_437']))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _field('Customer Name', _sv(h?['sp_440_name'])),
                ),
                const SizedBox(width: 12),
                Expanded(child: _field('Slip No', _sv(h?['sp_438']))),
              ],
            ),

          const SizedBox(height: 10),

          // Row 2: Address (full width)
          _field('Address', _sv(h?['address'])),

          const SizedBox(height: 10),

          // Row 3: VIN | Model | Variant | Color
          if (compact)
            _fieldCol([
              _field('VIN No', _sv(h?['sp_441'])),
              _field('Model', _sv(h?['sp_442_model'])),
              _field('Variant', _sv(h?['sp_443_variant'])),
              _field('Color', _sv(h?['sp_444_color'])),
            ])
          else
            Row(
              children: [
                Expanded(child: _field('VIN No', _sv(h?['sp_441']))),
                const SizedBox(width: 12),
                Expanded(child: _field('Model', _sv(h?['sp_442_model']))),
                const SizedBox(width: 12),
                Expanded(child: _field('Variant', _sv(h?['sp_443_variant']))),
                const SizedBox(width: 12),
                Expanded(child: _field('Color', _sv(h?['sp_444_color']))),
              ],
            ),

          const SizedBox(height: 10),

          // Row 4: Docket Package Amt | Docket Discount | Docket Acc Amt
          if (compact)
            _fieldCol([
              _field('Docket Package Amt', _sv(h?['sp_452'])),
              _field('Docket Discount Amt', _sv(h?['sp_453'])),
              _field('Docket Accessories Amt', _sv(h?['sp_454'])),
            ])
          else
            Row(
              children: [
                Expanded(
                  child: _field('Docket Package Amt', _sv(h?['sp_452'])),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field('Docket Discount Amt', _sv(h?['sp_453'])),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field('Docket Accessories Amt', _sv(h?['sp_454'])),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _fieldCol(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.expand((w) => [w, const SizedBox(height: 10)]).toList()
        ..removeLast(),
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Spares Entry input form  (task #3)
  // Mirrors the web "Spares Entry" panel above the accessories grid.
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSparesEntryForm(double width) {
    final compact = width < 600;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── row 1: Category | Part No | Spares Name | Issue Qty | MRP ──
          if (compact)
            Column(
              children: [
                _entryField('Category', _categoryCtrl, compact: compact),
                const SizedBox(height: 10),
                _entryField('Part No', _partNoCtrl, compact: compact),
                const SizedBox(height: 10),
                _entryField('Spares Name', _sparesCtrl, compact: compact),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _entryField(
                        'Issue Qty',
                        _issueQtyCtrl,
                        compact: compact,
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _entryField(
                        'MRP',
                        _mrpCtrl,
                        compact: compact,
                        numeric: true,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _entryField('Category', _categoryCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _entryField('Part No', _partNoCtrl)),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _entryField('Spares Name', _sparesCtrl),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _entryField('Issue Qty', _issueQtyCtrl, numeric: true),
                ),
                const SizedBox(width: 10),
                Expanded(child: _entryField('MRP', _mrpCtrl, numeric: true)),
              ],
            ),

          const SizedBox(height: 10),

          // ── row 2: Discount | Amount ──
          if (compact)
            Row(
              children: [
                Expanded(
                  child: _entryField(
                    'Discount',
                    _discountCtrl,
                    compact: compact,
                    numeric: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _entryField(
                    'Amount',
                    _amountCtrl,
                    compact: compact,
                    numeric: true,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _entryField('Discount', _discountCtrl, numeric: true),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _entryField('Amount', _amountCtrl, numeric: true),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// A labelled read-only text field used inside the Spares Entry form.
  Widget _entryField(
    String label,
    TextEditingController ctrl, {
    bool compact = false,
    bool numeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: compact ? 34 : 38,
          child: TextField(
            controller: ctrl,
            readOnly: true,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            style: TextStyle(fontSize: compact ? 12 : 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 8 : 10,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Totals bar  (task #4)
  // Mirrors the footer row: Accessories Amount | (col) | (col) | Total Amount
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTotalsBar(double width) {
    final compact = width < 600;
    final accAmt = _accessoriesTotal;
    final disc = _discountTotal;
    final total = _grandTotal;

    String fmt(double v) =>
        v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: _totalCell('Acc. Amount', fmt(accAmt), compact: true),
            ),
            Expanded(child: _totalCell('Discount', fmt(disc), compact: true)),
            Expanded(
              child: _totalCell(
                'Total Amt',
                fmt(total),
                compact: true,
                highlight: true,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _totalCell('Accessories Amount', fmt(accAmt)),
          ),
          _totalDivider(),
          Expanded(child: _totalCell('', fmt(disc))),
          _totalDivider(),
          Expanded(child: _totalCell('', '0')),
          _totalDivider(),
          Expanded(
            flex: 2,
            child: _totalCell('Total Amount', fmt(total), highlight: true),
          ),
        ],
      ),
    );
  }

  Widget _totalCell(
    String label,
    String value, {
    bool highlight = false,
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: highlight ? _primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalDivider() => Container(
    width: 1,
    color: Colors.grey.shade400,
    margin: const EdgeInsets.symmetric(vertical: 6),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Docket table  — Category · Qty · MRP · Status
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDocketTable(double width) {
    final theme = Theme.of(context);
    final compact = width < 600;
    final hPad = compact ? 10.0 : 16.0;
    final vPad = compact ? 10.0 : 12.0;
    final fs = compact ? 11.0 : 12.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3.0), // Category
            1: FlexColumnWidth(1.0), // Qty
            2: FlexColumnWidth(1.2), // MRP
            3: FlexColumnWidth(1.5), // Status
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: _primary),
              children: [
                _th('Category', hPad: hPad, vPad: vPad, fs: fs),
                _th('Qty', hPad: hPad, vPad: vPad, fs: fs),
                _th('MRP', hPad: hPad, vPad: vPad, fs: fs),
                _th('Status', hPad: hPad, vPad: vPad, fs: fs),
              ],
            ),
            ...List.generate(_docketRows.length, (i) {
              final r = _docketRows[i];
              final even = i % 2 == 0;
              return TableRow(
                decoration: BoxDecoration(
                  color: even
                      ? theme.cardColor
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                ),
                children: [
                  _td(
                    _sv(r['Category']),
                    hPad: hPad,
                    vPad: vPad,
                    fs: fs,
                    bold: true,
                  ),
                  _td(_sv(r['qty']), hPad: hPad, vPad: vPad, fs: fs),
                  _td(_sv(r['mrp']), hPad: hPad, vPad: vPad, fs: fs),
                  _td(_sv(r['status']), hPad: hPad, vPad: vPad, fs: fs),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Details grid  — accessories pending approval
  // < 600 : cards;  >= 600 : table
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No pending approval items',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'All accessory cancellations have been processed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(BoxConstraints constraints) {
    if (constraints.maxWidth < 600) {
      return Column(
        children: List.generate(
          _detailRows.length,
          (i) => _buildDetailCard(
            i + 1,
            _detailRows[i],
            compact: constraints.maxWidth < 360,
          ),
        ),
      );
    }
    return _buildDetailsTable(constraints.maxWidth);
  }

  // ── Table (≥ 600 px) ───────────────────────────────────────────────────

  Widget _buildDetailsTable(double width) {
    final theme = Theme.of(context);
    final compact = width < 900;
    final hPad = compact ? 10.0 : 14.0;
    final vPad = compact ? 10.0 : 12.0;
    final fs = compact ? 11.0 : 12.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(38), // S.No
            1: FlexColumnWidth(2.8), // Spares Name
            2: FlexColumnWidth(1.6), // Part No
            3: FlexColumnWidth(0.8), // Qty
            4: FlexColumnWidth(1.0), // MRP
            5: IntrinsicColumnWidth(), // Action buttons
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // ── header ──────────────────────────────────────────────
            TableRow(
              decoration: const BoxDecoration(color: _primary),
              children: [
                _th('#', hPad: hPad, vPad: vPad, fs: fs, center: true),
                _th('Spares Name', hPad: hPad, vPad: vPad, fs: fs),
                _th('Part No', hPad: hPad, vPad: vPad, fs: fs),
                _th('Qty', hPad: hPad, vPad: vPad, fs: fs),
                _th('MRP', hPad: hPad, vPad: vPad, fs: fs),
                _th('Action', hPad: hPad, vPad: vPad, fs: fs, center: true),
              ],
            ),

            // ── rows ────────────────────────────────────────────────
            ...List.generate(_detailRows.length, (i) {
              final r = _detailRows[i];
              final even = i % 2 == 0;
              final approved = _isApproved(r);

              return TableRow(
                decoration: BoxDecoration(
                  color: even
                      ? theme.cardColor
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                ),
                children: [
                  _td('${i + 1}', hPad: hPad, vPad: vPad, fs: fs, center: true),
                  _td(
                    _sv(r['sp_451']),
                    hPad: hPad,
                    vPad: vPad,
                    fs: fs,
                    bold: true,
                  ),
                  _td(_sv(r['sp_452']), hPad: hPad, vPad: vPad, fs: fs),
                  _td(_sv(r['sp_453']), hPad: hPad, vPad: vPad, fs: fs),
                  _td(_sv(r['sp_43_6']), hPad: hPad, vPad: vPad, fs: fs),
                  // approve / reject
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad * 0.5,
                      vertical: vPad * 0.4,
                    ),
                    child: _actionBtns(r, approved: approved, compact: compact),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Card (< 600 px) ────────────────────────────────────────────────────

  Widget _buildDetailCard(
    int idx,
    Map<String, dynamic> r, {
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final approved = _isApproved(r);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── row header: badge + spares name ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 28 : 32,
                height: compact ? 28 : 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$idx',
                  style: TextStyle(
                    color: _primary,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _sv(r['sp_451']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          Divider(height: compact ? 16 : 18, color: Colors.grey.shade200),

          _infoRow(
            Icons.numbers_rounded,
            'Part No',
            _sv(r['sp_452']),
            compact: compact,
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.production_quantity_limits_rounded,
            'Qty',
            _sv(r['sp_453']),
            compact: compact,
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.attach_money_rounded,
            'MRP',
            _sv(r['sp_43_6']),
            compact: compact,
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.local_shipping_outlined,
            'Issue',
            _sv(r['issue']),
            compact: compact,
          ),

          const SizedBox(height: 12),

          // ── action buttons ───────────────────────────────────────
          _actionBtns(r, approved: approved, compact: compact, fullWidth: true),
        ],
      ),
    );
  }

  // ── Approve / Reject button pair ───────────────────────────────────────

  Widget _actionBtns(
    Map<String, dynamic> row, {
    required bool approved,
    bool compact = false,
    bool fullWidth = false,
  }) {
    final childUnq = _sv(row['childunq']);
    final processing = _processingIds.contains(childUnq);
    final btnH = compact ? 30.0 : 34.0;
    final fs = compact ? 11.0 : 12.0;

    final approveBtn = SizedBox(
      height: btnH,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: (approved || processing) ? null : () => _approve(row),
        style: ElevatedButton.styleFrom(
          backgroundColor: approved ? Colors.grey.shade400 : _green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: processing
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Approve',
                style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700),
              ),
      ),
    );

    final rejectBtn = SizedBox(
      height: btnH,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: (approved || processing) ? null : () => _reject(row),
        style: ElevatedButton.styleFrom(
          backgroundColor: approved ? Colors.grey.shade400 : _red,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          'Reject',
          style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700),
        ),
      ),
    );

    if (fullWidth) {
      return Column(
        children: [approveBtn, const SizedBox(height: 6), rejectBtn],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [approveBtn, const SizedBox(width: 6), rejectBtn],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared table cell helpers
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
    bool center = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: fs,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool compact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: compact ? 15 : 17, color: _accent),
        const SizedBox(width: 7),
        SizedBox(
          width: compact ? 55 : 62,
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
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  double _hPad(double w) {
    if (w < 360) return 8;
    if (w < 600) return 12;
    if (w < 900) return 16;
    return 20;
  }

  /// Returns true when the cancellation approval date is already set
  /// (i.e. year != 1900 and value is non-null/non-empty).
  bool _isApproved(Map<String, dynamic> row) {
    final raw = row['cancelappdate']?.toString() ?? '';
    if (raw.isEmpty) return false;
    try {
      final dt = DateTime.parse(raw);
      return dt.year != 1900;
    } catch (_) {
      return false;
    }
  }

  String _sv(dynamic v) {
    if (v == null) return '-';
    final t = v.toString().trim();
    return t.isEmpty ? '-' : t;
  }
}
