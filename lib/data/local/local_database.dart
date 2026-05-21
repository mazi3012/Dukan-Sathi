import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dukan_sathi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Products Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        description TEXT,
        is_service INTEGER NOT NULL DEFAULT 0,
        gst_rate REAL NOT NULL DEFAULT 0.0,
        hsn_sac_code TEXT,
        cost_price REAL NOT NULL DEFAULT 0.0,
        metadata TEXT NOT NULL DEFAULT '{}'
      )
    ''');

    // 2. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        current_balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // 3. Sales Table (Full compliance schema matching Postgres sales table)
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        invoice_number TEXT,
        shop_id TEXT NOT NULL,
        invoice_id TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        customer_state TEXT,
        amount REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0.0,
        due_amount REAL NOT NULL DEFAULT 0.0,
        payment_status TEXT NOT NULL,
        discount_type TEXT,
        discount_value REAL,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        subtotal_before_discount REAL,
        subtotal_after_discount REAL,
        timestamp TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'pending',
        status TEXT NOT NULL DEFAULT 'approved',
        updated_at TEXT
      )
    ''');

    // 4. Sync Queue Table for offline updates background synchronization
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        action TEXT NOT NULL,
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Helper CRUD methods
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(
      table,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAll(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      row,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<void> executeInTransaction(Future<void> Function(Transaction txn) action) async {
    final db = await database;
    await db.transaction((txn) async {
      await action(txn);
    });
  }

  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
}

