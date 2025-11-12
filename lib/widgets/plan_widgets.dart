// lib/widgets/plan_widgets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/plan.dart';
import 'package:exnote/models/plan_item.dart';
import 'package:exnote/providers/plan_provider.dart';

// --- Suggested Items for Autocomplete ---
const List<String> _itemSuggestions = [
  'Groceries',
  'Rent',
  'Car Payment',
  'Dinner Out',
  'Flight Ticket',
  'Hotel Stay',
  'New Clothes',
  'Phone Bill',
  'Gas/Fuel',
  'Gym Membership',
];

// ---------------------------------------------
// 1. Add/Edit Plan Item Modal (UPGRADED: Autocomplete & Quick Amounts)
// ---------------------------------------------
class AddPlanItemModal extends StatefulWidget {
  final int planId;
  final PlanItem? itemToEdit;
  final Function(String name, double amount, String? description)?
  onSave; // For creation page

  const AddPlanItemModal({
    super.key,
    required this.planId,
    this.itemToEdit,
    this.onSave,
  });

  @override
  State<AddPlanItemModal> createState() => _AddPlanItemModalState();
}

class _AddPlanItemModalState extends State<AddPlanItemModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.itemToEdit?.name ?? '',
    );
    _amountController = TextEditingController(
      text: widget.itemToEdit?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.itemToEdit?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text;

      if (widget.onSave != null) {
        // Case 1: Saving temporary item during Plan Creation
        widget.onSave!(name, amount, description);
      } else {
        // Case 2: Saving to an Active/Existing Plan (uses PlanProvider)
        final provider = Provider.of<PlanProvider>(context, listen: false);
        final newItem = PlanItem(
          id: widget.itemToEdit?.id,
          planId: widget.planId,
          name: name,
          amount: amount,
          description: description,
          isCompleted: widget.itemToEdit?.isCompleted ?? false,
          displayOrder:
              widget.itemToEdit?.displayOrder ??
              999, // Use existing order or large number
        );

        if (widget.itemToEdit == null) {
          await provider.addPlanItem(newItem);
        } else {
          await provider.updatePlanItem(newItem);
        }
      }

      Navigator.pop(context);
    }
  }

  void _addAmountToItem(double amount) {
    double currentAmount = double.tryParse(_amountController.text) ?? 0.0;
    _amountController.text = (currentAmount + amount).toStringAsFixed(0);
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
                widget.itemToEdit == null
                    ? 'Add Planned Item'
                    : 'Edit Planned Item',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              // --- Autocomplete Text Field for Name ---
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _itemSuggestions.where((String option) {
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
                          labelText: 'Item Name (e.g., Gas, New Shoes)',
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter name' : null,
                        onFieldSubmitted: (String value) {
                          onFieldSubmitted();
                        },
                      );
                    },
                onSelected: (String selection) {
                  _nameController.text = selection;
                },
              ),
              const SizedBox(height: 10),

              // --- Amount Text Field ---
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Planned Amount (Rs.)',
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (v) => (v!.isEmpty || double.tryParse(v) == null)
                    ? 'Enter valid amount'
                    : null,
              ),
              const SizedBox(height: 8),
              // --- Quick Amount Buttons ---
              Wrap(
                spacing: 8.0,
                children: [500.0, 1000.0, 2000.0]
                    .map(
                      (amount) => ActionChip(
                        label: Text('+ Rs.${amount.toStringAsFixed(0)}'),
                        onPressed: () => _addAmountToItem(amount),
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveItem,
                    child: Text(
                      widget.itemToEdit == null ? 'Add Item' : 'Update Item',
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

// ---------------------------------------------
// 2. Tile for a Planned Item in Creation Page
// ---------------------------------------------

class PlanItemCreationTile extends StatelessWidget {
  final PlanItem item;
  final VoidCallback onEdit;

  const PlanItemCreationTile({
    super.key,
    required this.item,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(item.description ?? 'No description'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rs.${item.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.drag_handle, size: 20),
          ],
        ),
        onTap: onEdit, // Tap also opens edit
      ),
    );
  }
}

// ---------------------------------------------
// 3. Tile for a Planned Item in Ongoing View
// ---------------------------------------------
class PlannedItemTile extends StatelessWidget {
  final PlanItem item;
  final Function(bool?) onToggle;
  final VoidCallback onEdit;

  const PlannedItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: item.isCompleted
          ? Theme.of(context).cardColor.withOpacity(0.5)
          : Theme.of(context).cardColor,
      child: ListTile(
        onTap: onEdit, // Tap also opens edit
        leading: Checkbox(value: item.isCompleted, onChanged: onToggle),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(item.description ?? 'Tap to edit/swipe to delete'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rs.${item.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: item.isCompleted ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.drag_handle, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------
// 4. Summary Card for Ongoing Plan View (REFACTORED for better layout)
// ---------------------------------------------
class PlanSummaryCard extends StatelessWidget {
  final Plan plan;
  final double totalPlanned;
  final double totalCompleted;
  final double totalRemaining;

  const PlanSummaryCard({
    super.key,
    required this.plan,
    required this.totalPlanned,
    required this.totalCompleted,
    required this.totalRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final spentPercentage = plan.maxAmount > 0
        ? (totalCompleted / plan.maxAmount).clamp(0.0, 1.0)
        : 0.0;
    final remainingColor = totalRemaining >= 0
        ? Colors.green
        : Colors.deepOrange;

    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Row 1: Title and Item Count ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Budget: Rs.${plan.maxAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: remainingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // --- Top Right: Items Planned Count ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        totalPlanned.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Planned',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- Row 2: Remaining Card (TOP) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: remainingColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: remainingColor, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    'REMAINING',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: remainingColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Rs.${totalRemaining.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: remainingColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // --- Row 3: Spent Card (BELOW) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL SPENT',
                    style: TextStyle(fontSize: 14, color: Colors.redAccent),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Rs.${totalCompleted.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 30),

            // --- Progress Bar ---
            Text(
              'Progress: ${(spentPercentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: spentPercentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(remainingColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------
// 5. Edit Plan Modal (Unchanged as it didn't have issues)
// ---------------------------------------------
class EditPlanModal extends StatefulWidget {
  final Plan plan;

  const EditPlanModal({super.key, required this.plan});

  @override
  State<EditPlanModal> createState() => _EditPlanModalState();
}

class _EditPlanModalState extends State<EditPlanModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _maxAmountController;
  late PlanType _selectedType;
  late DateTime _startDate;
  late DateTime _endDate;

  // Suggested Plan Names for Autocomplete
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
    _nameController = TextEditingController(text: widget.plan.name);
    _maxAmountController = TextEditingController(
      text: widget.plan.maxAmount.toString(),
    );
    _selectedType = widget.plan.type;
    _startDate = widget.plan.startDate;
    _endDate = widget.plan.endDate;
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
      final updatedPlan = widget.plan.copyWith(
        name: _nameController.text,
        type: _selectedType,
        maxAmount: double.parse(_maxAmountController.text),
        startDate: _startDate,
        endDate: _endDate,
      );

      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      await planProvider.updatePlan(updatedPlan);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan updated successfully!')),
      );
      Navigator.pop(context);
    }
  }

  void _addAmountToBudget(double amount) {
    double currentAmount = double.tryParse(_maxAmountController.text) ?? 0.0;
    _maxAmountController.text = (currentAmount + amount).toStringAsFixed(0);
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
                'Edit Plan Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              // --- Autocomplete Text Field for Plan Name (Added here too) ---
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
                          labelText: 'Plan Name',
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
              const SizedBox(height: 20),

              // Plan Duration
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

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _savePlan,
                    child: const Text('Update Plan'),
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
