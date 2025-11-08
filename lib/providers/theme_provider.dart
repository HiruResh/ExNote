import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Method used by CustomDrawer
  void setThemeMode(ThemeMode mode) {
    if (mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  // Method used by SettingsPage
  void toggleTheme(bool isDarkMode) {
    // If isDarkMode is true, set the mode to dark, otherwise set it to light.
    final newMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    // We can reuse the setThemeMode logic to avoid repetition and notify listeners.
    setThemeMode(newMode);
  }
}
