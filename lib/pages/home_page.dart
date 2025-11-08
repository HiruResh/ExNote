// lib/pages/home_page.dart (FULL CODE - FIX: Calling public loadExpenses)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/expense.dart';
import 'package:exnote/pages/add_expense_modal.dart';
import 'package:exnote/pages/notes_page.dart';
import 'package:exnote/pages/planner_page.dart';
import 'package:exnote/pages/settings_page.dart';
import 'package:exnote/pages/statistics_page.dart';
import 'package:exnote/providers/expense_provider.dart';
import 'package:exnote/widgets/custom_drawer.dart';
import 'package:exnote/widgets/expense_item_card.dart';
import 'package:exnote/widgets/expense_bar_chart.dart';
import 'package:exnote/widgets/upcoming_notes_carousel.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet: Expense & Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reload all core data when refreshing the main screen
              Provider.of<ExpenseProvider>(
                context,
                listen: false,
              ).loadExpenses(); // <-- FIX APPLIED HERE: Changed to loadExpenses()
              // Provider.of<NoteProvider>(context, listen: false)._loadNotes(); // Assuming NoteProvider is auto-reloading
              // Provider.of<PlanProvider>(context, listen: false)._loadAllData(); // Assuming PlanProvider is auto-reloading
            },
          ),
        ],
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
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Separate widget for the actual home page content
class _HomeContent extends StatelessWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        // Find the maximum expense to display on the chart toggle
        double maxExpense = expenseProvider.expenses.isNotEmpty
            ? expenseProvider.expenses
                  .map((e) => e.amount)
                  .reduce((a, b) => a > b ? a : b)
            : 0.0;

        return Column(
          children: [
            // 1. Upcoming Notes Carousel
            const UpcomingNotesCarousel(),

            // 2. Bar Graph for Daily/Weekly/Monthly Expenses
            // Note: Padding is added inside the widget for the black background container
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
                    'Max: \$${maxExpense.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // 4. Expenses List
            Expanded(
              child: expenseProvider.expenses.isEmpty
                  ? const Center(child: Text('No expenses yet. Add one!'))
                  : ListView.builder(
                      itemCount: expenseProvider.expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenseProvider.expenses[index];
                        return Dismissible(
                          key: Key(expense.id.toString()),
                          direction: DismissDirection
                              .horizontal, // Allows both directions
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20.0),
                            color: Colors.blueAccent,
                            child: const Icon(Icons.edit, color: Colors.white),
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
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
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
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (delete == true) {
                                expenseProvider.deleteExpense(expense.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                builder: (context) =>
                                    AddExpenseModal(expenseToEdit: expense),
                              );
                              return false; // Don't dismiss the item, just show modal
                            }
                            return false;
                          },
                          child: ExpenseItemCard(expense: expense),
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
