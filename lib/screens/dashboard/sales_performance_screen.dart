import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SalesPerformanceScreen extends StatefulWidget {
  const SalesPerformanceScreen({super.key});

  @override
  State<SalesPerformanceScreen> createState() => _SalesPerformanceScreenState();
}

class _SalesPerformanceScreenState extends State<SalesPerformanceScreen> {
  static const Color _primary = Color(0xFF1B5E20);
  static const List<Color> _gradient = [
    Color(0xFF1B5E20),
    Color(0xFF2E7D32),
    Color(0xFF43A047),
  ];

  static const _periods = [
    {'key': 'today',               'label': 'Today',           'icon': Icons.today_rounded},
    {'key': 'yesterday',           'label': 'Yesterday',       'icon': Icons.history_rounded},
    {'key': 'thisweek',            'label': 'This Week',       'icon': Icons.view_week_rounded},
    {'key': 'thismonth',           'label': 'This Month',      'icon': Icons.calendar_month_rounded},
    {'key': 'thisfinancialyear',   'label': 'Financial Year',  'icon': Icons.account_balance_rounded},
  ];

  // per-period state
  final Map<String, Map<String, dynamic>> _data  = {};
  final Map<String, bool>                 _loading = {};
  final Map<String, String?>              _errors  = {};

  @override
  void initState() {
    super.initState();
    // load all periods in parallel
    for (final p in _periods) {
      _fetch(p['key'] as String);
    }
  }

  Future<void> _fetch(String period) async {
    if (mounted) setState(() { _loading[period] = true; _errors[period] = null; });
    try {
      final result = await ApiService.getSalesPerformance(period);
      if (!mounted) return;
      setState(() { _data[period] = result; _loading[period] = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errors[period] = e.toString(); _loading[period] = false; });
    }
  }

  Future<void> _refreshAll() async {
    for (final p in _periods) {
      _fetch(p['key'] as String);
    }
  }

  String _formatValue(dynamic v) {
    if (v == null) return '—';
    final n = (v as num).toDouble();
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000)   return '₹${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000)     return '₹${(n / 1000).toStringAsFixed(1)} K';
    return '₹${n.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: _primary,
        title: const Text(
          'Sales Performance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            ..._periods.map((p) => _buildPeriodCard(
              key:   p['key']   as String,
              label: p['label'] as String,
              icon:  p['icon']  as IconData,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
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
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Performance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Units sold & revenue across periods',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard({
    required String key,
    required String label,
    required IconData icon,
  }) {
    final isLoading = _loading[key] ?? true;
    final error     = _errors[key];
    final row       = _data[key] ?? {};
    final theme     = Theme.of(context);
    final isDark    = theme.brightness == Brightness.dark;

    final saleCount = (row['saleCount'] as num?)?.toInt() ?? 0;
    final saleValue = (row['saleValue'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Period header ─────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            if (error != null)
              Text(
                'Failed to load',
                style: TextStyle(color: Colors.red[400], fontSize: 13),
              )
            else if (isLoading)
              // Skeleton placeholders
              Row(
                children: [
                  _skeleton(80, 44),
                  const SizedBox(width: 12),
                  _skeleton(130, 44),
                ],
              )
            else
              // ── Metrics row ─────────────────────────────
              Row(
                children: [
                  // Units
                  Expanded(
                    child: _metricBox(
                      icon: Icons.directions_car_rounded,
                      label: 'Units Sold',
                      value: saleCount.toString(),
                      color: _primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Revenue
                  Expanded(
                    child: _metricBox(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Revenue',
                      value: _formatValue(saleValue),
                      color: const Color(0xFF0A3D8F),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
