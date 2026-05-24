import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/local/local_database.dart';
import '../../../core/session.dart';
import '../../../models/customer.dart';

class CustomersState {
  final List<Map<String, dynamic>> customers;
  final double outstandingDuesSum;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String filter;
  final String searchQuery;
  final Map<String, dynamic>? selectedCustomer;

  CustomersState({
    required this.customers,
    required this.outstandingDuesSum,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.currentPage,
    required this.filter,
    required this.searchQuery,
    this.selectedCustomer,
  });

  factory CustomersState.initial() {
    return CustomersState(
      customers: [],
      outstandingDuesSum: 0.0,
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      currentPage: 0,
      filter: 'All',
      searchQuery: '',
      selectedCustomer: null,
    );
  }

  CustomersState copyWith({
    List<Map<String, dynamic>>? customers,
    double? outstandingDuesSum,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? filter,
    String? searchQuery,
    Map<String, dynamic>? selectedCustomer,
    bool nullSelectedCustomer = false,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      outstandingDuesSum: outstandingDuesSum ?? this.outstandingDuesSum,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCustomer: nullSelectedCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  final CustomerRepository _customerRepo = CustomerRepository();
  final LocalDatabase _localDb = LocalDatabase.instance;
  final int _pageSize = 20;

  CustomersNotifier() : super(CustomersState.initial());

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCustomer(Map<String, dynamic>? customer) {
    state = state.copyWith(selectedCustomer: customer, nullSelectedCustomer: customer == null);
  }

  Future<void> fetchCustomers() async {
    final shopId = UserSession().shopId;
    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, currentPage: 0, hasMore: true);

    try {
      final res = await _customerRepo.getCustomers(
        shopId,
        limit: _pageSize,
        offset: 0,
      );
      final customersMap = res.map((c) => c.toJson()).toList();

      final duesRes = await _localDb.queryAll(
        'customers',
        where: 'shop_id = ?',
        whereArgs: [shopId],
      );
      double total = 0;
      for (var c in duesRes) {
        total += ((c['current_balance'] as num?)?.toDouble() ?? 0);
      }

      Map<String, dynamic>? updatedSelected;
      if (state.selectedCustomer != null) {
        updatedSelected = customersMap.firstWhere(
          (c) => c['id'] == state.selectedCustomer!['id'],
          orElse: () => state.selectedCustomer!,
        );
      }

      state = state.copyWith(
        customers: customersMap,
        outstandingDuesSum: total,
        isLoading: false,
        hasMore: res.length == _pageSize,
        selectedCustomer: updatedSelected,
      );
    } catch (e) {
      debugPrint('[Customers] Fetch error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMoreCustomers() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final shopId = UserSession().shopId;
    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      final nextOffset = (state.currentPage + 1) * _pageSize;
      final res = await _customerRepo.getCustomers(
        shopId,
        limit: _pageSize,
        offset: nextOffset,
      );
      final customersMap = res.map((c) => c.toJson()).toList();

      state = state.copyWith(
        currentPage: state.currentPage + 1,
        customers: [...state.customers, ...customersMap],
        hasMore: res.length == _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('[Customers] Load more error: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await _customerRepo.saveCustomer(customer);
    await fetchCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _customerRepo.updateCustomer(customer);
    await fetchCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _customerRepo.deleteCustomer(id);
    await fetchCustomers();
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  return CustomersNotifier();
});
