import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

/// VNA Booking Details for a specific model + variant + color combination.
/// Calls SP: A_SP_FOR_ApplicationChallangrid @what='Vna_details'
class VnaDetailsScreen extends StatefulWidget {
  final String modelName;
  final String variantName;
  final String colorName;
  final int qty;

  const VnaDetailsScreen({
    super.key,
    required this.modelName,
    required this.variantName,
    required this.colorName,
    required this.qty,
  });

  @override
  State<VnaDetailsScreen> createState() => _VnaDetailsScreenState();
}

class _VnaDetailsScreenState extends State<VnaDetailsScreen> {
  static const Color _primary = Color(0xFF880E4F);
  static const Color _accent  = Color(0xFFE91E63);

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
      _error     = null;
    });

    try {
      final result = await ApiService.getVnaDetails(
        modelName:   widget.modelName,
        variantName: widget.variantName,
        colorName:   widget.colorName,
      );

      final rawRows = result['rows'];
      final rows    = rawRows is List
          ? rawRows
                .whereType<Map>()
                .map((r) => Map<String, dynamic>.from(r))
                .toList()
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _total     = (result['total'] as num?)?.toInt() ?? rows.length;
          _rows      = rows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error     = e.toString();
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'VNA — Booking Details',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
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
          Icon(Icons.cloud_off_rounded, color: Colors.grey[400], size: 64),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
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
              ? [const Color(0xFF4A0020), const Color(0xFF880E4F)]
              : [const Color(0xFF880E4F), const Color(0xFFE91E63)],
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
          // Model icon + name
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
                      'Vehicles Not Allocated — Demand',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Variant + Color chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (widget.variantName.isNotEmpty)
                _headerChip(
                  icon: Icons.tune_rounded,
                  label: widget.variantName,
                ),
              if (widget.colorName.isNotEmpty)
                _headerChip(
                  icon: Icons.color_lens_rounded,
                  label: widget.colorName,
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _statPill(label: 'Pending Bookings', value: _total.toString()),
              const SizedBox(width: 10),
              _statPill(
                label: 'Demand Gap',
                value: widget.qty.toString(),
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white70),
            const SizedBox(width: 5),
          ],
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
              fontSize: 15,
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
    final customer    = row['customer']?.toString()    ?? '—';
    final bookingDate = _formatDate(row['bookingDate']);
    final variant     = row['variant']?.toString()     ?? '—';
    final color       = row['color']?.toString()       ?? '—';
    final isDark      = theme.brightness == Brightness.dark;

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
            // Serial + customer + date
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
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bookingDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
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
                    color: _primary,
                    theme: theme,
                  ),
                if (color.isNotEmpty && color != '—')
                  _infoBadge(
                    icon: Icons.color_lens_rounded,
                    label: color,
                    color: _accent,
                    theme: theme,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: _primary.withOpacity(0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found for ${widget.modelName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
