import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      // FIX: Add onConfigure to enable Foreign Key constraints
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    // 1. EXPENSES TABLE
    await db.execute('''
CREATE TABLE expenses ( 
  id $idType, 
  name $textType,
  amount $realType,
  category $textType,
  date $textType,
  description TEXT
  )
''');

    // 2. NOTES TABLE
    await db.execute('''
CREATE TABLE notes ( 
  id $idType, 
  title $textType,
  content $textType,
  date $textType
  )
''');

    // 3. PLANS TABLE
    await db.execute('''
CREATE TABLE plans ( 
  id $idType, 
  name $textType,
  type $textType,
  maxAmount $realType,
  startDate $textType,
  endDate $textType,
  description TEXT,
  isActive $boolType
  )
''');

    // 4. PLAN_ITEMS TABLE
    await db.execute('''
CREATE TABLE plan_items ( 
  id $idType, 
  planId INTEGER NOT NULL,
  name $textType,
  amount $realType,
  description TEXT,
  isCompleted $boolType,
  displayOrder INTEGER NOT NULL,
  FOREIGN KEY (planId) REFERENCES plans (id) ON DELETE CASCADE
  )
''');
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
