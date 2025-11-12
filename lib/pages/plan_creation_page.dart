// lib/pages/plan_creation_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/plan.dart';
import 'package:exnote/models/plan_item.dart';
import 'package:exnote/providers/plan_provider.dart';
import 'package:exnote/widgets/plan_widgets.dart'; // Imports the updated modal and tile

class PlanCreationPage extends StatefulWidget {
  const PlanCreationPage({super.key});

  @override
  State<PlanCreationPage> createState() => _PlanCreationPageState();
}

class _PlanCreationPageState extends State<PlanCreationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _maxAmountController;
  PlanType _selectedType = PlanType.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  List<PlanItem> _tempItems = [];
  int _orderCounter = 0; // Tracks the next display order for new items

  // Suggested Plan Names for Autocomplete (Duplicated for PlanCreationPage use)
  static const List<String> _planNameSuggestions = [
    'Monthly Groceries',
    'Vacation Travel Fund',
    'Home Renovation Budget',
    'Student Budget',
    'Weekly Allowance',
    'Car Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _maxAmountController = TextEditingController();
    _updateEndDate(_selectedType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _updateEndDate(PlanType type) {
    DateTime end;
    switch (type) {
      case PlanType.daily:
        end = _startDate;
        break;
      case PlanType.weekly:
        end = _startDate.add(const Duration(days: 6));
        break;
      case PlanType.monthly:
        // Go to the last day of the current month
        end = DateTime(_startDate.year, _startDate.month + 1, 0);
        break;
      case PlanType.custom:
        end = _endDate;
        break;
    }
    setState(() {
      _selectedType = type;
      _endDate = end;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _savePlan() async {
    if (_formKey.currentState!.validate()) {
      final newPlan = Plan(
        name: _nameController.text,
        type: _selectedType,
        maxAmount: double.parse(_maxAmountController.text),
        startDate: _startDate,
        endDate: _endDate,
        isActive: false, // Don't activate immediately
      );

      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      await planProvider.addPlan(newPlan, _tempItems);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan created successfully!')),
      );
      Navigator.pop(context); // Go back to Planner Hub
    }
  }

  void _showAddItemModal([PlanItem? itemToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPlanItemModal(
        planId: 0, // Placeholder ID since plan isn't saved yet
        itemToEdit: itemToEdit,
        onSave: (name, amount, description) {
          setState(() {
            if (itemToEdit == null) {
              // Add new item
              _tempItems.add(
                PlanItem(
                  planId: 0,
                  name: name,
                  amount: amount,
                  description: description,
                  // Use a unique ID/key for temporary items for editing/deleting before save
                  id: -1 - _tempItems.length,
                  displayOrder: _orderCounter++,
                ),
              );
            } else {
              // Edit existing item
              final index = _tempItems.indexWhere((i) => i.id == itemToEdit.id);
              if (index != -1) {
                _tempItems[index] = itemToEdit.copyWith(
                  name: name,
                  amount: amount,
                  description: description,
                );
              }
            }
          });
        },
      ),
    );
  }

  void _deleteItem(PlanItem item) {
    setState(() {
      _tempItems.removeWhere((i) => i.id == item.id);
    });
    // Re-index after deletion
    for (int i = 0; i < _tempItems.length; i++) {
      _tempItems[i] = _tempItems[i].copyWith(displayOrder: i);
    }
  }

  void _addAmountToBudget(double amount) {
    double currentAmount = double.tryParse(_maxAmountController.text) ?? 0.0;
    _maxAmountController.text = (currentAmount + amount).toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Spending Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Plan Name with Autocomplete (UPGRADED) ---
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _planNameSuggestions.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                      _nameController = textController;
                      return TextFormField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Plan Name (e.g., Groceries, Travel Fund)',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter a name' : null,
                      );
                    },
                onSelected: (String selection) {
                  _nameController.text = selection;
                },
              ),
              const SizedBox(height: 16),

              // --- Budget Field with Quick Select Buttons ---
              TextFormField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum Spending Amount (Rs.)',
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (v) => (v!.isEmpty || double.tryParse(v) == null)
                    ? 'Enter a valid amount'
                    : null,
              ),
              const SizedBox(height: 8),
              // Fast Amount Selection Buttons
              Wrap(
                spacing: 8.0,
                children: [500.0, 1000.0, 5000.0, 10000.0]
                    .map(
                      (amount) => ActionChip(
                        label: Text('+ Rs.${amount.toStringAsFixed(0)}'),
                        onPressed: () => _addAmountToBudget(amount),
                      ),
                    )
                    .toList(),
              ),
              // --- End Budget Field ---
              const SizedBox(height: 20),

              // Plan Type Selection
              Text(
                'Plan Duration Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8.0,
                children: PlanType.values
                    .map(
                      (type) => ChoiceChip(
                        label: Text(type.name.toUpperCase()),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          if (selected) _updateEndDate(type);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Date Range
              ListTile(
                title: const Text('Plan Period'),
                subtitle: Text(
                  '${_startDate.toIso8601String().split('T').first} to ${_endDate.toIso8601String().split('T').first}',
                ),
                trailing: _selectedType == PlanType.custom
                    ? const Icon(Icons.edit)
                    : const Icon(Icons.calendar_month),
                onTap: _selectedType == PlanType.custom
                    ? _selectDateRange
                    : null,
              ),
              const Divider(),
              const SizedBox(height: 10),

              // Planned Items List Header
              Text(
                'Planned Expenses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),

              // Planned Items List
              _tempItems.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'Add cards for individual expenses (e.g., Flight, Dinner).',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tempItems.length,
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _tempItems.removeAt(oldIndex);
                          _tempItems.insert(newIndex, item);
                          // Re-index display order
                          for (int i = 0; i < _tempItems.length; i++) {
                            _tempItems[i] = _tempItems[i].copyWith(
                              displayOrder: i,
                            );
                          }
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = _tempItems[index];
                        return Dismissible(
                          key: ValueKey(item.id), // Use the unique temp ID/key
                          direction: DismissDirection.endToStart,
                          // Swipe for Edit (instead of delete)
                          background: Container(
                            color: Theme.of(context).colorScheme.primary,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              // Perform Edit on swipe
                              _showAddItemModal(item);
                              return false; // Don't dismiss the item
                            }
                            return true; // Dismiss on any other direction (default behavior)
                          },
                          // Secondary background for Delete on left-to-right swipe (Optional)
                          secondaryBackground: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              _deleteItem(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} deleted.'),
                                ),
                              );
                            }
                          },
                          child: PlanItemCreationTile(
                            key: ValueKey(item.id),
                            item: item,
                            onEdit: () => _showAddItemModal(item),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: _savePlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'Save Plan',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      // --- Floating Action Button for Adding Expenses ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemModal(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
