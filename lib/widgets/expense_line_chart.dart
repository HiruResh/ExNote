// lib/widgets/expense_line_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:exnote/providers/expense_provider.dart';

enum LineChartFilter { daily, weekly, monthly }

class ExpenseLineChart extends StatefulWidget {
  final LineChartFilter initialFilter;

  const ExpenseLineChart({
    super.key,
    this.initialFilter = LineChartFilter.daily,
  });

  @override
  State<ExpenseLineChart> createState() => _ExpenseLineChartState();
}

class _ExpenseLineChartState extends State<ExpenseLineChart> {
  late LineChartFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  // Helper to get the correct data based on the filter
  Map<DateTime, double> _getChartData(ExpenseProvider provider) {
    final now = DateTime.now();
    const daysToShow = 7; // Range for daily view

    if (_currentFilter == LineChartFilter.daily) {
      final start = now.subtract(const Duration(days: daysToShow - 1));
      return provider.getDailyTotalsForRange(start, now);
    } else if (_currentFilter == LineChartFilter.weekly) {
      // Show totals for the last 6 weeks
      return provider.getWeeklyTotalsForRange(6);
    } else {
      // Show totals for the last 6 months
      return provider.getMonthlyTotalsForRange(6);
    }
  }

  // Helper to get the appropriate title for the X-axis
  String _getTitle(DateTime date) {
    if (_currentFilter == LineChartFilter.daily) {
      return DateFormat('E').format(date); // e.g., Mon, Tue
    } else if (_currentFilter == LineChartFilter.weekly) {
      return DateFormat('MMM dd').format(date); // Start date of the week
    } else {
      return DateFormat('MMM yy').format(date); // e.g., Jan 25
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final data = _getChartData(expenseProvider);

        if (data.isEmpty || data.values.every((v) => v == 0)) {
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

        final sortedData = data.entries.toList();
        final maxAmount = data.values.reduce((a, b) => a > b ? a : b);

        List<FlSpot> spots = sortedData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value);
        }).toList();

        // Theming
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final lineColor = isDarkMode
            ? Colors.white
            : Theme.of(context).primaryColor;
        final gridColor = isDarkMode
            ? Colors.white10
            : Colors.grey.withOpacity(0.3);
        final labelColor = isDarkMode ? Colors.white70 : Colors.black54;

        return Column(
          children: [
            // 1. Filter Buttons
            _buildFilterButtons(),

            // 2. The Chart
            Container(
              padding: const EdgeInsets.only(
                top: 10,
                right: 20,
                left: 10,
                bottom: 10,
              ),
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxAmount / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: gridColor, strokeWidth: 0.5);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
                        interval: maxAmount / 5,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _currentFilter == LineChartFilter.monthly
                            ? 1
                            : null,
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
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: gridColor, width: 1),
                      left: const BorderSide(color: Colors.transparent),
                      right: const BorderSide(color: Colors.transparent),
                      top: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                  minX: 0,
                  maxX: (sortedData.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxAmount * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      // KEY CHANGE 1: Straight lines
                      isCurved: false,
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      // KEY CHANGE 2: Dots at data points
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3, // Small dot size
                            color: lineColor,
                            strokeColor: Colors.transparent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SegmentedButton<LineChartFilter>(
        segments: const <ButtonSegment<LineChartFilter>>[
          ButtonSegment<LineChartFilter>(
            value: LineChartFilter.daily,
            label: Text('7 Days'),
          ),
          ButtonSegment<LineChartFilter>(
            value: LineChartFilter.weekly,
            label: Text('6 Weeks'),
          ),
          ButtonSegment<LineChartFilter>(
            value: LineChartFilter.monthly,
            label: Text('6 Months'),
          ),
        ],
        selected: <LineChartFilter>{_currentFilter},
        onSelectionChanged: (Set<LineChartFilter> newSelection) {
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
