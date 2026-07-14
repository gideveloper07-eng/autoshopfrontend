import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendLineChart extends StatelessWidget {
  final List<double> trend;
  final Color color;

  const TrendLineChart({super.key, required this.trend, required this.color});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const SizedBox(
        height: 190,
        child: Center(child: Text("No trend available")),
      );
    }

    final double maxValue = trend.reduce((a, b) => a > b ? a : b);
    final double maxY = (maxValue * 1.20).ceilToDouble();

    final List<FlSpot> spots = List.generate(
      trend.length,
      (index) => FlSpot(index.toDouble(), trend[index]),
    );

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (trend.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,

          clipData: const FlClipData.all(),

          borderData: FlBorderData(show: false),

          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
                dashArray: [6, 4],
              );
            },
          ),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  );
                },
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const labels = [
                    "Mon",
                    "Tue",
                    "Wed",
                    "Thu",
                    "Fri",
                    "Sat",
                    "Sun",
                  ];

                  if (value.toInt() >= labels.length) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    spot.y.toStringAsFixed(0),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),

          lineBarsData: [
            /// Glow line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color.withOpacity(0.18),
              barWidth: 10,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              preventCurveOverShooting: true,
            ),

            /// Main line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 3.5,
              isStrokeCapRound: true,

              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final bool isLast = index == trend.length - 1;

                  return FlDotCirclePainter(
                    radius: isLast ? 7 : 4,
                    color: Colors.white,
                    strokeWidth: isLast ? 4 : 3,
                    strokeColor: color,
                  );
                },
              ),

              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(.22),
                    color.withOpacity(.08),
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
