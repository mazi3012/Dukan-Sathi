import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final shopId = UserSession().shopId;
    if (shopId == null) return;

    setState(() => _isLoading = true);

    try {
      final res = await supabase
          .from('products')
          .select()
          .eq('shop_id', shopId)
          .order('name');
      
      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(res);
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.darkBackground, Color(0xFF1A1D2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _products.isEmpty
                          ? _buildEmptyState()
                          : _buildProductList(),
                ),
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
            icon: const Icon(Iconsax.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.box, size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          const Text(
            "No products found",
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            "Ask Sathi AI in Telegram to add products!",
            style: TextStyle(color: AppColors.primary.withOpacity(0.5)),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final name = product['name'] ?? 'Unknown';
        final price = (product['price'] as num?)?.toDouble() ?? 0;
        final stock = product['stock_quantity'] ?? 0;
        final category = product['category'] ?? 'General';

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: GlassBox(
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.box, color: AppColors.primary),
              ),
              title: Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                category,
                style: const TextStyle(color: Colors.white54),
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
                    style: TextStyle(
                      color: stock < 10 ? AppColors.error : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().slideY(begin: 0.1, delay: (index * 50).ms).fadeIn();
      },
    );
  }
}
