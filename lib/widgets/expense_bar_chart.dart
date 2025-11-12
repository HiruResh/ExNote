// lib/widgets/expense_bar_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/providers/expense_provider.dart';
import 'package:intl/intl.dart';

enum BarChartFilter { daily, weekly, monthly }

class ExpenseBarChart extends StatefulWidget {
  final BarChartFilter initialFilter;

  const ExpenseBarChart({
    super.key,
    this.initialFilter = BarChartFilter.weekly,
  });

  @override
  State<ExpenseBarChart> createState() => _ExpenseBarChartState();
}

class _ExpenseBarChartState extends State<ExpenseBarChart> {
  late BarChartFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  // Helper to get the correct data based on the filter
  Map<DateTime, double> _getChartData(ExpenseProvider provider) {
    final now = DateTime.now();
    if (_currentFilter == BarChartFilter.daily) {
      // Show last 7 days
      final start = now.subtract(const Duration(days: 6));
      return provider.getDailyTotalsForRange(start, now);
    } else if (_currentFilter == BarChartFilter.weekly) {
      // Show totals for the last 6 weeks
      return provider.getWeeklyTotalsForRange(6);
    } else {
      // Show totals for the last 6 months
      return provider.getMonthlyTotalsForRange(6);
    }
  }

  // Helper to get the appropriate title for the X-axis
  String _getTitle(DateTime date) {
    if (_currentFilter == BarChartFilter.daily) {
      return DateFormat('E').format(date); // e.g., Mon, Tue
    } else if (_currentFilter == BarChartFilter.weekly) {
      return DateFormat('MMM dd').format(date); // Start date of the week
    } else {
      return DateFormat('MMM yy').format(date); // e.g., Jan 25
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final chartData = _getChartData(expenseProvider);

    if (chartData.isEmpty || chartData.values.every((v) => v == 0)) {
      return Column(
        children: [
          _buildFilterButtons(),
          const Expanded(
            child: Center(
              child: Text("No expense data available for this period."),
            ),
          ),
        ],
      );
    }

    final sortedData = chartData.entries.toList();

    // Theme-dependent colors
    final barColor = Theme.of(context).colorScheme.secondary;
    final labelColor = isDarkMode ? Colors.white70 : Colors.black54;

    // Find the maximum amount for scaling the graph
    final maxAmount = chartData.values.reduce((a, b) => a > b ? a : b);

    // Prepare BarChartGroupData
    List<BarChartGroupData> barGroups = sortedData.asMap().entries.map((entry) {
      final index = entry.key; // Index in the list serves as the x-coordinate
      final amount = entry.value.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: barColor,
            width: 12, // Increased width for better visibility
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        // 1. Filter Buttons
        _buildFilterButtons(),

        // 2. The Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, right: 10, left: 10),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount * 1.2,
                minY: 0,

                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(color: labelColor, fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                      interval: maxAmount / 4,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedData.length) {
                          final date = sortedData[index].key;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _getTitle(date),
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 10,
                              ), // FIX: Visible in light mode
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDarkMode
                          ? Colors.white10
                          : Colors.grey.withOpacity(0.3),
                      strokeWidth: 0.5,
                    );
                  },
                  horizontalInterval: maxAmount / 4,
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,

                // BarTouchData to show amount on touch/hover
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (spot) =>
                        Theme.of(context).primaryColor.withOpacity(0.8),
                    tooltipBorder: const BorderSide(
                      color: Colors.white,
                      width: 0.5,
                    ),
                    tooltipPadding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'Rs.${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SegmentedButton<BarChartFilter>(
        segments: const <ButtonSegment<BarChartFilter>>[
          ButtonSegment<BarChartFilter>(
            value: BarChartFilter.daily,
            label: Text('7 Days'),
          ),
          ButtonSegment<BarChartFilter>(
            value: BarChartFilter.weekly,
            label: Text('6 Weeks'),
          ),
          ButtonSegment<BarChartFilter>(
            value: BarChartFilter.monthly,
            label: Text('6 Months'),
          ),
        ],
        selected: <BarChartFilter>{_currentFilter},
        onSelectionChanged: (Set<BarChartFilter> newSelection) {
          setState(() {
            _currentFilter = newSelection.first;
          });
        },
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12)),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          ),
        ),
      ),
    );
  }
}
