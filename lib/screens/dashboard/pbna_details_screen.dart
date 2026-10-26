import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../vehicle_allocation/vehicle_allocation_form_screen.dart';

/// PBNA Booking Details for a specific model.
/// Calls SP: A_SP_FOR_ApplicationChallangrid @what='Pbna_Modelwise_details'
/// with @ModelUnq = modelName
class PbnaDetailsScreen extends StatefulWidget {
  final String modelName;
  final int totalCount;

  const PbnaDetailsScreen({
    super.key,
    required this.modelName,
    required this.totalCount,
  });

  @override
  State<PbnaDetailsScreen> createState() => _PbnaDetailsScreenState();
}

class _PbnaDetailsScreenState extends State<PbnaDetailsScreen> {
  static const Color _primary = Color(0xFF6A1B9A);
  static const Color _accent = Color(0xFFAB47BC);

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getPbnaModelwiseDetails(widget.modelName);

      final rawRows = result['rows'];
      final rows = rawRows is List
          ? rawRows
                .whereType<Map>()
                .map((r) => Map<String, dynamic>.from(r))
                .toList()
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _total = (result['total'] as num?)?.toInt() ?? rows.length;
          _rows = rows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              widget.modelName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'PBNA — Booking Details',
              style: TextStyle(fontSize: 11, color: Colors.white70),
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
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: const Center(
              child: CircularProgressIndicator(color: _primary),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        if (_rows.isEmpty)
          _buildEmpty()
        else
          ..._rows.asMap().entries.map(
            (entry) => _buildBookingCard(entry.key, entry.value, theme),
          ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3A0750), const Color(0xFF6A1B9A)]
              : [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.modelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'Pending Booking — Not Allocated',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statPill(label: 'Total Pending', value: _total.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking card ───────────────────────────────────────────────────────────

  Widget _buildBookingCard(
    int index,
    Map<String, dynamic> row,
    ThemeData theme,
  ) {
    final customer = row['customer']?.toString() ?? '—';
    final bookingDate = _formatDate(row['bookingDate']);
    final scname = row['scname']?.toString().trim() ?? '';
    final variant = row['variant']?.toString() ?? '—';
    final color = row['color']?.toString() ?? '—';
    final ageing = row['ageing']?.toString() ?? '—';
    // Support both API camelCase keys and raw SQL column aliases.
    // SQL may return "Finance Type", "Financer Name", "LOAN AMOUNT", etc.
    final status = (row['finstatus'] ?? '').toString().trim().toUpperCase();

    final financeType = _rowValue(row, ['financeType', 'Finance Type']).trim();
    final financerName = _rowValue(row, [
      'financerName',
      'Financer Name',
    ]).trim();
    final loanAmount = _rowRawValue(row, ['loanAmount', 'LOAN AMOUNT']);
    final disbursedAmount = _rowRawValue(row, [
      'disbursedAmount',
      'DISBURSED AMOUNT',
    ]);
    final remarks = _rowValue(row, ['remarks']).trim();
    final normalizedStatus = status.trim().toUpperCase();
    final hasFinanceFields = [
      financeType,
      financerName,
      _formatAmount(loanAmount) ?? '',
      _formatAmount(disbursedAmount) ?? '',
      remarks,
    ].any((value) => value.trim().isNotEmpty && value.toLowerCase() != 'null');
    final isFinanceEntryPending =
        normalizedStatus == 'FINANCE ENTRY PENDING' ||
        (normalizedStatus.isEmpty && !hasFinanceFields);

    // Only show the pending message when SQL explicitly says
    // FINANCE ENTRY PENDING. A normal status such as APPROVE/PENDING/HOLD
    // must display its finance information when available.

    final isDark = theme.brightness == Brightness.dark;
    final badgeColor = isDark ? const Color(0xFFD0A4FF) : _primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : _primary.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(isDark ? 0.04 : 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: serial + customer + date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Serial badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Customer name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bookingDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      // Sales Consultant name
                      if (scname.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'SC: $scname',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Booking ageing in days
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ageing: $ageing days',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Variant + Color chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (variant.isNotEmpty && variant != '—')
                  _infoBadge(
                    icon: Icons.tune_rounded,
                    label: variant,
                    theme: theme,
                  ),
                if (color.isNotEmpty && color != '—')
                  _infoBadge(
                    icon: Icons.color_lens_rounded,
                    label: color,
                    theme: theme,
                    color: _accent,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Finance details returned by Pbna_Modelwise_details.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.35,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        color: badgeColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Finance Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isFinanceEntryPending)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Finance Details Pending',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _financeInfo('Finance Status', status, theme),
                    _financeInfo('Finance Type', financeType, theme),
                    _financeInfo('Financer Name', financerName, theme),
                    _financeInfo(
                      'Loan Amount',
                      _formatAmount(loanAmount),
                      theme,
                    ),
                    _financeInfo(
                      'Disbursed Amount',
                      _formatAmount(disbursedAmount),
                      theme,
                    ),
                    _financeInfo('Remarks', remarks, theme),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final customerUnq =
                      row['customerUnq']?.toString().trim() ?? '';

                  if (customerUnq.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer ID not found in PBNA data.'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleAllocationFormScreen(
                        initialCustomerUnq: customerUnq,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.directions_car_rounded),
                label: const Text('Allocate Vehicle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  dynamic _rowRawValue(Map<String, dynamic> row, List<String> possibleKeys) {
    for (final possibleKey in possibleKeys) {
      for (final entry in row.entries) {
        if (entry.key.trim().toLowerCase() == possibleKey.toLowerCase()) {
          return entry.value;
        }
      }
    }
    return null;
  }

  String _rowValue(Map<String, dynamic> row, List<String> possibleKeys) {
    final value = _rowRawValue(row, possibleKeys);
    if (value == null) return '';
    final text = value.toString().trim();
    return text.toLowerCase() == 'null' ? '' : text;
  }

  String? _formatAmount(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  Widget _financeInfo(String label, String? value, ThemeData theme) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge({
    required IconData icon,
    required String label,
    required ThemeData theme,
    Color? color,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = color ?? _primary;
    final c = isDark
        ? (baseColor == _primary
              ? const Color(0xFFD0A4FF)
              : const Color(0xFFE1BEE7))
        : baseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: colors.onSurfaceVariant,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No pending bookings for ${widget.modelName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
