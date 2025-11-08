// lib/main.dart (CORRECTED IMPORTS AND DATABASE INITIALIZATION)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exnote/pages/home_page.dart';
import 'package:exnote/providers/expense_provider.dart';
import 'package:exnote/providers/note_provider.dart';
import 'package:exnote/providers/plan_provider.dart';
import 'package:exnote/providers/theme_provider.dart';
import 'package:exnote/services/database_service.dart';
import 'package:exnote/utils/app_themes.dart';
import 'package:sqflite_common/sqflite.dart';
// FIX 1: Change import to the main package entry for common usage
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX 2: Check for kIsWeb or other environments and initialize factory
  if (kIsWeb) {
    // databaseFactoryFfi is now available thanks to the corrected import
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database instance before running the app
  final dbService = DatabaseService.instance;
  await dbService.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // These calls are now valid because the providers will be updated below
        ChangeNotifierProvider(create: (_) => ExpenseProvider(dbService)),
        ChangeNotifierProvider(create: (_) => NoteProvider(dbService)),
        ChangeNotifierProvider(create: (_) => PlanProvider(dbService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Expense Tracker & Notes',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const HomePage(),
    );
  }
}
