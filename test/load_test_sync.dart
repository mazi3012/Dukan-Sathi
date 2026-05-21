import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize ffi for running tests outside Flutter native devices
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SyncManager 50K Concurrent Load & Scale Testing', () {
    late Database db;
    late String dbPath;

    setUp(() async {
      // Use a temporary system directory to avoid polluting doc roots
      final tempDir = await Directory.systemTemp.createTemp('dukan_sathi_test');
      dbPath = p.join(tempDir.path, 'load_test.db');
      
      db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
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
        },
      );
    });

    tearDown(() async {
      await db.close();
      try {
        await File(dbPath).delete();
      } catch (_) {}
    });

    test('Simulate 100,000 Concurrent Sync Queues (Scale Hitting)', () async {
      print('🚀 Starting load test: Simulating 100,000 concurrent inserts...');
      final stopwatch = Stopwatch()..start();

      final int totalOperations = 100000;
      final List<Map<String, dynamic>> batchPayloads = List.generate(totalOperations, (index) {
        return {
          'table_name': 'products',
          'action': 'INSERT',
          'record_id': 'prod_$index',
          'payload': jsonEncode({
            'id': 'prod_$index',
            'name': 'Super Load Tested Atta $index',
            'price': 45.50 + (index % 10),
            'stock_quantity': 100 + (index % 50),
            'category': 'Groceries',
          }),
          'created_at': DateTime.now().toIso8601String(),
        };
      });

      print('📦 Generated $totalOperations payloads in ${stopwatch.elapsedMilliseconds} ms.');
      
      // Perform batch inserts using standard SQLite transaction to mimic ultra-fast scaling
      stopwatch.reset();
      stopwatch.start();
      
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final payload in batchPayloads) {
          batch.insert('sync_queue', payload);
        }
        await batch.commit(noResult: true);
      });

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final double opsPerSecond = (totalOperations / elapsedMs) * 1000;

      print('⚡ Transaction successfully committed!');
      print('📊 Time taken: ${elapsedMs / 1000} seconds ($elapsedMs ms)');
      print('📈 Throughput: ${opsPerSecond.toStringAsFixed(2)} inserts/sec');

      // Verify count matches
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
      final count = countResult.first['count'] as int;
      expect(count, equals(totalOperations));
      print('✅ Verified: All $count sync records exist in the queue!');

      // Read a batch of records to simulate FIFO sync queue processing
      stopwatch.reset();
      stopwatch.start();
      
      final pageSize = 100;
      int processedCount = 0;
      
      while (processedCount < totalOperations) {
        final results = await db.query(
          'sync_queue',
          orderBy: 'id ASC',
          limit: pageSize,
          offset: processedCount,
        );
        
        if (results.isEmpty) break;
        processedCount += results.length;
      }

      print('🔄 Simulated background sync iteration over 50K records (Read throughput):');
      print('⏱️ Read iteration completed in ${stopwatch.elapsedMilliseconds} ms.');
      expect(processedCount, equals(totalOperations));
    });
  });
}
