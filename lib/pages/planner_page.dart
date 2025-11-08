// lib/pages/planner_page.dart (FULL CODE)

import 'package:exnote/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/plan.dart';
import 'package:exnote/models/plan_item.dart';
import 'package:exnote/providers/expense_provider.dart';
import 'package:exnote/providers/plan_provider.dart';
import 'package:exnote/pages/plan_creation_page.dart';
import 'package:exnote/pages/plan_history_page.dart';
import 'package:exnote/widgets/plan_widgets.dart'; // We'll create this file

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlanProvider>(
      builder: (context, planProvider, child) {
        if (planProvider.activePlan != null) {
          // If a plan is active, show the ongoing tracker view
          return OngoingPlanView(
            plan: planProvider.activePlan!,
            planItems: planProvider.activePlanItems,
          );
        } else {
          // If no plan is active, show the hub to create/select one
          return PlannerHubView();
        }
      },
    );
  }
}

// ---------------------------------------------
// Hub View (No Active Plan)
// ---------------------------------------------
class PlannerHubView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Hub'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'No Active Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            const Text(
              'Start a new budget or manage your past plans.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create New Plan'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PlanCreationPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('View All Plans'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PlanHistoryPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------
// Ongoing Plan View (Plan is Active)
// ---------------------------------------------
class OngoingPlanView extends StatefulWidget {
  final Plan plan;
  final List<PlanItem> planItems;

  const OngoingPlanView({
    super.key,
    required this.plan,
    required this.planItems,
  });

  @override
  State<OngoingPlanView> createState() => _OngoingPlanViewState();
}

class _OngoingPlanViewState extends State<OngoingPlanView> {
  @override
  Widget build(BuildContext context) {
    // Calculate total planned and total remaining
    final totalPlanned = widget.planItems.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final totalCompleted = widget.planItems
        .where((item) => item.isCompleted)
        .fold(0.0, (sum, item) => sum + item.amount);
    final totalRemaining = widget.plan.maxAmount - totalCompleted;

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.plan.name} (Ongoing)'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              // Deactivate the plan
              await planProvider.updatePlan(
                widget.plan.copyWith(isActive: false),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan Deactivated.')),
              );
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Summary Card
          PlanSummaryCard(
            plan: widget.plan,
            totalPlanned: totalPlanned,
            totalCompleted: totalCompleted,
            totalRemaining: totalRemaining,
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Planned Expenses List (${widget.planItems.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          // Planned Items List
          Expanded(
            child: ReorderableListView.builder(
              itemCount: widget.planItems.length,
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = widget.planItems.removeAt(oldIndex);
                widget.planItems.insert(newIndex, item);
                planProvider.updateItemOrder(widget.plan.id!, widget.planItems);
              },
              itemBuilder: (context, index) {
                final item = widget.planItems[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    planProvider.deletePlanItem(item.id!);
                  },
                  child: PlannedItemTile(
                    key: ValueKey(
                      item.id,
                    ), // Key needed for ReorderableListView
                    item: item,
                    onToggle: (bool? value) async {
                      final updatedItem = item.copyWith(
                        isCompleted: value ?? false,
                      );
                      await planProvider.updatePlanItem(updatedItem);

                      if (value == true) {
                        // Automatically add to home expenses as an actual expense
                        await expenseProvider.addExpense(
                          Expense(
                            name: item.name,
                            amount: item.amount,
                            category:
                                "Plan: ${widget.plan.name}", // Special category
                            date: DateTime.now(),
                            description: "From Plan: ${item.description ?? ''}",
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.name} completed and recorded as expense.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    onEdit: () =>
                        _showAddPlanItemModal(context, item, widget.plan.id!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlanItemModal(context, null, widget.plan.id!),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showAddPlanItemModal(BuildContext context, PlanItem? item, int planId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPlanItemModal(planId: planId, itemToEdit: item),
    );
  }
}
