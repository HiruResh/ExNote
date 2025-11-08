import 'package:flutter/material.dart';
import 'package:exnote/models/expense.dart';
import 'package:exnote/services/database_service.dart';
import 'package:exnote/services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  // FIX: Service is now initialized with the injected DatabaseService
  final ExpenseService _expenseService;
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  // FIX: Constructor now requires DatabaseService instance
  ExpenseProvider(DatabaseService dbService)
    : _expenseService = ExpenseService(dbService) {
    // Assume ExpenseService accepts dbService
    loadExpenses();
  }

  // FIX 1: Make loadExpenses public
  Future<void> loadExpenses() async {
    _expenses = await _expenseService.readAllExpenses();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseService.create(expense);
    await loadExpenses(); // Reload all expenses after adding
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseService.update(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _expenseService.delete(id);
    await loadExpenses();
  }

  // --- Data Aggregation Methods for Charts ---

  // Helper function to get expenses for a given day
  List<Expense> getDailyExpenses(DateTime date) {
    return _expenses.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  // Helper function to get expenses for a given month
  List<Expense> getMonthlyExpenses(DateTime date) {
    return _expenses.where((e) {
      return e.date.year == date.year && e.date.month == date.month;
    }).toList();
  }

  // FIX 2: Make readExpensesByDateRange public
  List<Expense> readExpensesByDateRange(DateTime start, DateTime end) {
    // Normalize dates to include the entire end day
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return _expenses.where((e) {
      return (e.date.isAfter(normalizedStart) ||
              e.date.isAtSameMomentAs(normalizedStart)) &&
          (e.date.isBefore(normalizedEnd) ||
              e.date.isAtSameMomentAs(normalizedEnd));
    }).toList();
  }

  // Function to calculate total expense by category for a list of expenses
  Map<String, double> getCategoryTotals(List<Expense> expenses) {
    final Map<String, double> totals = {};
    for (var expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  // Function to get Bar Chart data (Daily Totals for a week/range)
  Map<DateTime, double> getDailyTotalsForRange(DateTime start, DateTime end) {
    final Map<DateTime, double> dailyTotals = {};

    // Normalize start/end dates for comparison
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    // Initialize all days in the range to 0
    for (
      var i = 0;
      i <= normalizedEnd.difference(normalizedStart).inDays;
      i++
    ) {
      final date = normalizedStart.add(Duration(days: i));
      dailyTotals[date] = 0.0;
    }

    // Populate with actual expense totals
    for (var expense in _expenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      if ((expenseDate.isAfter(
                normalizedStart.subtract(const Duration(days: 1)),
              ) ||
              expenseDate.isAtSameMomentAs(normalizedStart)) &&
          (expenseDate.isBefore(normalizedEnd.add(const Duration(days: 1))))) {
        dailyTotals.update(
          expenseDate,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
    }
    return dailyTotals;
  }
}
