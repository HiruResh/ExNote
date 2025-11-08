// lib/pages/settings_page.dart (FULL CODE)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
              // Placeholder: In a real app, this would navigate to a Category Management screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category management feature coming soon!'),
                ),
              );
            },
          ),
          const Divider(),

          // --- 3. Database Management (Reset/Backup Placeholder) ---
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
              onPressed: () {
                // In a full implementation, you'd call a DatabaseService.reset() method here.
                // For now, we'll just show a confirmation.
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data reset initiated (Placeholder).'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
