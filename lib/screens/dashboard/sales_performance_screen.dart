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
    {'key': 'today', 'label': 'Today', 'icon': Icons.today_rounded},
    {'key': 'yesterday', 'label': 'Yesterday', 'icon': Icons.history_rounded},
    {'key': 'thisweek', 'label': 'This Week', 'icon': Icons.view_week_rounded},
    {
      'key': 'thismonth',
      'label': 'This Month',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'key': 'thisfinancialyear',
      'label': 'Financial Year',
      'icon': Icons.account_balance_rounded,
    },
  ];

  static const Color _todayColor = Color(0xFF00B894);
  static const Color _yesterdayColor = Color(0xFFFF9F1A);
  static const Color _weekColor = Color(0xFF2F80ED);
  static const Color _monthColor = Color(0xFF7652F8);
  static const Color _yearColor = Color(0xFF8E44AD);

  // per-period state
  final Map<String, Map<String, dynamic>> _data = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    // load all periods in parallel
    for (final p in _periods) {
      _fetch(p['key'] as String);
    }
  }

  Future<void> _fetch(String period) async {
    if (mounted) {
      setState(() {
        _loading[period] = true;
        _errors[period] = null;
      });
    }
    try {
      final result = await ApiService.getSalesPerformance(period);
      if (!mounted) return;
      setState(() {
        _data[period] = result;
        _loading[period] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[period] = e.toString();
        _loading[period] = false;
      });
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
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)} K';
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
            ..._periods.map(
              (p) => _buildPeriodCard(
                key: p['key'] as String,
                label: p['label'] as String,
                icon: p['icon'] as IconData,
              ),
            ),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Live Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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
    final error = _errors[key];
    final row = _data[key] ?? {};
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final saleCount = (row['saleCount'] as num?)?.toInt() ?? 0;
    final saleValue = (row['saleValue'] as num?)?.toDouble() ?? 0.0;
    final accent = _periodAccent(key);
    final cardFill = isDark
        ? Color.alphaBlend(accent.withValues(alpha: 0.16), theme.cardColor)
        : Color.alphaBlend(accent.withValues(alpha: 0.08), theme.cardColor);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardFill, theme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.36 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF183C35),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _periodSubtitle(key),
                        style: TextStyle(
                          fontSize: 10,
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            if (error != null)
              Text(
                'Failed to load',
                style: TextStyle(color: Colors.red[400], fontSize: 13),
              )
            else if (isLoading)
              Row(
                children: [
                  _skeleton(80, 44),
                  const SizedBox(width: 12),
                  _skeleton(130, 44),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _metricBox(
                      icon: Icons.directions_car_rounded,
                      label: 'Units Sold',
                      value: saleCount.toString(),
                      color: accent,
                      isDark: isDark,
                      hasBg: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricBox(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Revenue',
                      value: _formatValue(saleValue),
                      color: const Color(0xFF3B4CA8),
                      isDark: isDark,
                      hasBg: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _periodAccent(String key) {
    switch (key) {
      case 'today':
        return _todayColor;
      case 'yesterday':
        return _yesterdayColor;
      case 'thisweek':
        return _weekColor;
      case 'thismonth':
        return _monthColor;
      case 'thisfinancialyear':
        return _yearColor;
      default:
        return _primary;
    }
  }

  String _periodSubtitle(String key) {
    switch (key) {
      case 'today':
        return 'Daily snapshot';
      case 'yesterday':
        return 'Previous day';
      case 'thisweek':
        return '7-day trend';
      case 'thismonth':
        return 'Monthly view';
      case 'thisfinancialyear':
        return 'Annual summary';
      default:
        return 'Performance period';
    }
  }

  Widget _metricBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool hasBg = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: hasBg
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: isDark ? 0.20 : 0.12),
                  color.withValues(alpha: isDark ? 0.03 : 0.38),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasBg ? null : color.withValues(alpha: isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
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
                  fontWeight: FontWeight.w800,
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
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
