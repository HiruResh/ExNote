import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/plan.dart';
import 'package:exnote/models/plan_item.dart';
import 'package:exnote/providers/plan_provider.dart';

// ---------------------------------------------
// 1. Add/Edit Plan Item Modal
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name (e.g., Gas, New Shoes)',
                ),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 10),
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
  final VoidCallback onEdit; // Kept for tap on tile, but swipe is primary edit

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
            // The edit button is redundant with the new swipe-to-edit feature.
            // IconButton(
            //   icon: const Icon(Icons.edit, size: 20),
            //   onPressed: onEdit,
            // ),
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
  final VoidCallback onEdit; // Kept for tap on tile, but swipe is primary edit

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
            // The edit button is redundant with the new swipe-to-edit feature.
            // IconButton(
            //   icon: const Icon(Icons.edit, size: 20),
            //   onPressed: onEdit,
            // ),
            const Icon(Icons.drag_handle, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------
// 4. Summary Card for Ongoing Plan View
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
    final spentPercentage = (totalCompleted / plan.maxAmount) * 100;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Period: ${plan.type.name.toUpperCase()} | Budget: Rs.${plan.maxAmount.toStringAsFixed(2)}',
            ),
            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryMetric(
                  label: 'Spent',
                  amount: totalCompleted,
                  color: Colors.redAccent,
                ),
                _SummaryMetric(
                  label: 'Remaining',
                  amount: totalRemaining,
                  color: totalRemaining >= 0 ? Colors.green : Colors.deepOrange,
                ),
                _SummaryMetric(
                  label: 'Items Planned',
                  amount: totalPlanned,
                  color: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            Text(
              'Progress: ${spentPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalCompleted / plan.maxAmount,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                totalRemaining >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Rs.${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// ---------------------------------------------
// 5. Edit Plan Modal (New)
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Plan Name'),
                validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
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
