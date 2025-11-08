// lib/pages/plan_history_page.dart (FULL CODE)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/plan.dart';
import 'package:exnote/pages/plan_statistics_page.dart'; // NEW IMPORT
import 'package:exnote/providers/plan_provider.dart';

class PlanHistoryPage extends StatelessWidget {
  const PlanHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Saved Plans')),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, child) {
          if (planProvider.allPlans.isEmpty) {
            return const Center(child: Text('No plans created yet.'));
          }
          return ListView.builder(
            itemCount: planProvider.allPlans.length,
            itemBuilder: (context, index) {
              final plan = planProvider.allPlans[index];
              return PlanHistoryTile(plan: plan);
            },
          );
        },
      ),
    );
  }
}

class PlanHistoryTile extends StatelessWidget {
  final Plan plan;

  const PlanHistoryTile({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          plan.isActive ? Icons.check_circle : Icons.calendar_today,
          color: plan.isActive ? Colors.green : Theme.of(context).primaryColor,
        ),
        title: Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          'Budget: \$${plan.maxAmount.toStringAsFixed(2)}\nPeriod: ${DateFormat.yMd().format(plan.startDate)} - ${DateFormat.yMd().format(plan.endDate)}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'activate') {
              await planProvider.activatePlan(plan);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${plan.name} activated!')),
              );
              // No need to navigate, PlanPage handles view update
            } else if (value == 'stats') {
              // --- NAVIGATION ADDED HERE ---
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlanStatisticsPage(plan: plan),
                ),
              );
              // -----------------------------
            } else if (value == 'delete') {
              await planProvider.deletePlan(plan.id!);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${plan.name} deleted.')));
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (!plan.isActive)
              const PopupMenuItem<String>(
                value: 'activate',
                child: Text('Activate Plan'),
              ),
            const PopupMenuItem<String>(
              value: 'stats',
              child: Text('View Statistics'),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete Plan', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
