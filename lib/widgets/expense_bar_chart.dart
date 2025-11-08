// lib/widgets/expense_bar_chart.dart (FULL CODE - FIX: fl_chart 1.1.1 API)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/providers/expense_provider.dart';

class ExpenseBarChart extends StatelessWidget {
  const ExpenseBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final now = DateTime.now();
    // Start 6 days ago to cover 7 days total (including today)
    final oneWeekAgo = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    // Get data for the last 7 days
    final dailyTotals = expenseProvider.getDailyTotalsForRange(oneWeekAgo, now);

    // Find the maximum amount for scaling the graph
    final maxAmount = dailyTotals.values.isEmpty
        ? 1.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b);

    // Prepare BarChartGroupData
    List<BarChartGroupData> barGroups = dailyTotals.entries.map((entry) {
      // Map the date to an integer index (0 to 6) for the x-axis
      final index = entry.key.difference(oneWeekAgo).inDays;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Theme.of(context).primaryColor,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount * 1.2,

          // FIX 8: AxisTitles in fl_chart 1.1.1 does not take showTitles
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(), // Empty AxisTitles to hide top
            rightTitles: const AxisTitles(), // Empty AxisTitles to hide right
            leftTitles: const AxisTitles(), // Empty AxisTitles to hide left

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // The index (value) is 0-6. Convert this back to a weekday name.
                  final date = oneWeekAgo.add(Duration(days: value.toInt()));
                  // Map weekday (1=Mon, 7=Sun) to a short name
                  final days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  final dayIndex = date.weekday - 1;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[dayIndex],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
          ),

          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,

          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (spot) => Colors.grey.withOpacity(0.5),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
