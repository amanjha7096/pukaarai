import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    required this.barColor,
    this.maxY,
  });

  final List<double> values;
  final Color barColor;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final computed = values.fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxY ?? (computed > 0 ? computed * 1.3 : 1.0);

    return BarChart(
      BarChartData(
        maxY: top,
        barTouchData: BarTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: values.asMap().entries.map((e) {
          final active = e.value > 0;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: active ? e.value : 0.04,
                color: active ? barColor : barColor.withAlpha(51),
                width: 7,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
