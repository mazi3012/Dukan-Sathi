import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  // In-memory database fallback for Flutter Web
  final Map<String, List<Map<String, dynamic>>> _webDb = {
    'products': [],
    'customers': [],
    'sales': [],
    'sync_queue': [],
  };
  int _webSyncQueueIdCounter = 1;

  LocalDatabase._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Direct SQLite database access is not supported on Web.');
    }
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
    if (kIsWeb) {
      final list = _webDb[table] ??= [];
      final rowCopy = Map<String, dynamic>.from(row);
      
      // Handle auto-increment for sync_queue ID on web
      if (table == 'sync_queue' && !rowCopy.containsKey('id')) {
        rowCopy['id'] = _webSyncQueueIdCounter++;
      }
      
      // If table has primary key, replace any existing item with the same primary key
      String? primaryKeyField;
      if (table == 'products' || table == 'customers' || table == 'sales') {
        primaryKeyField = 'id';
      } else if (table == 'sync_queue') {
        primaryKeyField = 'id';
      }
      
      if (primaryKeyField != null && rowCopy[primaryKeyField] != null) {
        list.removeWhere((item) => item[primaryKeyField] == rowCopy[primaryKeyField]);
      }
      
      list.add(rowCopy);
      return rowCopy['id'] is int ? rowCopy['id'] as int : 1;
    }

    final db = await database;
    return await db.insert(
      table,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  bool _rowMatches(Map<String, dynamic> row, String where, List<dynamic> whereArgs) {
    // Standardize spacing and casing
    final normalized = where.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    if (normalized == 'shop_id = ?' && whereArgs.isNotEmpty) {
      return row['shop_id'] == whereArgs[0];
    }
    
    if (normalized == 'id = ?' && whereArgs.isNotEmpty) {
      return row['id'] == whereArgs[0];
    }
    
    if (normalized == 'shop_id = ? AND stock_quantity < ?' && whereArgs.length >= 2) {
      final shopId = whereArgs[0];
      final minStock = whereArgs[1] as num;
      return row['shop_id'] == shopId && (row['stock_quantity'] as num? ?? 0) < minStock;
    }
    
    if (normalized == 'shop_id = ? AND timestamp >= ?' && whereArgs.length >= 2) {
      final shopId = whereArgs[0];
      final since = whereArgs[1].toString();
      final ts = row['timestamp']?.toString() ?? '';
      return row['shop_id'] == shopId && ts.compareTo(since) >= 0;
    }
    
    if (normalized == 'shop_id = ? AND metadata LIKE ?' && whereArgs.length >= 2) {
      final shopId = whereArgs[0];
      final barcodeQuery = whereArgs[1].toString().replaceAll('%', '').replaceAll('"', '');
      if (row['shop_id'] != shopId) return false;
      final metadata = row['metadata'];
      final metadataStr = metadata is String ? metadata : jsonEncode(metadata ?? {});
      return metadataStr.replaceAll('"', '').contains(barcodeQuery);
    }
    
    // Fallback search
    return true;
  }

  Future<List<Map<String, dynamic>>> queryAll(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (kIsWeb) {
      var list = List<Map<String, dynamic>>.from(_webDb[table] ?? []);
      
      // Simple where clause filtering
      if (where != null && whereArgs != null) {
        list = list.where((item) => _rowMatches(item, where, whereArgs)).toList();
      }
      
      // Simple orderBy
      if (orderBy != null) {
        if (orderBy.contains('timestamp DESC')) {
          list.sort((a, b) {
            final tA = a['timestamp']?.toString() ?? '';
            final tB = b['timestamp']?.toString() ?? '';
            return tB.compareTo(tA);
          });
        } else if (orderBy.contains('name ASC')) {
          list.sort((a, b) {
            final nA = a['name']?.toString() ?? '';
            final nB = b['name']?.toString() ?? '';
            return nA.compareTo(nB);
          });
        } else if (orderBy.contains('id ASC')) {
          list.sort((a, b) {
            final idA = a['id'] is int ? a['id'] as int : 0;
            final idB = b['id'] is int ? b['id'] as int : 0;
            return idA.compareTo(idB);
          });
        }
      }
      
      // Offset and Limit
      int start = offset ?? 0;
      if (start > list.length) return [];
      var result = list.sublist(start);
      if (limit != null && limit < result.length) {
        result = result.sublist(0, limit);
      }
      return result;
    }

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
    if (kIsWeb) {
      final list = _webDb[table] ?? [];
      int count = 0;
      for (var i = 0; i < list.length; i++) {
        if (_rowMatches(list[i], where, whereArgs)) {
          final updated = Map<String, dynamic>.from(list[i])..addAll(row);
          list[i] = updated;
          count++;
        }
      }
      return count;
    }

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
    if (kIsWeb) {
      final list = _webDb[table] ?? [];
      final before = list.length;
      list.removeWhere((item) => _rowMatches(item, where, whereArgs));
      return before - list.length;
    }

    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> clearTable(String table) async {
    if (kIsWeb) {
      _webDb[table]?.clear();
      return;
    }
    final db = await database;
    await db.delete(table);
  }

  Future<void> executeInTransaction(Future<void> Function(Transaction txn) action) async {
    if (kIsWeb) {
      final mockTxn = MockTransaction(this);
      await action(mockTxn);
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      await action(txn);
    });
  }

  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    if (kIsWeb) {
      return;
    }
    final db = await database;
    await db.execute(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    if (kIsWeb) {
      if (sql.contains('UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?') && arguments != null && arguments.length >= 2) {
        final delta = arguments[0] as int;
        final id = arguments[1] as String;
        final list = _webDb['products'] ?? [];
        for (var i = 0; i < list.length; i++) {
          if (list[i]['id'] == id) {
            final updated = Map<String, dynamic>.from(list[i]);
            updated['stock_quantity'] = (updated['stock_quantity'] ?? 0) + delta;
            list[i] = updated;
            return 1;
          }
        }
      }
      return 0;
    }
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
}

// Mock Transaction class for Flutter Web compliance
class MockTransaction implements Transaction {
  final LocalDatabase _localDb;
  MockTransaction(this._localDb);

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    return _localDb.insert(table, values);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return _localDb.delete(table, where: where ?? '', whereArgs: whereArgs ?? []);
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) {
    return _localDb.update(table, values, where: where ?? '', whereArgs: whereArgs ?? []);
  }

  @override
  Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) {
    return _localDb.queryAll(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit, offset: offset);
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) {
    return _localDb.execute(sql, arguments);
  }

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) {
    throw UnimplementedError();
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) {
    throw UnimplementedError();
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) {
    return _localDb.rawUpdate(sql, arguments);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) {
    throw UnimplementedError();
  }

  @override
  Future<QueryCursor> queryCursor(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? bufferSize, int? limit, int? offset}) {
    throw UnimplementedError('queryCursor is not supported on Web.');
  }

  @override
  Future<QueryCursor> rawQueryCursor(String sql, List<Object?>? arguments, {int? bufferSize}) {
    throw UnimplementedError('rawQueryCursor is not supported on Web.');
  }

  @override
  Batch batch() {
    throw UnimplementedError();
  }

  @override
  Database get database => throw UnimplementedError();
}
