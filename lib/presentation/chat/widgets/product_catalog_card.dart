import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';

class ProductCatalogCard extends StatelessWidget {
  final Map<String, dynamic> payload;

  const ProductCatalogCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = payload['items'] as List<dynamic>? ?? [];
    final String message = payload['message'] as String? ?? 'Available Products';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBox(
      borderRadius: 16.0,
      opacity: isDark ? 0.12 : 0.85,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Iconsax.box5,
                    color: AppColors.success,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRODUCT CATALOG',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0, thickness: 1.0, color: Colors.white24),

            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'No products found in the catalog.',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length > 5 ? 5 : items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final prod = Map<String, dynamic>.from(items[index] as Map);
                  final name = prod['name'] as String? ?? 'Unnamed Product';
                  final price = (prod['price'] as num?)?.toDouble() ?? 0.0;
                  final stock = (prod['stock_quantity'] as num?)?.toInt() ?? 0;
                  final category = prod['category'] as String? ?? 'General';

                  final isLowStock = stock <= 5;

                  return Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4.0),
                              Row(
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      color: isDark ? Colors.white38 : Colors.black45,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: (isLowStock ? AppColors.error : AppColors.success).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      isLowStock ? 'Low Stock: $stock' : 'Stock: $stock',
                                      style: TextStyle(
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.bold,
                                        color: isLowStock ? AppColors.error : AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.lightOnSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            if (items.length > 5) ...[
              const SizedBox(height: 10.0),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '+ ${items.length - 5} more products',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ),
            ],
          ],
        ),
      ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0.0),
    );
  }
}
