import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';

class InventoryDraftCard extends StatelessWidget {
  final dynamic payload;
  const InventoryDraftCard({super.key, this.payload});

  @override
  Widget build(BuildContext context) {
    List<dynamic> products = [];
    if (payload is List) {
      products = payload;
    } else if (payload is Map) {
      products = payload['items'] ?? payload['inventory'] ?? [];
    }

    if (products.isEmpty) {
      return const GlassBox(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No products found in inventory.", style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Column(
      children: products.map((product) {
        final name = product['item_name'] ?? product['name'] ?? "Unknown Product";
        final price = product['price_per_unit'] ?? product['price'] ?? 0.0;
        final stock = product['quantity'] ?? product['stock_quantity'] ?? 0;
        final unit = product['unit'] ?? "";
        final category = product['category'] ?? "General";

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassBox(
            blur: 20,
            opacity: 0.1,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.box, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          category,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹$price",
                        style: const TextStyle(
                          color: AppColors.primary,
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
      }).toList(),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
