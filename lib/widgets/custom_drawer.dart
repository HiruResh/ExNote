// lib/widgets/custom_drawer.dart (MODERN LOOK)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/pages/settings_page.dart';
import 'package:exnote/providers/theme_provider.dart';
import 'package:exnote/pages/instruction_page.dart'; // NEW IMPORT

// --- HELPER WIDGET FOR THE SHAPED HEADER ---
class DrawerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40); // Start curve up 40 units from bottom
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// ---------------------------------------------

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = primaryColor.withOpacity(0.1);

    return Drawer(
      child: Column(
        // Use Column to control the header and list area
        children: <Widget>[
          // --- MODERN SHAPED DRAWER HEADER ---
          Stack(
            children: [
              ClipPath(
                clipper: DrawerClipper(),
                child: Container(
                  height: 200,
                  color: primaryColor, // Base primary color background
                ),
              ),
              Container(
                height: 200,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 40,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 30,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ExNote',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Expense & Notes Tracker',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- DRAWER MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // Settings Tile
                _buildDrawerTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),

                // NEW: Instruction Page Tile
                _buildDrawerTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'Instructions / Help',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InstructionPage(),
                      ),
                    );
                  },
                ),

                // Manage Categories Tile (as before)
                _buildDrawerTile(
                  context,
                  icon: Icons.category_outlined,
                  title: 'Manage Categories',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Manage Categories Page (Coming Soon!)'),
                      ),
                    );
                  },
                ),

                const Divider(),

                // Dark Mode Switch
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.dark_mode_outlined, color: Colors.grey),
                          SizedBox(width: 28),
                          Text('Dark Mode', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeProvider.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDarkMode
        ? Colors.white10
        : Theme.of(context).primaryColor.withOpacity(0.05);

    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      tileColor: tileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }
}
