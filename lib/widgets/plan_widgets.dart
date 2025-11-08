// lib/widgets/plan_widgets.dart (FULL CODE)

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
                  labelText: 'Planned Amount (\$)',
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
              '\$${item.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            const Icon(Icons.drag_handle, size: 20),
          ],
        ),
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
              '\$${item.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: item.isCompleted ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
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
              'Period: ${plan.type.name.toUpperCase()} | Budget: \$${plan.maxAmount.toStringAsFixed(2)}',
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
          '\$${amount.toStringAsFixed(2)}',
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
