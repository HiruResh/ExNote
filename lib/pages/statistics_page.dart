// lib/pages/statistics_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/expense.dart';
import 'package:exnote/providers/expense_provider.dart';
import 'package:exnote/widgets/expense_bar_chart.dart';
import 'package:exnote/widgets/expense_pie_chart.dart';
import 'package:exnote/widgets/expense_line_chart.dart';

enum StatFilter { daily, weekly, monthly }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // SET DEFAULT FILTER TO DAILY for Pie Chart and main list
  StatFilter _currentFilter = StatFilter.daily;

  List<Expense> _getFilteredExpenses(ExpenseProvider provider) {
    final now = DateTime.now();
    if (_currentFilter == StatFilter.daily) {
      return provider.getDailyExpenses(now);
    } else if (_currentFilter == StatFilter.weekly) {
      // Logic for current week (Mon-Sun)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return provider.readExpensesByDateRange(startOfWeek, endOfWeek);
    } else {
      // Logic for current month
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(
        now.year,
        now.month + 1,
        0,
      ); // Day 0 of next month is last day of this month
      return provider.readExpensesByDateRange(startOfMonth, endOfMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          final filteredExpenses = _getFilteredExpenses(expenseProvider);
          final categoryTotals = expenseProvider.getCategoryTotals(
            filteredExpenses,
          );
          final totalAmount = filteredExpenses.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- 1. Filter Toggle (For Pie Chart - Default Daily) ---
              SegmentedButton<StatFilter>(
                segments: const <ButtonSegment<StatFilter>>[
                  ButtonSegment<StatFilter>(
                    value: StatFilter.daily,
                    label: Text('Daily'),
                  ),
                  ButtonSegment<StatFilter>(
                    value: StatFilter.weekly,
                    label: Text('Weekly'),
                  ),
                  ButtonSegment<StatFilter>(
                    value: StatFilter.monthly,
                    label: Text('Monthly'),
                  ),
                ],
                selected: <StatFilter>{_currentFilter},
                onSelectionChanged: (Set<StatFilter> newSelection) {
                  setState(() {
                    _currentFilter = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // --- 2. Pie Chart (Category Breakdown) ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Breakdown (${_currentFilter.name.toUpperCase()})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      ExpensePieChart(
                        categoryTotals: categoryTotals,
                        totalAmount: totalAmount,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Line Chart (Default Daily) ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Trend',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      // Line chart defaults to Daily (7 Days)
                      const ExpenseLineChart(
                        initialFilter: LineChartFilter.daily,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Bar Chart (Default Weekly) ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Comparison',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      // Bar chart defaults to Weekly (6 Weeks)
                      const SizedBox(
                        height: 250,
                        child: ExpenseBarChart(
                          initialFilter: BarChartFilter.weekly,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
