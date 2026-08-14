import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendLineChart extends StatefulWidget {
  final List<double> trend;
  final Color color;

  /// '7days' shows day-of-week labels, '6months' shows month abbreviations
  final String period;

  const TrendLineChart({
    super.key,
    required this.trend,
    required this.color,
    this.period = '7days',
  });

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.trend.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            "No data available",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ),
      );
    }

    final double maxValue =
        widget.trend.reduce((a, b) => a > b ? a : b);
    final double minValue =
        widget.trend.reduce((a, b) => a < b ? a : b);
    final double maxY = (maxValue * 1.25).ceilToDouble();
    // Give a small bottom padding so the line doesn't hug the x-axis
    final double minY =
        minValue > 0 ? (minValue * 0.75).floorToDouble() : 0;

    final List<FlSpot> spots = List.generate(
      widget.trend.length,
      (i) => FlSpot(i.toDouble(), widget.trend[i]),
    );

    // Richer gradient colors per chart color
    final bool isBlue = widget.color == Colors.blue ||
        widget.color.value == Colors.blue.value;

    final Color lineColor =
        isBlue ? const Color(0xff2563EB) : const Color(0xff16A34A);
    final Color glowColor =
        isBlue ? const Color(0xff60A5FA) : const Color(0xff4ADE80);
    final Color fillTop =
        isBlue ? const Color(0xff2563EB) : const Color(0xff16A34A);
    final Color fillBottom =
        isBlue ? const Color(0xffDBEAFE) : const Color(0xffDCFCE7);
    final Color gridColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.grey.shade200;
    final Color labelColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade500;

    return SizedBox(
      height: 220,
      child: LineChart(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        LineChartData(
          minX: 0,
          maxX: (widget.trend.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,

          clipData: const FlClipData.all(),
          borderData: FlBorderData(show: false),

          // ── Grid ───────────────────────────────────────────
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: gridColor,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),

          // ── Axis labels ────────────────────────────────────
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  );
                },
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final int idx = value.toInt();

                  if (widget.period == '6months') {
                    const monthNames = [
                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                    ];
                    final now = DateTime.now();
                    final monthIdx = (now.month - 1 - (5 - idx) + 12) % 12;
                    if (idx < 0 || idx > 5) return const SizedBox();
                    final bool isActive = idx == _touchedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        monthNames[monthIdx],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive ? lineColor : labelColor,
                        ),
                      ),
                    );
                  }

                  // 7days
                  const labels = [
                    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
                  ];
                  if (idx >= labels.length) return const SizedBox();
                  final bool isActive = idx == _touchedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? lineColor : labelColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Touch ──────────────────────────────────────────
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              final idx =
                  response?.lineBarSpots?.first.spotIndex;
              if (mounted) {
                setState(() => _touchedIndex = idx);
              }
            },
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((i) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: lineColor.withOpacity(0.4),
                    strokeWidth: 1.5,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 7,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: lineColor,
                    ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              getTooltipColor: (_) => isDark
                  ? const Color(0xff1E293B)
                  : lineColor,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    spot.y.toStringAsFixed(0),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  );
                }).toList();
              },
            ),
          ),

          // ── Lines ──────────────────────────────────────────
          lineBarsData: [
            // Outer glow halo
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              color: glowColor.withOpacity(0.25),
              barWidth: 14,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              preventCurveOverShooting: true,
            ),

            // Inner glow
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              color: lineColor.withOpacity(0.35),
              barWidth: 7,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              preventCurveOverShooting: true,
            ),

            // Main line + gradient fill
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              preventCurveOverShooting: true,

              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final bool isTouched = index == _touchedIndex;
                  final bool isLast =
                      index == widget.trend.length - 1;
                  if (isTouched) return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                  return FlDotCirclePainter(
                    radius: isLast ? 6 : 3.5,
                    color: Colors.white,
                    strokeWidth: isLast ? 3.5 : 2.5,
                    strokeColor: lineColor,
                  );
                },
              ),

              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    fillTop.withOpacity(0.32),
                    fillBottom.withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
