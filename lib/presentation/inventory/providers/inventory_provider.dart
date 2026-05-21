import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../models/product.dart';
import '../../../core/session.dart';

class InventoryState {
  final List<Product> allProducts;
  final List<Product> displayedProducts;
  final double totalValue;
  final List<String> categories;
  final String selectedCategory;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasMore;

  InventoryState({
    required this.allProducts,
    required this.displayedProducts,
    required this.totalValue,
    required this.categories,
    required this.selectedCategory,
    required this.isLoading,
    required this.isLoadingMore,
    required this.currentPage,
    required this.hasMore,
  });

  factory InventoryState.initial() {
    return InventoryState(
      allProducts: [],
      displayedProducts: [],
      totalValue: 0.0,
      categories: ['All', 'Low Stock'],
      selectedCategory: 'All',
      isLoading: true,
      isLoadingMore: false,
      currentPage: 0,
      hasMore: true,
    );
  }

  InventoryState copyWith({
    List<Product>? allProducts,
    List<Product>? displayedProducts,
    double? totalValue,
    List<String>? categories,
    String? selectedCategory,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMore,
  }) {
    return InventoryState(
      allProducts: allProducts ?? this.allProducts,
      displayedProducts: displayedProducts ?? this.displayedProducts,
      totalValue: totalValue ?? this.totalValue,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  final ProductRepository _productRepo = ProductRepository();
  final int _pageSize = 20;

  InventoryNotifier() : super(InventoryState.initial());

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    final shopId = UserSession().shopId;
    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    if (!forceRefresh && state.allProducts.isNotEmpty && !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, currentPage: 0, hasMore: true);

    try {
      final allLocalProducts = await _productRepo.getProducts(shopId, forceRefresh: forceRefresh);
      double value = 0;
      final Set<String> cats = {};

      for (var p in allLocalProducts) {
        value += p.price * p.stockQuantity;
        if (p.category.isNotEmpty) {
          cats.add(p.category);
        }
      }

      state = state.copyWith(
        allProducts: allLocalProducts,
        totalValue: value,
        categories: ['All', 'Low Stock', ...cats],
        isLoading: false,
      );

      _applyFilterAndPagination(resetPage: true);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilterAndPagination(resetPage: true);
  }

  void loadMoreProducts() {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    state = state.copyWith(currentPage: nextPage);
    _applyFilterAndPagination(resetPage: false);
    state = state.copyWith(isLoadingMore: false);
  }

  void _applyFilterAndPagination({required bool resetPage}) {
    final filtered = state.allProducts.where((p) {
      if (state.selectedCategory == 'All') return true;
      if (state.selectedCategory == 'Low Stock') return p.stockQuantity < 10;
      return p.category == state.selectedCategory;
    }).toList();

    final nextOffset = state.currentPage * _pageSize;
    final chunk = filtered.skip(nextOffset).take(_pageSize).toList();

    state = state.copyWith(
      displayedProducts: resetPage ? chunk : [...state.displayedProducts, ...chunk],
      hasMore: filtered.length > nextOffset + chunk.length,
    );
  }

  Future<void> addProduct(Product product) async {
    await _productRepo.saveProduct(product);
    await fetchProducts(forceRefresh: true);
  }

  Future<void> updateProduct(Product product) async {
    await _productRepo.updateProduct(product);
    await fetchProducts(forceRefresh: true);
  }

  Future<void> deleteProduct(String productId) async {
    await _productRepo.deleteProduct(productId);
    await fetchProducts(forceRefresh: true);
  }

  Future<void> adjustStock(String productId, int delta) async {
    await _productRepo.adjustStock(productId, delta);
    await fetchProducts(forceRefresh: true);
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier();
});
