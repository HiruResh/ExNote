// lib/pages/add_expense_modal.dart (UPDATED)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/expense.dart';
import 'package:exnote/providers/expense_provider.dart';

class AddExpenseModal extends StatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseModal({super.key, this.expenseToEdit});

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController; // NEW CONTROLLER
  late String _selectedCategory;
  late DateTime _selectedDate;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Housing',
    'Utilities',
    'Health',
    'Education',
    'Other',
  ];

  // NEW: Pre-defined amount increments
  final List<int> _amountIncrements = [1, 10, 100, 1000, 10000, 100000];

  // NEW: Pre-defined name suggestions (Title, Category)
  final List<Map<String, String>> _nameSuggestions = [
    {'title': 'Lunch', 'category': 'Food'},
    {'title': 'Snacks', 'category': 'Food'},
    {'title': 'Coffee', 'category': 'Food'},
    {'title': 'Bus', 'category': 'Transport'},
    {'title': 'Train', 'category': 'Transport'},
    {'title': 'Gas', 'category': 'Transport'},
    {'title': 'Groceries', 'category': 'Shopping'},
    {'title': 'Movie', 'category': 'Entertainment'},
  ];

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseToEdit;

    _nameController = TextEditingController(text: expense?.name ?? '');
    _amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    ); // Initialize
    _selectedCategory = expense?.category ?? _categories.first;
    _selectedDate = expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // NEW: Function to add amount increment
  void _addAmount(int increment) {
    setState(() {
      double currentAmount = double.tryParse(_amountController.text) ?? 0.0;
      currentAmount += increment;
      _amountController.text = currentAmount.toStringAsFixed(
        0,
      ); // Display as integer if possible
    });
  }

  // NEW: Function to apply name/category suggestion
  void _applySuggestion(String title, String category) {
    setState(() {
      _nameController.text = title;
      // Only change category if the suggested category exists in the list
      if (_categories.contains(category)) {
        _selectedCategory = category;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.expenseToEdit?.id,
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text, // Save optional description
      );

      final provider = Provider.of<ExpenseProvider>(context, listen: false);

      if (widget.expenseToEdit == null) {
        provider.addExpense(expense);
      } else {
        provider.updateExpense(expense);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.expenseToEdit == null
                    ? 'Add New Expense'
                    : 'Edit Expense',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),

              // --- 1. Title/Name Input and Suggestion Buttons ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Title (e.g., Coffee, Dinner)',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),

              const SizedBox(height: 8),
              // NEW: Name Suggestion Buttons
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _nameSuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(
                      '${suggestion['title']!} (${suggestion['category']!})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _applySuggestion(
                      suggestion['title']!,
                      suggestion['category']!,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // --- 2. Amount Input and Increment Buttons ---
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)',
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (value) =>
                    (value!.isEmpty || double.tryParse(value) == null)
                    ? 'Enter a valid amount'
                    : null,
              ),

              const SizedBox(height: 8),
              // NEW: Amount Increment Buttons
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _amountIncrements.map((amount) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero, // Remove minimum size constraint
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _addAmount(amount),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      amount >= 1000
                          ? '${(amount / 1000).toStringAsFixed(0)}K'
                          : amount.toString(),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // --- 3. Description Input ---
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // --- 4. Category Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 20),

              // --- 5. Date Picker ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMEd().format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 30),

              // --- 6. Action Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveExpense,
                    child: Text(
                      widget.expenseToEdit == null
                          ? 'Save Expense'
                          : 'Update Expense',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
