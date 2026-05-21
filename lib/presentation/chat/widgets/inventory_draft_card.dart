import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/session.dart';
import '../../../models/product.dart';
import '../../../data/repositories/product_repository.dart';
class InventoryDraftCard extends StatefulWidget {
  final dynamic payload;
  const InventoryDraftCard({super.key, this.payload});

  @override
  State<InventoryDraftCard> createState() => _InventoryDraftCardState();
}

class _InventoryDraftCardState extends State<InventoryDraftCard> {
  bool _isApproving = false;
  bool _isApproved = false;
  String? _batchId;
  late List<dynamic> _products;

  @override
  void initState() {
    super.initState();
    _parsePayload();
  }

  void _parsePayload() {
    final payload = widget.payload;
    if (payload is List) {
      _products = payload;
      _batchId = null;
    } else if (payload is Map) {
      _products = payload['items'] ?? payload['inventory'] ?? payload['products'] ?? [];
      _batchId = payload['batchId']?.toString() ?? payload['id']?.toString();
      _isApproved = payload['status'] == 'APPROVED';
    } else {
      _products = [];
    }
  }

  @override
  void didUpdateWidget(InventoryDraftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.payload != oldWidget.payload) {
      setState(() {
        _parsePayload();
      });
    }
  }

  Future<void> _approveBatch() async {
    if (_batchId == null || _isApproved) return;

    setState(() => _isApproving = true);
    try {
      final productRepo = ProductRepository();
      
      // Save all products locally via SQLite repository
      for (final pMap in _products) {
        final product = Product.fromJson(Map<String, dynamic>.from(pMap));
        await productRepo.saveProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Products Added to Inventory!"),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _isApproved = true;
        });
      }
    } catch (e) {
      debugPrint("Approve batch error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Approval failed: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return GlassBox(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("No products found.", style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_batchId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Row(
              children: [
                Icon(
                  _isApproved ? Iconsax.tick_circle : Iconsax.add_circle,
                  color: _isApproved ? AppColors.success : Theme.of(context).primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isApproved ? "Added to Inventory" : "New Product Proposal",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ..._products.map((product) {
          final name = product['item_name'] ?? product['name'] ?? "Unknown Product";
          final price = product['price_per_unit'] ?? product['price'] ?? 0.0;
          final stock = product['quantity'] ?? product['stock_quantity'] ?? 0;
          final category = product['category'] ?? "General";

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GlassBox(
              blur: 20,
              opacity: 0.1,
              border: Border.all(
                color: _isApproved 
                    ? AppColors.success.withOpacity(0.3) 
                    : Theme.of(context).dividerColor.withOpacity(0.1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: (_isApproved ? AppColors.success : Theme.of(context).primaryColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.box, 
                        color: _isApproved ? AppColors.success : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            category,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹$price",
                          style: TextStyle(
                            color: _isApproved ? AppColors.success : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: stock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stock > 0 ? "$stock in stock" : "Out of stock",
                            style: TextStyle(
                              color: stock > 0 ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        
        if (_batchId != null && !_isApproved)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isApproving ? null : _approveBatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isApproving
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.add_square, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            "Approve & Add to Inventory", 
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
      ],
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
