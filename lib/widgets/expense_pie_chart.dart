// lib/widgets/expense_pie_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpensePieChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalAmount;

  const ExpensePieChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (totalAmount == 0) {
      return const Center(child: Text("No data to show for this period."));
    }

    // Assign colors to categories (you'd ideally map colors consistently)
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
    ];
    int colorIndex = 0;

    List<PieChartSectionData> sections = categoryTotals.entries.map((entry) {
      final percentage = (entry.value / totalAmount) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: categoryTotals.entries.map((entry) {
            final color =
                colors[categoryTotals.keys.toList().indexOf(entry.key) %
                    colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, color: color),
                const SizedBox(width: 4),
                Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
