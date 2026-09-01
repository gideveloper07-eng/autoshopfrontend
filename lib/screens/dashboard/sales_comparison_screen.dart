import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/rgb_border_card.dart';

class SalesComparisonScreen extends StatefulWidget {
  const SalesComparisonScreen({super.key});

  @override
  State<SalesComparisonScreen> createState() => _SalesComparisonScreenState();
}

class _SalesComparisonScreenState extends State<SalesComparisonScreen> {
  static const Color _primary = Color(0xFF3949AB);
  static const List<Color> _gradient = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  static const _periods = [
    {
      'key': 'today_vs_yesterday',
      'label': 'Today vs Yesterday',
      'icon': Icons.today_rounded,
    },
    {
      'key': 'thisweek_vs_lastweek',
      'label': 'This Week vs Last Week',
      'icon': Icons.view_week_rounded,
    },
    {
      'key': 'thismonth_vs_lastmonth',
      'label': 'This Month vs Last Month',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'key': 'thisquarter_vs_lastquarter',
      'label': 'This Quarter vs Last Quarter',
      'icon': Icons.bar_chart_rounded,
    },
    {
      'key': 'thisyear_vs_lastyear',
      'label': 'This Year vs Last Year',
      'icon': Icons.account_balance_rounded,
    },
  ];

  final Map<String, Map<String, dynamic>> _data = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
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
      final result = await ApiService.getSalesComparison(period);
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

  String _formatGrowth(dynamic v) {
    if (v == null) return '—';
    final n = (v as num).toDouble();
    return '${n >= 0 ? '+' : ''}${n.toStringAsFixed(1)}%';
  }

  Color _growthColor(dynamic v) {
    if (v == null) return Colors.grey;
    return (v as num).toDouble() >= 0
        ? const Color(0xFF00B894)
        : const Color(0xFFE17055);
  }

  Color _periodAccent(String key) {
    return _primary;
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
          'Sales Comparison',
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
            const SizedBox(height: 16),
            ..._periods.map(
              (p) => _buildComparisonCard(
                periodKey: p['key'] as String,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.compare_arrows_rounded,
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
                  'Sales Comparison',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Compare sales across time periods',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Live',
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
    );
  }

  Widget _buildComparisonCard({
    required String periodKey,
    required String label,
    required IconData icon,
  }) {
    final isLoading = _loading[periodKey] ?? true;
    final error = _errors[periodKey];
    final row = _data[periodKey] ?? {};
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentCount = (row['CurrentSaleCount'] as num?)?.toInt() ?? 0;
    final previousCount = (row['PreviousSaleCount'] as num?)?.toInt() ?? 0;
    final currentValue = (row['CurrentSaleValue'] as num?)?.toDouble() ?? 0.0;
    final previousValue = (row['PreviousSaleValue'] as num?)?.toDouble() ?? 0.0;
    final countDiff = (row['SaleCountDifference'] as num?)?.toInt() ?? 0;
    final valueDiff = (row['SaleValueDifference'] as num?)?.toDouble() ?? 0.0;
    final growthPct = row['SaleValueGrowthPercent'];

    final currentLabel = _currentLabel(periodKey);
    final previousLabel = _previousLabel(periodKey);

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: _primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
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
                    else if (growthPct != null)
                      _GrowthBadge(value: growthPct),
                  ],
                ),

                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load',
                    style: TextStyle(color: Colors.red[400], fontSize: 13),
                  ),
                ] else if (!isLoading) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // ── Current vs Previous row ──────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _metricBox(
                          label: currentLabel,
                          topLine: '$currentCount units',
                          bottomLine: _formatValue(currentValue),
                          color: _primary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricBox(
                          label: previousLabel,
                          topLine: '$previousCount units',
                          bottomLine: _formatValue(previousValue),
                          color: Colors.grey,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Change summary ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _growthColor(valueDiff).withOpacity(
                        isDark ? 0.12 : 0.07,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _growthColor(valueDiff).withOpacity(0.20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: _growthColor(valueDiff),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Change: ${countDiff >= 0 ? '+' : ''}$countDiff units  |  ${_formatValueSigned(valueDiff)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _growthColor(valueDiff),
                            ),
                          ),
                        ),
                        if (growthPct != null)
                          Text(
                            _formatGrowth(growthPct),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _growthColor(growthPct),
                            ),
                          ),
                      ],
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

  String _currentLabel(String key) {
    switch (key) {
      case 'today_vs_yesterday':
        return 'Today';
      case 'thisweek_vs_lastweek':
        return 'This Week';
      case 'thismonth_vs_lastmonth':
        return 'This Month';
      case 'thisquarter_vs_lastquarter':
        return 'This Quarter';
      case 'thisyear_vs_lastyear':
        return 'This Year';
      default:
        return 'Current';
    }
  }

  String _previousLabel(String key) {
    switch (key) {
      case 'today_vs_yesterday':
        return 'Yesterday';
      case 'thisweek_vs_lastweek':
        return 'Last Week';
      case 'thismonth_vs_lastmonth':
        return 'Last Month';
      case 'thisquarter_vs_lastquarter':
        return 'Last Quarter';
      case 'thisyear_vs_lastyear':
        return 'Last Year';
      default:
        return 'Previous';
    }
  }

  String _formatValueSigned(double v) {
    final prefix = v >= 0 ? '+' : '';
    if (v.abs() >= 10000000) {
      return '$prefix₹${(v / 10000000).toStringAsFixed(2)} Cr';
    }
    if (v.abs() >= 100000) return '$prefix₹${(v / 100000).toStringAsFixed(2)} L';
    if (v.abs() >= 1000) return '$prefix₹${(v / 1000).toStringAsFixed(1)} K';
    return '$prefix₹${v.toStringAsFixed(0)}';
  }

  Widget _metricBox({
    required String label,
    required String topLine,
    required String bottomLine,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.10) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            topLine,
            style: const TextStyle(
              color: Color(0xFF3949AB),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bottomLine,
            style: const TextStyle(
              color: Color(0xFF3949AB),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonRow() {
    return Row(
      children: [
        Expanded(child: _skeleton(double.infinity, 70)),
        const SizedBox(width: 10),
        Expanded(child: _skeleton(double.infinity, 70)),
      ],
    );
  }

  Widget _skeleton(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ── Small growth badge ───────────────────────────────────────────────────────
class _GrowthBadge extends StatelessWidget {
  final dynamic value;
  const _GrowthBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final n = value == null ? 0.0 : (value as num).toDouble();
    final isPositive = n >= 0;
    final color =
        isPositive ? const Color(0xFF00B894) : const Color(0xFFE17055);
    final bg = color.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            '${isPositive ? '+' : ''}${n.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
