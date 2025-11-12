// lib/pages/home_page.dart (UPDATED with AppBar Design)
import 'package:exnote/pages/add_expense_modal.dart';
import 'package:exnote/pages/notes_page.dart';
import 'package:exnote/pages/planner_page.dart';
import 'package:exnote/pages/statistics_page.dart';
import 'package:exnote/providers/expense_provider.dart';
import 'package:exnote/widgets/custom_drawer.dart';
import 'package:exnote/widgets/expense_bar_chart.dart';
import 'package:exnote/widgets/expense_item_card.dart';
import 'package:exnote/widgets/upcoming_notes_carousel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/expense.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // For Bottom Navigation Bar

  // The screens for the Bottom Navigation Bar
  static final List<Widget> _widgetOptions = <Widget>[
    const _HomeContent(), // Actual home content
    const StatisticsPage(),
    const PlannerPage(),
    const NotesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current theme is dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine selected color: White in dark mode, PrimaryColor in light mode
    final selectedNavColor = isDarkMode
        ? Colors.white
        : Theme.of(context).primaryColor;
    // Determine unselected color: Light grey in dark mode, Dark grey in light mode
    final unselectedNavColor = isDarkMode ? Colors.grey[600] : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        // NEW DESIGN
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            children: [
              TextSpan(
                text: 'Ex',
                style: TextStyle(
                  color: Theme.of(context).primaryColor, // Highlight 'Ex'
                ),
              ),
              TextSpan(
                text: 'Note',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Normal color for 'Note'
                ),
              ),
            ],
          ),
        ),
        centerTitle: false, // Title aligned to the start
        elevation: 2.0, // Add subtle elevation
        // REFRESH BUTTON REMOVED (No actions needed here)
        actions: const [],
      ),
      drawer: const CustomDrawer(),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton:
          _selectedIndex ==
              0 // Only show FAB on Home screen
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddExpenseModal(),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Planner',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Notes'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: selectedNavColor,
        unselectedItemColor: unselectedNavColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Separate widget for the actual home page content (remains the same)
class _HomeContent extends StatelessWidget {
  const _HomeContent({Key? key}) : super(key: key);

  // --- HELPER FUNCTION TO GROUP EXPENSES ---
  Map<String, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final Map<String, List<Expense>> groupedExpenses = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFormatter = DateFormat('EEEE, MMM d, yyyy');

    // Sort expenses by date in descending order (most recent first)
    expenses.sort((a, b) => b.date.compareTo(a.date));

    for (var expense in expenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      String dateKey;
      if (expenseDate.isAtSameMomentAs(today)) {
        dateKey = 'Today';
      } else if (expenseDate.isAtSameMomentAs(yesterday)) {
        dateKey = 'Yesterday';
      } else {
        dateKey = dateFormatter.format(expenseDate);
      }

      groupedExpenses.putIfAbsent(dateKey, () => []).add(expense);
    }
    return groupedExpenses;
  }
  // --- END HELPER FUNCTION ---

  @override
  Widget build(BuildContext context) {
    // Check if the current theme is dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine max expense text color: White in dark mode, PrimaryColor in light mode
    final maxExpenseColor = isDarkMode
        ? Colors.white
        : Theme.of(context).primaryColor;

    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        // Find the maximum expense to display on the chart toggle
        double maxExpense = expenseProvider.expenses.isNotEmpty
            ? expenseProvider.expenses
                  .map((e) => e.amount)
                  .reduce((a, b) => a > b ? a : b)
            : 0.0;

        // Group expenses for the list display
        final groupedExpenses = _groupExpensesByDate(expenseProvider.expenses);
        final dateKeys = groupedExpenses.keys.toList();

        return Column(
          children: [
            // 1. Upcoming Notes Carousel
            const UpcomingNotesCarousel(),

            // 2. Bar Graph for Daily/Weekly/Monthly Expenses
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ExpenseBarChart(),
            ),

            // 3. Expenses List Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Max: Rs.${maxExpense.toStringAsFixed(2)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: maxExpenseColor),
                  ),
                ],
              ),
            ),

            // 4. Grouped Expenses List
            Expanded(
              child: expenseProvider.expenses.isEmpty
                  ? const Center(child: Text('No expenses yet. Add one!'))
                  : ListView.builder(
                      itemCount: dateKeys.length,
                      itemBuilder: (context, dateIndex) {
                        final dateKey = dateKeys[dateIndex];
                        final expensesForDate = groupedExpenses[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Header
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                top: 10.0,
                                bottom: 5.0,
                              ),
                              child: Text(
                                dateKey,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            // List of Expenses for that date
                            ...expensesForDate.map((expense) {
                              return Dismissible(
                                key: Key(expense.id.toString()),
                                direction: DismissDirection.horizontal,
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20.0),
                                  color: Colors.blueAccent,
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  color: Colors.redAccent,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                // Edit/Delete logic (remains the same)
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    // Delete logic
                                    final bool? delete = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirm Delete"),
                                          content: const Text(
                                            "Are you sure you want to delete this expense?",
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (delete == true) {
                                      expenseProvider.deleteExpense(
                                        expense.id!,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Expense deleted'),
                                        ),
                                      );
                                    }
                                    return delete;
                                  } else if (direction ==
                                      DismissDirection.startToEnd) {
                                    // Edit logic
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => AddExpenseModal(
                                        expenseToEdit: expense,
                                      ),
                                    );
                                    return false; // Don't dismiss the item, just show modal
                                  }
                                  return false;
                                },
                                child: ExpenseItemCard(expense: expense),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
