// lib/pages/settings_page.dart (FIXED)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/providers/theme_provider.dart';
import 'package:exnote/services/database_service.dart';
import 'package:exnote/providers/expense_provider.dart';
// Add other providers (NoteProvider, PlanProvider) here if needed for reloading.

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the color for the AppBar title for contrast
    final titleColor =
        Theme.of(context).appBarTheme.titleTextStyle?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: titleColor), // Apply the determined color
        ),
      ),
      body: ListView(
        children: [
          // --- 1. Theme Management ---
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle between Light and Dark theme'),
                secondary: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              );
            },
          ),
          const Divider(),

          // --- 2. Category Management Placeholder ---
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, edit, or remove expense categories'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category management feature coming soon!'),
                ),
              );
            },
          ),
          const Divider(),

          // --- 3. Database Management (Reset) ---
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.red),
            title: const Text('Reset Application Data'),
            subtitle: const Text(
              'Permanently delete all expenses, notes, and plans',
            ),
            trailing: const Icon(Icons.warning_amber, color: Colors.red),
            onTap: () {
              _showResetDialog(context);
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Data Reset"),
          content: const Text(
            "Are you absolutely sure? This will delete all your saved expenses, notes, and plans permanently.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Reset", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog

                try {
                  // Call the actual reset logic
                  await DatabaseService.instance.resetDatabase();

                  // Reset the state of relevant providers (MUST have a load method)
                  await Provider.of<ExpenseProvider>(
                    context,
                    listen: false,
                  ).loadExpenses();
                  // Await Provider.of<NoteProvider>(context, listen: false).loadNotes();
                  // Await Provider.of<PlanProvider>(context, listen: false).loadPlans();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'All application data has been permanently deleted.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error resetting data: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
