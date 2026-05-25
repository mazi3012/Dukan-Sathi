import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../data/local/local_database.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/session.dart';
import '../../../core/database.dart';

class DashboardState {
  final double grossSales;
  final double netRevenue;
  final double gstCollected;
  final int invoiceCountToday;
  final double totalMarketDues;
  final int aiRestockItemsCount;
  final String aiRestockItemName;
  final double expectedRevenueTomorrow;
  final int pendingApprovalsCount;
  final List<Map<String, dynamic>> recentActivity;
  final bool isLoading;
  final bool hasError;

  DashboardState({
    required this.grossSales,
    required this.netRevenue,
    required this.gstCollected,
    required this.invoiceCountToday,
    required this.totalMarketDues,
    required this.aiRestockItemsCount,
    required this.aiRestockItemName,
    required this.expectedRevenueTomorrow,
    required this.pendingApprovalsCount,
    required this.recentActivity,
    required this.isLoading,
    required this.hasError,
  });

  factory DashboardState.initial() {
    return DashboardState(
      grossSales: 0.0,
      netRevenue: 0.0,
      gstCollected: 0.0,
      invoiceCountToday: 0,
      totalMarketDues: 0.0,
      aiRestockItemsCount: 0,
      aiRestockItemName: "All Stock Normal",
      expectedRevenueTomorrow: 0.0,
      pendingApprovalsCount: 0,
      recentActivity: [],
      isLoading: true,
      hasError: false,
    );
  }

  DashboardState copyWith({
    double? grossSales,
    double? netRevenue,
    double? gstCollected,
    int? invoiceCountToday,
    double? totalMarketDues,
    int? aiRestockItemsCount,
    String? aiRestockItemName,
    double? expectedRevenueTomorrow,
    int? pendingApprovalsCount,
    List<Map<String, dynamic>>? recentActivity,
    bool? isLoading,
    bool? hasError,
  }) {
    return DashboardState(
      grossSales: grossSales ?? this.grossSales,
      netRevenue: netRevenue ?? this.netRevenue,
      gstCollected: gstCollected ?? this.gstCollected,
      invoiceCountToday: invoiceCountToday ?? this.invoiceCountToday,
      totalMarketDues: totalMarketDues ?? this.totalMarketDues,
      aiRestockItemsCount: aiRestockItemsCount ?? this.aiRestockItemsCount,
      aiRestockItemName: aiRestockItemName ?? this.aiRestockItemName,
      expectedRevenueTomorrow: expectedRevenueTomorrow ?? this.expectedRevenueTomorrow,
      pendingApprovalsCount: pendingApprovalsCount ?? this.pendingApprovalsCount,
      recentActivity: recentActivity ?? this.recentActivity,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;

  DashboardNotifier() : super(DashboardState.initial());

  Future<void> _updateLocalCustomerDues(String shopId) async {
    // Helper to keep SQLite customer current_balance in-sync with actual sales due_amount
    try {
      final customers = await _localDb.queryAll('customers', where: 'shop_id = ?', whereArgs: [shopId]);
      final sales = await _localDb.queryAll('sales', where: 'shop_id = ?', whereArgs: [shopId]);
      
      final customerDuesMap = <String, double>{};
      for (var sale in sales) {
        final customerId = sale['customer_id']?.toString();
        final dueAmount = (sale['due_amount'] as num?)?.toDouble() ?? 0.0;
        if (customerId != null && customerId.isNotEmpty && customerId != 'null') {
          customerDuesMap[customerId] = (customerDuesMap[customerId] ?? 0.0) + dueAmount;
        }
      }

      for (var customer in customers) {
        final id = customer['id'] as String;
        final expectedDue = customerDuesMap[id] ?? 0.0;
        final currentBal = (customer['current_balance'] as num?)?.toDouble() ?? 0.0;
        if ((currentBal - expectedDue).abs() > 0.01) {
          await _localDb.update('customers', {'current_balance': expectedDue}, where: 'id = ?', whereArgs: [id]);
        }
      }
    } catch (e) {
      debugPrint('[DashboardNotifier] Error syncing local dues: $e');
    }
  }

  Future<void> fetchDashboardData() async {
    final shopId = UserSession().shopId;
    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, hasError: false);

    try {
      // Proactively align any out-of-sync local balances to ensure perfect dashboard stats
      await _updateLocalCustomerDues(shopId);

      // 1. Fetch Total Sales locally
      final salesRes = await _localDb.queryAll(
        'sales',
        where: 'shop_id = ?',
        whereArgs: [shopId],
      );
      
      double netRevenue = 0;
      double grossSales = 0;
      double gstCollected = 0;
      
      int invoiceCountToday = 0;
      double netRevenueToday = 0;
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      for (var row in salesRes) {
        final amount = (row['amount'] as num).toDouble();
        
        // Smart GST fallback for legacy/custom sales
        final double beforeDiscount = (row['subtotal_before_discount'] as num?)?.toDouble() ?? (amount / 1.18);
        final double discountAmount = (row['discount_amount'] as num?)?.toDouble() ?? 0.0;
        final double afterDiscount = (row['subtotal_after_discount'] as num?)?.toDouble() ?? (beforeDiscount - discountAmount);
        
        grossSales += beforeDiscount;
        netRevenue += afterDiscount;
        gstCollected += (amount - afterDiscount);

        // Check if sale belongs to today
        final timestampStr = row['timestamp'] as String?;
        if (timestampStr != null) {
          final timestamp = DateTime.tryParse(timestampStr);
          if (timestamp != null && !timestamp.isBefore(startOfToday)) {
            invoiceCountToday++;
            netRevenueToday += afterDiscount;
          }
        }
      }

      // 3 & 4. Fetch Expenses and Pending Approvals (Online-only parallelized queries)
      double expenses = 0;
      int pendingApprovals = 0;
      if (_connectivity.isOnline) {
        try {
          final results = await Future.wait([
            supabase
                .from('expenses')
                .select('amount')
                .eq('shop_id', shopId),
            supabase
                .from('draft_approvals')
                .select('approval_id')
                .eq('shop_id', shopId)
                .eq('approval_status', 'PENDING'),
          ]);

          final expensesRes = results[0] as List<dynamic>;
          for (var row in expensesRes) {
            expenses += (row['amount'] as num).toDouble();
          }

          final approvalsRes = results[1] as List<dynamic>;
          pendingApprovals = approvalsRes.length;
        } catch (e) {
          debugPrint('[Dashboard] Online parallel query error: $e');
        }
      }

      // 5. Fetch Low Stock Count (< 5 units) locally (excluding services)
      final lowStockRes = await _localDb.queryAll(
        'products',
        where: 'shop_id = ? AND stock_quantity < ? AND is_service = 0',
        whereArgs: [shopId, 5],
      );
      final lowStock = lowStockRes.length;
      final restockItemName = lowStockRes.isNotEmpty ? lowStockRes.first['name'] as String : "All Stock Normal";

      // 6. Fetch Total Market Dues locally
      final duesRes = await _localDb.queryAll(
        'customers',
        where: 'shop_id = ?',
        whereArgs: [shopId],
      );
      
      double dues = 0;
      for (var row in duesRes) {
        dues += (row['current_balance'] as num?)?.toDouble() ?? 0;
      }

      // 7. Fetch Recent Activity locally
      final activityRes = await _localDb.queryAll(
        'sales',
        where: 'shop_id = ?',
        whereArgs: [shopId],
        orderBy: 'timestamp DESC',
        limit: 6,
      );

      final totalMarketDues = dues > 0 ? dues : 0.0;
      final aiRestockItemsCount = lowStock;
      
      // Calculate realistic projections based on today's/daily average performance
      final expectedRevenueTomorrow = netRevenueToday > 0 
          ? netRevenueToday * 1.05 
          : (salesRes.isNotEmpty ? (netRevenue / salesRes.length) * 1.05 : 0.0);
          
      final aiRestockItemName = restockItemName;

      state = state.copyWith(
        grossSales: grossSales,
        netRevenue: netRevenue,
        gstCollected: gstCollected,
        invoiceCountToday: invoiceCountToday,
        totalMarketDues: totalMarketDues,
        aiRestockItemsCount: aiRestockItemsCount,
        expectedRevenueTomorrow: expectedRevenueTomorrow,
        pendingApprovalsCount: pendingApprovals,
        recentActivity: List<Map<String, dynamic>>.from(activityRes),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Dashboard] Fetch error: $e');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
