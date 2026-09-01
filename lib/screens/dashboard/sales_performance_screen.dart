import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/rgb_border_card.dart';

class SalesPerformanceScreen extends StatefulWidget {
  const SalesPerformanceScreen({super.key});

  @override
  State<SalesPerformanceScreen> createState() => _SalesPerformanceScreenState();
}

class _SalesPerformanceScreenState extends State<SalesPerformanceScreen> {
  static const Color _primary = Color(0xFF1A237E);
  static const Color _headerColor = Color(0xFF3949AB);
  static const List<Color> _gradient = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
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

  static const Color _todayColor = Color(0xFF4CAF50);
  static const Color _yesterdayColor = Color(0xFF2196F3);
  static const Color _weekColor = Color(0xFF9C27B0);
  static const Color _monthColor = Color(0xFFFF9800);
  static const Color _yearColor = Color(0xFFE91E63);

  static const Color _todayCardColor = Color(0xFFE8F5E9);
  static const Color _yesterdayCardColor = Color(0xFFE3F2FD);
  static const Color _weekCardColor = Color(0xFFF3E5F5);
  static const Color _monthCardColor = Color(0xFFFFF3E0);
  static const Color _yearCardColor = Color(0xFFFCE4EC);

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
        backgroundColor: _headerColor,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
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
          const Text(
            'Sales Performance',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Units sold & revenue across periods',
            style: TextStyle(color: Colors.white70, fontSize: 14),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: RgbBorderCard(
        borderRadius: 16,
        borderWidth: 2.0,
        glow: true,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 14),

            // Label + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _periodSubtitle(key),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Units Sold
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
              )
            else if (error != null)
              Text('—', style: TextStyle(color: Colors.red[300], fontSize: 13))
            else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Units Sold',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    saleCount.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Revenue
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Revenue',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatValue(saleValue),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // LIVE badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.30)),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

  Color _periodCardColor(String key) {
    switch (key) {
      case 'today':
        return _todayCardColor;
      case 'yesterday':
        return _yesterdayCardColor;
      case 'thisweek':
        return _weekCardColor;
      case 'thismonth':
        return _monthCardColor;
      case 'thisfinancialyear':
        return _yearCardColor;
      default:
        return _todayCardColor;
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
        color: isDark 
            ? color.withValues(alpha: 0.15)
            : Colors.white,
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
