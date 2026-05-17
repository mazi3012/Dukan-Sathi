import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/database.dart';
import '../../../core/session.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  double _totalValue = 0;
  String _selectedCategory = 'All';
  List<String> _categories = ['All', 'Low Stock'];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    
    final shopId = UserSession().shopId;
    if (shopId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await supabase
          .from('products')
          .select()
          .eq('shop_id', shopId)
          .order('name');
      
      if (mounted) {
        double value = 0;
        Set<String> cats = {};
        for (var p in res) {
          final price = (p['price'] as num?)?.toDouble() ?? 0;
          final stock = (p['stock_quantity'] as int?) ?? 0;
          value += price * stock;
          final cat = p['category'];
          if (cat != null && cat.toString().isNotEmpty) {
            cats.add(cat.toString());
          }
        }

        setState(() {
          _products = List<Map<String, dynamic>>.from(res);
          _totalValue = value;
          _categories = ['All', 'Low Stock', ...cats];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Inventory] Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Inventory",
            style: Theme.of(context).textTheme.displaySmall,
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
                  Text("Total Stock Value", style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  Text(
                    "₹${_totalValue.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.primary.withOpacity(0.2) : AppColors.lightPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.chart_2, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.lightPrimary),
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
            onTap: () => setState(() => _selectedCategory = cat),
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
    final newStock = (product['stock_quantity'] as int? ?? 0) + 10;
    try {
      await supabase.from('products').update({'stock_quantity': newStock}).eq('id', product['id']);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restocked +10 for ${product['name']}', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
      _fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to restock: $e'), backgroundColor: AppColors.error));
    }
  }

  Widget _buildProductList() {
    final filtered = _products.where((p) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Low Stock') return (p['stock_quantity'] as int? ?? 0) < 10;
      return p['category'] == _selectedCategory;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text("No products in '$_selectedCategory'", style: const TextStyle(color: Colors.white54)),
      );
    }
    
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    if (isDesktop || isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 3 : 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 2.5,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildProductCard(filtered[index], index);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: _buildProductCard(filtered[index], index),
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
