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

  Future<void> _updateCustomerDue(String? customerId, double dueDelta) async {
    if (customerId == null || customerId.isEmpty || customerId == 'null' || dueDelta == 0.0) {
      return;
    }

    if (kIsWeb) {
      try {
        final res = await supabase
            .from('customers')
            .select('current_balance')
            .eq('id', customerId)
            .maybeSingle();
        if (res != null) {
          final double currentBalance = (res['current_balance'] as num?)?.toDouble() ?? 0.0;
          final newBalance = (currentBalance + dueDelta) < 0.0 ? 0.0 : (currentBalance + dueDelta);
          await supabase
              .from('customers')
              .update({'current_balance': newBalance})
              .eq('id', customerId);
        }
      } catch (e) {
        debugPrint("[SaleRepository] Error updating customer balance on web: $e");
      }
    } else {
      try {
        final customers = await _localDb.queryAll(
          'customers',
          where: 'id = ?',
          whereArgs: [customerId],
        );
        if (customers.isNotEmpty) {
          final double currentBalance = (customers.first['current_balance'] as num?)?.toDouble() ?? 0.0;
          final newBalance = (currentBalance + dueDelta) < 0.0 ? 0.0 : (currentBalance + dueDelta);
          
          await _localDb.update(
            'customers',
            {'current_balance': newBalance},
            where: 'id = ?',
            whereArgs: [customerId],
          );
          
          final updatedCustomerMap = Map<String, dynamic>.from(customers.first);
          updatedCustomerMap['current_balance'] = newBalance;
          
          await _syncManager.queueOperation(
            tableName: 'customers',
            action: 'UPDATE',
            recordId: customerId,
            payload: updatedCustomerMap,
          );
        }
      } catch (e) {
        debugPrint("[SaleRepository] Error updating customer balance locally: $e");
      }
    }
  }

  /// Saves sales record locally and queues background sync.
  /// On web, writes directly to Supabase to avoid AI stale-data issues.
  Future<void> saveSale(Map<String, dynamic> sale) async {
    // 1. Update customer balance (Add due_amount)
    final customerId = sale['customer_id']?.toString();
    final double dueAmount = (sale['due_amount'] as num?)?.toDouble() ?? 0.0;
    if (dueAmount > 0.0) {
      await _updateCustomerDue(customerId, dueAmount);
    }

    // Web fast-path: skip local queue, write directly to Supabase
    if (kIsWeb) {
      await supabase.from('sales').upsert(sale);
      return;
    }

    // 2. Save locally
    await _localDb.insert('sales', sale);

    // 3. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'sales',
      action: 'INSERT',
      recordId: sale['id'] as String,
      payload: sale,
    );
  }

  /// Instantly deletes a sale locally and queues background sync.
  /// On web, deletes directly from Supabase to avoid AI stale-data issues.
  Future<void> deleteSale(String id) async {
    // 1. Fetch sale to deduct due_amount from customer
    Map<String, dynamic>? sale;
    if (kIsWeb) {
      try {
        final res = await supabase.from('sales').select('customer_id, due_amount').eq('id', id).maybeSingle();
        if (res != null) {
          sale = Map<String, dynamic>.from(res as Map);
        }
      } catch (e) {
        debugPrint("Error fetching sale before delete on web: $e");
      }
    } else {
      try {
        final sales = await _localDb.queryAll('sales', where: 'id = ?', whereArgs: [id]);
        if (sales.isNotEmpty) {
          sale = sales.first;
        }
      } catch (e) {
        debugPrint("Error fetching sale before delete locally: $e");
      }
    }

    if (sale != null) {
      final customerId = sale['customer_id']?.toString();
      final double dueAmount = (sale['due_amount'] as num?)?.toDouble() ?? 0.0;
      if (dueAmount > 0.0) {
        await _updateCustomerDue(customerId, -dueAmount);
      }
    }

    // Web fast-path: skip local queue, delete directly from Supabase
    if (kIsWeb) {
      await supabase.from('sales').delete().eq('id', id);
      return;
    }

    // 2. Delete locally
    await _localDb.delete(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );

    // 3. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'sales',
      action: 'DELETE',
      recordId: id,
      payload: {},
    );
  }
}
