// lib/pages/instruction_page.dart
import 'package:flutter/material.dart';

class InstructionPage extends StatelessWidget {
  const InstructionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Instructions'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to ExNote!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Divider(height: 10),
            Text(
              'Built by -Hirusha',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(height: 30),

            _buildInstructionCard(
              context,
              icon: Icons.add_circle_outline,
              title: 'Adding an Expense (Home Screen)',
              content:
                  'Use the **floating plus button** (FAB) on the Home screen to quickly log a new expense. Input the amount, category, and date.',
            ),

            _buildInstructionCard(
              context,
              icon: Icons.swipe_left_alt,
              title: 'Edit & Delete (Home Screen List)',
              content:
                  'In the **Recent Expenses** list, swipe an item left to **Delete** it, or swipe right to **Edit** the expense in a modal.',
            ),

            _buildInstructionCard(
              context,
              icon: Icons.bar_chart,
              title: 'Understanding Statistics',
              content:
                  'The Statistics tab features a **Pie Chart** (category breakdown) and **Line Chart** (spending trends). Use the filters to view data by day, week, or month.',
            ),

            _buildInstructionCard(
              context,
              icon: Icons.note_alt,
              title: 'Managing Notes',
              content:
                  'The Notes tab is for any reminders or financial planning notes. You can see important upcoming notes in the **carousel** on the Home screen.',
            ),

            _buildInstructionCard(
              context,
              icon: Icons.web,
              title: 'More Informatio and Updates',
              content:
                  'visit https://github.com/HirushaReshan/ExNote for new updates.',
            ),

            const SizedBox(height: 20),
            Text(
              'Tip: Use the Drawer to quickly access Settings and Dark Mode!',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(content),
            ],
          ),
        ),
      ),
    );
  }
}
