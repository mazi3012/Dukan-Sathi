import 'package:flutter/foundation.dart';
import '../../core/database.dart';
import '../../core/services/connectivity_service.dart';
import '../../models/product.dart';
import '../local/local_database.dart';
import '../sync/sync_manager.dart';

class ProductRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final SyncManager _syncManager = SyncManager.instance;

  /// Retrieves products from the local database. If online, triggers a background cloud sync.
  Future<List<Product>> getProducts(String shopId, {bool forceRefresh = false}) async {
    // 1. Instantly return local cached products
    final localMaps = await _localDb.queryAll(
      'products',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'name ASC',
    );
    
    final localProducts = localMaps.map((m) {
      // Map integer from SQLite to boolean
      final map = Map<String, dynamic>.from(m);
      map['is_service'] = map['is_service'] == 1;
      return Product.fromJson(map);
    }).toList();

    // 2. Trigger background sync if online
    if (_connectivity.isOnline && (localProducts.isEmpty || forceRefresh)) {
      // Perform background sync to refresh the local cache
      syncProductsFromCloud(shopId);
    }

    return localProducts;
  }

  /// Fetches products from Supabase and populates the local cache
  Future<void> syncProductsFromCloud(String shopId) async {
    try {
      final cloudProducts = await supabase
          .from('products')
          .select('id, shop_id, name, price, stock_quantity, category, description, is_service, gst_rate, hsn_sac_code, cost_price, metadata')
          .eq('shop_id', shopId);

      await _localDb.executeInTransaction((txn) async {
        for (var p in cloudProducts) {
          final mapped = Map<String, dynamic>.from(p);
          mapped['is_service'] = (mapped['is_service'] == true) ? 1 : 0;
          
          await txn.insert(
            'products',
            mapped,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      debugPrint('[ProductRepository] Synced ${cloudProducts.length} products to local DB.');
    } catch (e) {
      debugPrint('[ProductRepository] Cloud fetch failed: $e');
    }
  }

  /// Instantly saves product locally and queues background sync
  Future<void> saveProduct(Product product) async {
    final map = product.toJson();
    map['is_service'] = product.isService ? 1 : 0;

    // 1. Write locally
    await _localDb.insert('products', map);

    // 2. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'products',
      action: 'INSERT',
      recordId: product.id,
      payload: product.toJson(),
    );
  }

  /// Instantly updates product locally and queues background sync
  Future<void> updateProduct(Product product) async {
    final map = product.toJson();
    map['is_service'] = product.isService ? 1 : 0;

    // 1. Write locally
    await _localDb.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );

    // 2. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'products',
      action: 'UPDATE',
      recordId: product.id,
      payload: product.toJson(),
    );
  }

  /// Instantly deletes product locally and queues background sync
  Future<void> deleteProduct(String id) async {
    // 1. Delete locally
    await _localDb.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    // 2. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'products',
      action: 'DELETE',
      recordId: id,
      payload: {},
    );
  }

  /// Relatively adjusts a product's stock levels locally and queues it for background sync
  Future<void> adjustStock(String id, int delta) async {
    // 1. Update SQLite locally first
    await _localDb.rawUpdate(
      'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
      [delta, id],
    );

    // 2. Queue for background sync
    await _syncManager.queueOperation(
      tableName: 'products',
      action: 'ADJUST_STOCK',
      recordId: id,
      payload: {'id': id, 'delta': delta},
    );
  }
}
