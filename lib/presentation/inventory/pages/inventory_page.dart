import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../main/pages/main_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/database.dart';
import '../../../core/session.dart';
import 'package:dukansathi_new/data/repositories/product_repository.dart';
import 'package:dukansathi_new/models/product.dart';



class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _allProductsCached = [];
  bool _isLoading = true;
  double _totalValue = 0;
  String _selectedCategory = 'All';
  List<String> _categories = ['All', 'Low Stock'];

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  final ProductRepository _productRepo = ProductRepository();

  void _applyFilterAndPagination({bool resetPage = false}) {
    if (resetPage) {
      _currentPage = 0;
    }

    final filtered = _allProductsCached.where((p) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Low Stock') return (p['stock_quantity'] as int? ?? 0) < 10;
      return p['category'] == _selectedCategory;
    }).toList();

    final nextOffset = _currentPage * _pageSize;
    final chunk = filtered.skip(nextOffset).take(_pageSize).toList();

    if (mounted) {
      setState(() {
        if (resetPage) {
          _products = chunk;
        } else {
          _products.addAll(chunk);
        }
        _hasMore = filtered.length > nextOffset + chunk.length;
      });
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });
    
    final shopId = UserSession().shopId;
    if (shopId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Offline-first: query total stock valuation & categories from local database
      final allLocalProducts = await _productRepo.getProducts(shopId);
      double value = 0;
      Set<String> cats = {};
      final List<Map<String, dynamic>> cachedList = [];

      for (var p in allLocalProducts) {
        final price = p.price;
        final stock = p.stockQuantity;
        value += price * stock;
        if (p.category.isNotEmpty) {
          cats.add(p.category);
        }
        cachedList.add(p.toJson());
      }

      if (mounted) {
        setState(() {
          _allProductsCached = cachedList;
          _totalValue = value;
          _categories = ['All', 'Low Stock', ...cats];
          _isLoading = false;
        });
        _applyFilterAndPagination(resetPage: true);
      }
    } catch (e) {
      debugPrint('[Inventory] Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      _applyFilterAndPagination(resetPage: false);
      setState(() => _isLoadingMore = false);
    } catch (e) {
      debugPrint('[Inventory] Load more error: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _isLoading ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonSummaryCard()) : _buildValuationCard(),
                if (!_isLoading && _products.isNotEmpty) _buildCategoryFilters(),
                const SizedBox(height: 10),
                Expanded(
                  child: _isLoading
                      ? _buildListSkeleton()
                      : _products.isEmpty
                          ? _buildEmptyState()
                          : _buildProductList(),
                ),
                const SizedBox(height: 80), // padding for bottom bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Iconsax.menu, size: 24),
                  onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                "Inventory",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _fetchProducts,
            icon: Icon(Iconsax.refresh, color: Theme.of(context).iconTheme.color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: "No Products Found",
      subtitle: "Ask Sathi AI in Telegram to add products or sync your inventory.",
      icon: Iconsax.box_search,
      actionLabel: "Refresh Inventory",
      onAction: _fetchProducts,
    );
  }

  Widget _buildListSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }

  Widget _buildValuationCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassBox(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Stock Value", 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "₹${_totalValue.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.lightPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.chart_2, color: isDark ? AppColors.primary : AppColors.lightPrimary),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.2, curve: Curves.easeOut).fadeIn(),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          final isLowStock = cat == 'Low Stock';
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
              _applyFilterAndPagination(resetPage: true);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isLowStock ? AppColors.error : (Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.lightPrimary))
                    : Theme.of(context).cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (isLowStock) ...[
                    const Icon(Iconsax.warning_2, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms);
        },
      ),
    );
  }

  Future<void> _restockProduct(Map<String, dynamic> product) async {
    final productId = product['id'];
    final productName = product['name'] ?? 'Unknown';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    const adjustAmount = 10;

    // Save previous state for rollback
    final previousProducts = List<Map<String, dynamic>>.from(_products.map((p) => Map<String, dynamic>.from(p)));
    final previousAllProducts = List<Map<String, dynamic>>.from(_allProductsCached.map((p) => Map<String, dynamic>.from(p)));
    final previousTotalValue = _totalValue;

    // 1. Optimistic Update (Immediate UI response)
    if (mounted) {
      setState(() {
        _products = _products.map((p) {
          if (p['id'] == productId) {
            final updatedP = Map<String, dynamic>.from(p);
            final currentStock = (updatedP['stock_quantity'] as int? ?? 0);
            updatedP['stock_quantity'] = currentStock + adjustAmount;
            return updatedP;
          }
          return p;
        }).toList();

        _allProductsCached = _allProductsCached.map((p) {
          if (p['id'] == productId) {
            final updatedP = Map<String, dynamic>.from(p);
            final currentStock = (updatedP['stock_quantity'] as int? ?? 0);
            updatedP['stock_quantity'] = currentStock + adjustAmount;
            return updatedP;
          }
          return p;
        }).toList();
        
        _totalValue += price * adjustAmount;
      });
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restocked +10 for $productName', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      // 2. Perform actual background DB/API operation
      await _productRepo.adjustStock(productId, adjustAmount);
      debugPrint('[Inventory] Optimistic restock confirmed for $productName');
    } catch (e) {
      // 3. Rollback on Failure
      debugPrint('[Inventory] Optimistic restock failed: $e. Rolling back...');
      if (mounted) {
        setState(() {
          _products = previousProducts;
          _allProductsCached = previousAllProducts;
          _totalValue = previousTotalValue;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restock $productName. Changes rolled back!'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return Center(
        child: Text("No products in '$_selectedCategory'", style: const TextStyle(color: Colors.white54)),
      );
    }
    
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    if (isDesktop || isTablet) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = isDesktop ? 3 : 2;
          final cardWidth = (width - (crossAxisCount - 1) * 15) / crossAxisCount;
          const double cardHeight = 100.0;
          final double childAspectRatio = cardWidth / cardHeight;

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _products.length + (_isLoadingMore ? crossAxisCount : 0),
            itemBuilder: (context, index) {
              if (index >= _products.length) {
                if (index == _products.length + (crossAxisCount ~/ 2)) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  );
                }
                return const SizedBox.shrink();
              }
              return _buildProductCard(_products[index], index);
            },
          );
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _products.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: _buildProductCard(_products[index], index),
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final name = product['name'] ?? 'Unknown';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final stock = product['stock_quantity'] as int? ?? 0;
    final category = product['category'] ?? 'General';
    final isLowStock = stock < 10;

    return Dismissible(
      key: Key(product['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.primary.withOpacity(0.3) : AppColors.lightPrimary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Restock +10", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Iconsax.add_circle, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await _restockProduct(product);
        return false; // don't remove from list
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isLowStock ? [
            BoxShadow(color: AppColors.error.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
          ] : null,
        ),
        child: GlassBox(
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isLowStock 
                    ? AppColors.error.withOpacity(0.1) 
                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.primary.withOpacity(0.1) : AppColors.lightPrimarySoft),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Iconsax.box, color: isLowStock ? AppColors.error : (Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.lightPrimary)),
            ),
            title: Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              category,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${price.toStringAsFixed(0)}",
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Stock: $stock",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isLowStock ? AppColors.error : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.1, delay: (index * 50).ms).fadeIn();
  }
}
