import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardSparkline extends StatelessWidget {
  final List<double> values;

  const DashboardSparkline({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(height: 36);
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    final List<FlSpot> spots = List.generate(
      values.length,
      (index) => FlSpot(index.toDouble(), values[index]),
    );

    return SizedBox(
      height: 42,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: minValue - 1,
          maxY: maxValue + 1,

          clipData: const FlClipData.all(),

          borderData: FlBorderData(show: false),

          gridData: const FlGridData(show: false),

          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(),
            rightTitles: AxisTitles(),
            topTitles: AxisTitles(),
            bottomTitles: AxisTitles(),
          ),

          lineTouchData: const LineTouchData(enabled: false),

          lineBarsData: [
            LineChartBarData(
              spots: spots,

              isCurved: true,

              curveSmoothness: .35,

              color: Colors.white,

              barWidth: 3,

              isStrokeCapRound: true,

              preventCurveOverShooting: true,

              dotData: const FlDotData(show: false),

              belowBarData: BarAreaData(
                show: true,

                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,

                  colors: [
                    Colors.white.withOpacity(.30),

                    Colors.white.withOpacity(.05),
                  ],
                ),
              ),
            ),
          ],
        ),

        duration: const Duration(milliseconds: 900),

        curve: Curves.easeOutCubic,
      ),
    );
  }
}
