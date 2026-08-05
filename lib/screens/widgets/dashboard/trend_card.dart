import 'package:flutter/material.dart';
import 'trend_line_chart.dart';

class TrendCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double growth;
  final List<double> trend;

  const TrendCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.growth,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = growth >= 0;

    final double highest = trend.isEmpty
        ? 0
        : trend.reduce((a, b) => a > b ? a : b);

    final double lowest = trend.isEmpty
        ? 0
        : trend.reduce((a, b) => a < b ? a : b);

    final double average = trend.isEmpty
        ? 0
        : trend.reduce((a, b) => a + b) / trend.length;

    final Color backgroundColor = color == Colors.blue
        ? const Color(0xffF6FAFF)
        : const Color(0xffF6FFF8);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Top Accent
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14),
                          SizedBox(width: 6),
                          Text(
                            "Last 7 Days",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /// Growth
                Row(
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isPositive ? Colors.green : Colors.red,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        isPositive
                            ? "${growth.toStringAsFixed(1)}% higher than last week"
                            : "${growth.abs().toStringAsFixed(1)}% lower than last week",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// CHART
                TrendLineChart(trend: trend, color: color),

                const SizedBox(height: 20),

                Divider(color: Colors.grey.shade300),

                const SizedBox(height: 16),

                /// INSIGHTS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InsightItem(
                          icon: Icons.emoji_events_rounded,
                          iconColor: Colors.orange,
                          title: "Highest",
                          value: highest.toStringAsFixed(0),
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey.shade300,
                      ),

                      Expanded(
                        child: _InsightItem(
                          icon: Icons.analytics_rounded,
                          iconColor: Colors.blue,
                          title: "Average",
                          value: average.toStringAsFixed(1),
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey.shade300,
                      ),

                      Expanded(
                        child: _InsightItem(
                          icon: Icons.trending_down_rounded,
                          iconColor: Colors.red,
                          title: "Lowest",
                          value: lowest.toStringAsFixed(0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InsightItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withOpacity(.12),
          child: Icon(icon, size: 18, color: iconColor),
        ),

        const SizedBox(height: 10),

        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
