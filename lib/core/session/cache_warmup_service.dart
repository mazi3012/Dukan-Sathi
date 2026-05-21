import 'package:flutter/foundation.dart';
import 'package:dukansathi_new/data/repositories/product_repository.dart';
import 'package:dukansathi_new/data/repositories/customer_repository.dart';
import 'package:dukansathi_new/data/repositories/sale_repository.dart';

class CacheWarmupService {
  void triggerWarmup(String shopId) {
    Future.microtask(() async {
      try {
        debugPrint('[CacheWarmup] Warming up caches for shop $shopId...');
        await Future.wait([
          ProductRepository().syncProductsFromCloud(shopId),
          CustomerRepository().syncCustomersFromCloud(shopId),
          SaleRepository().syncSalesFromCloud(shopId),
        ]);
        debugPrint('[CacheWarmup] Caches warmed successfully!');
      } catch (e) {
        debugPrint('[CacheWarmup] Warmup failed: $e');
      }
    });
  }
}
