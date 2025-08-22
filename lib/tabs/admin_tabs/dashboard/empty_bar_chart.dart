import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EmptyBarChart extends StatelessWidget {
  const EmptyBarChart({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(BarChartData(
      maxY: 20,
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      titlesData: const FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
    ));
  }
}
