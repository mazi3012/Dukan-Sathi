import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../data/local/local_database.dart';
import '../../../core/session.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class SalesState {
  final List<Map<String, dynamic>> sales;
  final double todayRevenue;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;
  final Map<String, dynamic>? selectedSale;

  SalesState({
    required this.sales,
    required this.todayRevenue,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.currentPage,
    required this.searchQuery,
    this.selectedSale,
  });

  factory SalesState.initial() {
    return SalesState(
      sales: [],
      todayRevenue: 0.0,
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      currentPage: 0,
      searchQuery: '',
      selectedSale: null,
    );
  }

  SalesState copyWith({
    List<Map<String, dynamic>>? sales,
    double? todayRevenue,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    Map<String, dynamic>? selectedSale,
    bool nullSelectedSale = false,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSale: nullSelectedSale ? null : (selectedSale ?? this.selectedSale),
    );
  }
}

class SalesNotifier extends StateNotifier<SalesState> {
  final Ref? _ref;
  final SaleRepository _saleRepo = SaleRepository();
  final LocalDatabase _localDb = LocalDatabase.instance;
  final int _pageSize = 20;

  SalesNotifier([this._ref]) : super(SalesState.initial());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectSale(Map<String, dynamic>? sale) {
    state = state.copyWith(selectedSale: sale, nullSelectedSale: sale == null);
  }

  Future<void> fetchSales({bool forceRefresh = false}) async {
    final shopId = UserSession().shopId;
    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, currentPage: 0, hasMore: true);

    try {
      final res = await _saleRepo.getSales(
        shopId,
        forceRefresh: forceRefresh,
        limit: _pageSize,
        offset: 0,
      );

      final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String();
      final todayRes = await _localDb.queryAll(
        'sales',
        where: 'shop_id = ? AND timestamp >= ?',
        whereArgs: [shopId, todayStart],
      );

      double today = 0;
      for (var s in todayRes) {
        today += ((s['amount_paid'] as num?)?.toDouble() ?? 0);
      }

      Map<String, dynamic>? updatedSelected;
      if (state.selectedSale != null) {
        final found = res.where((s) => s['id'] == state.selectedSale!['id']);
        if (found.isNotEmpty) {
          updatedSelected = found.first;
        } else {
          updatedSelected = state.selectedSale;
        }
      }

      state = state.copyWith(
        sales: List<Map<String, dynamic>>.from(res),
        todayRevenue: today,
        isLoading: false,
        hasMore: res.length == _pageSize,
        selectedSale: updatedSelected,
      );
    } catch (e) {
      debugPrint('[SalesNotifier] Fetch error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMoreSales() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final shopId = UserSession().shopId;
    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      final nextOffset = (state.currentPage + 1) * _pageSize;
      final res = await _saleRepo.getSales(
        shopId,
        limit: _pageSize,
        offset: nextOffset,
      );

      state = state.copyWith(
        currentPage: state.currentPage + 1,
        sales: [...state.sales, ...res],
        hasMore: res.length == _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('[SalesNotifier] Load more error: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> deleteSale(String id) async {
    await _saleRepo.deleteSale(id);
    await fetchSales(forceRefresh: true);
    if (_ref != null) {
      _ref!.read(dashboardProvider.notifier).fetchDashboardData();
    }
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  return SalesNotifier(ref);
});
