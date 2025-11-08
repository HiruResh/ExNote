// lib/pages/plan_statistics_page.dart (FULL CODE - Simplified _StatRow)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/expense.dart';
import 'package:exnote/models/plan.dart';
import 'package:exnote/providers/expense_provider.dart';
import 'package:exnote/providers/plan_provider.dart';
import 'package:exnote/widgets/expense_pie_chart.dart';
import 'package:exnote/widgets/plan_widgets.dart'; // For PlanSummaryCard

class PlanStatisticsPage extends StatelessWidget {
  final Plan plan;

  const PlanStatisticsPage({super.key, required this.plan});

  // Helper to get expenses that fall within the plan's time range
  List<Expense> _getRelevantExpenses(ExpenseProvider expenseProvider) {
    // Note: This relies on ExpenseProvider having readExpensesByDateRange,
    // which was defined in the expense provider aggregation step.
    return expenseProvider.readExpensesByDateRange(
      plan.startDate,
      plan.endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, PlanProvider>(
      builder: (context, expenseProvider, planProvider, child) {
        // 1. Get Actual Expenses
        final actualExpenses = _getRelevantExpenses(expenseProvider);
        final actualTotal = actualExpenses.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );
        final categoryTotals = expenseProvider.getCategoryTotals(
          actualExpenses,
        );

        // 2. Get Planned Data (Used for comparison)
        final planItems = planProvider.allPlans.firstWhere(
          (p) => p.id == plan.id,
          orElse: () => plan,
        );
        final totalPlanned = planItems.maxAmount;
        final difference = totalPlanned - actualTotal;

        return Scaffold(
          appBar: AppBar(title: Text('${plan.name} Analysis')),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- 1. Key Summary Card ---
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Period: ${DateFormat.yMd().format(plan.startDate)} - ${DateFormat.yMd().format(plan.endDate)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Divider(),
                      _StatRow('Initial Budget', totalPlanned, Colors.blue),
                      _StatRow('Actual Spending', actualTotal, Colors.red),
                      _StatRow(
                        difference >= 0 ? 'Budget Remaining' : 'Over Budget',
                        difference.abs(),
                        difference >= 0 ? Colors.green : Colors.deepOrange,
                        isDifference: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. Category Pie Chart (Based on Actual Spending) ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Breakdown (Actual Expenses)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      SizedBox(
                        height: 250,
                        child: ExpensePieChart(
                          categoryTotals: categoryTotals,
                          totalAmount: actualTotal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 3. Expense List ---
              Text(
                'Expenses in Period (${actualExpenses.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              ...actualExpenses
                  .map(
                    (expense) => ListTile(
                      title: Text(expense.name),
                      subtitle: Text(
                        '${expense.category} | ${DateFormat.yMd().format(expense.date)}',
                      ),
                      trailing: Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isDifference;

  const _StatRow(
    this.label,
    this.amount,
    this.color, {
    this.isDifference = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isDifference ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            // FIX: Simplified the string interpolation for the amount.
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
