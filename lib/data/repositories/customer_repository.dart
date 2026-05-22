import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database.dart';
import '../../core/services/connectivity_service.dart';
import '../../models/customer.dart';
import '../local/local_database.dart';
import '../sync/sync_manager.dart';

class CustomerRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final SyncManager _syncManager = SyncManager.instance;

  /// Retrieves customers from the local cache. If online, schedules a background cloud sync.
  Future<List<Customer>> getCustomers(
    String shopId, {
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {
    // 1. Instantly return local cached customers
    final localMaps = await _localDb.queryAll(
      'customers',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    
    final localCustomers = localMaps.map((m) => Customer.fromJson(m)).toList();

    // 2. Trigger background sync if online
    if (_connectivity.isOnline && (localCustomers.isEmpty || forceRefresh)) {
      syncCustomersFromCloud(shopId);
    }

    return localCustomers;
  }

  /// Fetches customers from Supabase and populates the local database cache
  Future<void> syncCustomersFromCloud(String shopId) async {
    try {
      final cloudCustomers = await supabase
          .from('customers')
          .select('id, shop_id, name, phone, current_balance')
          .eq('shop_id', shopId);

      await _localDb.executeInTransaction((txn) async {
        for (var c in cloudCustomers) {
          await txn.insert(
            'customers',
            Map<String, dynamic>.from(c),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      debugPrint('[CustomerRepository] Synced ${cloudCustomers.length} customers to local DB.');
    } catch (e) {
      debugPrint('[CustomerRepository] Cloud fetch failed: $e');
    }
  }

  /// Instantly saves a customer locally and queues background sync.
  /// On web, writes directly to Supabase to avoid AI stale-data issues.
  Future<void> saveCustomer(Customer customer) async {
    // Web fast-path: skip local queue, write directly to Supabase
    if (kIsWeb) {
      await supabase.from('customers').upsert(customer.toJson());
      return;
    }

    // 1. Write locally
    await _localDb.insert('customers', customer.toJson());

    // 2. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'customers',
      action: 'INSERT',
      recordId: customer.id,
      payload: customer.toJson(),
    );
  }

  /// Instantly updates a customer locally and queues background sync.
  /// On web, writes directly to Supabase to avoid AI stale-data issues.
  Future<void> updateCustomer(Customer customer) async {
    // Web fast-path: skip local queue, write directly to Supabase
    if (kIsWeb) {
      await supabase.from('customers').upsert(customer.toJson());
      return;
    }

    // 1. Write locally
    await _localDb.update(
      'customers',
      customer.toJson(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );

    // 2. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'customers',
      action: 'UPDATE',
      recordId: customer.id,
      payload: customer.toJson(),
    );
  }

  /// Instantly deletes a customer locally and queues background sync.
  /// On web, deletes directly from Supabase to avoid AI stale-data issues.
  Future<void> deleteCustomer(String id) async {
    // Web fast-path: skip local queue, delete directly from Supabase
    if (kIsWeb) {
      await supabase.from('customers').delete().eq('id', id);
      return;
    }

    // 1. Delete locally
    await _localDb.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    // 2. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'customers',
      action: 'DELETE',
      recordId: id,
      payload: {},
    );
  }
}
