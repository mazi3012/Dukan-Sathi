import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database.dart';
import '../../core/services/connectivity_service.dart';
import '../local/local_database.dart';
import '../sync/sync_manager.dart';

class SaleRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final SyncManager _syncManager = SyncManager.instance;

  /// Fetch sales from local SQLite first, triggers background cloud sync if online.
  Future<List<Map<String, dynamic>>> getSales(
    String shopId, {
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {
    // 1. Instantly return local cached sales
    final localSales = await _localDb.queryAll(
      'sales',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    // 2. Trigger background sync if online
    if (_connectivity.isOnline && (localSales.isEmpty || forceRefresh)) {
      syncSalesFromCloud(shopId);
    }

    return localSales;
  }

  /// Sync sales from Supabase in the background
  Future<void> syncSalesFromCloud(String shopId) async {
    try {
      // Optimizing with explicit column selects for high speed
      final cloudSales = await supabase
          .from('sales')
          .select('id, invoice_number, shop_id, invoice_id, customer_id, customer_name, customer_state, amount, amount_paid, due_amount, payment_status, discount_type, discount_value, discount_amount, subtotal_before_discount, subtotal_after_discount, timestamp, payment_method, status, updated_at')
          .eq('shop_id', shopId);

      await _localDb.executeInTransaction((txn) async {
        for (var s in cloudSales) {
          await txn.insert(
            'sales',
            Map<String, dynamic>.from(s),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      debugPrint('[SaleRepository] Synced ${cloudSales.length} sales to local DB.');
    } catch (e) {
      debugPrint('[SaleRepository] Cloud fetch failed: $e');
    }
  }

  /// Saves sales record locally and queues background sync.
  /// On web, writes directly to Supabase to avoid AI stale-data issues.
  Future<void> saveSale(Map<String, dynamic> sale) async {
    // Web fast-path: skip local queue, write directly to Supabase
    if (kIsWeb) {
      await supabase.from('sales').upsert(sale);
      return;
    }

    // 1. Save locally
    await _localDb.insert('sales', sale);

    // 2. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'sales',
      action: 'INSERT',
      recordId: sale['id'] as String,
      payload: sale,
    );
  }
}
