import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'dashboard_growth_chip.dart';
import 'dashboard_sparkline.dart';

class DashboardComparisonCard extends StatelessWidget {
  final String title;
  final IconData icon;

  final int today;
  final int yesterday;

  final double growth;

  final List<double> trend;

  final List<Color> gradient;

  final VoidCallback onTodayTap;
  final VoidCallback onYesterdayTap;

  final bool compact;

  /// Optional — if provided, a small performance icon appears in the header
  final VoidCallback? onPerformanceTap;

  /// Optional — if provided, a small comparison icon appears in the header
  final VoidCallback? onComparisonTap;

  const DashboardComparisonCard({
    super.key,
    required this.title,
    required this.icon,
    required this.today,
    required this.yesterday,
    required this.growth,
    required this.trend,
    required this.gradient,
    required this.onTodayTap,
    required this.onYesterdayTap,
    this.compact = false,
    this.onPerformanceTap,
    this.onComparisonTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 18.0 : 24.0;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: compact ? 180 : 240,
        padding: EdgeInsets.all(compact ? 14 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(.28),
              blurRadius: compact ? 10 : 18,
              offset: Offset(0, compact ? 4 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //----------------------------------------------------
            // HEADER
            //----------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 36 : 48,
                  height: compact ? 36 : 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: compact ? 20 : 24),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 16 : 20,
                        ),
                      ),

                      SizedBox(height: compact ? 4 : 8),

                      DashboardGrowthChip(growth: growth),
                    ],
                  ),
                ),

                // ── Performance icon (optional) ──────────────
                if (onPerformanceTap != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onPerformanceTap,
                    child: Container(
                      width: compact ? 32 : 36,
                      height: compact ? 32 : 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(.30),
                        ),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: compact ? 16 : 20,
                      ),
                    ),
                  ),
                ],

                // ── Comparison icon (optional) ────────────────
                if (onComparisonTap != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onComparisonTap,
                    child: Container(
                      width: compact ? 32 : 36,
                      height: compact ? 32 : 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(.30),
                        ),
                      ),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: Colors.white,
                        size: compact ? 16 : 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: compact ? 10 : 20),

            //----------------------------------------------------
            // METRICS
            //----------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: "Today",
                    value: today,
                    subtitle: "",
                    onTap: onTodayTap,
                    compact: compact,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _MetricTile(
                    label: "Y'day",
                    value: yesterday,
                    subtitle: "",
                    onTap: onYesterdayTap,
                    compact: compact,
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 0 : 18),

            //----------------------------------------------------
            // TREND
            //----------------------------------------------------
            // SizedBox(height: 55, child: DashboardSparkline(values: trend)),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final int value;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 6 : 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //------------------------------------------------
              // LABEL
              //------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 12,
                  ),
                ],
              ),

              const SizedBox(height: 4),

              //------------------------------------------------
              // VALUE
              //------------------------------------------------
              AnimatedFlipCounter(
                value: value,
                duration: const Duration(milliseconds: 700),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 24 : 30,
                ),
              ),

              if (!compact) const SizedBox(height: 4),

              //------------------------------------------------
              // SUBTITLE
              //------------------------------------------------
              if (!compact)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.70),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
