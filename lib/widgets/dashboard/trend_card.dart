import 'package:flutter/material.dart';
import 'trend_line_chart.dart';

class TrendCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double growth;
  final List<double> trend;

  /// '7days' or '6months'
  final String period;
  final ValueChanged<String>? onPeriodChanged;

  const TrendCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.growth,
    required this.trend,
    this.period = '7days',
    this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isPositive = growth >= 0;

    final double highest =
        trend.isEmpty ? 0 : trend.reduce((a, b) => a > b ? a : b);
    final double lowest =
        trend.isEmpty ? 0 : trend.reduce((a, b) => a < b ? a : b);
    final double average =
        trend.isEmpty ? 0 : trend.reduce((a, b) => a + b) / trend.length;

    // Theme colours keyed on blue vs green
    final bool isBlue = color == Colors.blue ||
        color.value == Colors.blue.value;
    final Color primaryColor =
        isBlue ? const Color(0xff2563EB) : const Color(0xff16A34A);
    final Color secondaryColor =
        isBlue ? const Color(0xff60A5FA) : const Color(0xff4ADE80);

    // Card background
    final Color cardBg = isDark
        ? (isBlue
            ? const Color(0xff0F172A)
            : const Color(0xff052E16))
        : Colors.white;

    // Header gradient
    final List<Color> headerGradient = isBlue
        ? [const Color(0xff1D4ED8), const Color(0xff2563EB), const Color(0xff60A5FA)]
        : [const Color(0xff166534), const Color(0xff16A34A), const Color(0xff4ADE80)];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDark ? 0.25 : 0.12),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: headerGradient,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title row: icon + title + period pill ──────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),

                    const SizedBox(width: 12),

                    // Title — flex so it shrinks before the pill does
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Period toggle pill — fixed size, never wraps
                    GestureDetector(
                      onTap: () {
                        final next =
                            period == '7days' ? '6months' : '7days';
                        onPeriodChanged?.call(next);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              period == '7days' ? "7 Days" : "6 Months",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Growth badge on its own line ───────────────
                const SizedBox(height: 10),
                _GrowthBadge(
                  growth: growth,
                  isPositive: isPositive,
                ),
              ],
            ),
          ),

          // ── Chart body ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 4),
            child: TrendLineChart(
              trend: trend,
              color: primaryColor,
              period: period,
            ),
          ),

          // ── Insight strip ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: primaryColor.withOpacity(0.12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _InsightItem(
                      icon: Icons.emoji_events_rounded,
                      iconBg: const Color(0xffFFF7ED),
                      iconColor: const Color(0xffF97316),
                      label: "Highest",
                      value: highest.toStringAsFixed(0),
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: primaryColor.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _InsightItem(
                      icon: Icons.analytics_rounded,
                      iconBg: isBlue
                          ? const Color(0xffEFF6FF)
                          : const Color(0xffF0FDF4),
                      iconColor: primaryColor,
                      label: "Average",
                      value: average.toStringAsFixed(1),
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: primaryColor.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _InsightItem(
                      icon: Icons.south_rounded,
                      iconBg: const Color(0xffFFF1F2),
                      iconColor: const Color(0xffF43F5E),
                      label: "Lowest",
                      value: lowest.toStringAsFixed(0),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Growth badge ──────────────────────────────────────────────────────────────

class _GrowthBadge extends StatelessWidget {
  final double growth;
  final bool isPositive;

  const _GrowthBadge({required this.growth, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final Color bg = isPositive
        ? Colors.white.withOpacity(0.20)
        : Colors.red.withOpacity(0.22);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              isPositive
                  ? "+${growth.toStringAsFixed(1)}% vs last week"
                  : "-${growth.abs().toStringAsFixed(1)}% vs last week",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insight item ──────────────────────────────────────────────────────────────

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _InsightItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? iconColor.withOpacity(0.18) : iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),

        const SizedBox(height: 8),

        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : Colors.grey.shade500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xff1E293B),
          ),
        ),
      ],
    );
  }
}
