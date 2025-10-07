import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/purchase_decision.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eco_gain.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE purchase_decisions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        price REAL NOT NULL,
        work_hours REAL NOT NULL,
        decision TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        hourly_rate REAL NOT NULL,
        yearly_salary REAL NOT NULL,
        monthly_salary REAL NOT NULL,
        hours_per_week REAL DEFAULT 40.0,
        weeks_per_year REAL DEFAULT 52.0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the new columns with default values
      await db.execute('ALTER TABLE purchase_decisions ADD COLUMN hours_per_week REAL DEFAULT 40.0');
      await db.execute('ALTER TABLE purchase_decisions ADD COLUMN weeks_per_year REAL DEFAULT 52.0');
    }
  }

  Future<int> insertDecision(PurchaseDecision decision) async {
    final db = await database;
    return await db.insert('purchase_decisions', decision.toMap());
  }

  Future<List<PurchaseDecision>> getAllDecisions() async {
    final db = await database;
    final result = await db.query(
      'purchase_decisions',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => PurchaseDecision.fromMap(map)).toList();
  }

  Future<List<PurchaseDecision>> getDecisionsByType(String decision) async {
    final db = await database;
    final result = await db.query(
      'purchase_decisions',
      where: 'decision = ?',
      whereArgs: [decision],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => PurchaseDecision.fromMap(map)).toList();
  }

  Future<int> deleteDecision(int id) async {
    final db = await database;
    return await db.delete(
      'purchase_decisions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
