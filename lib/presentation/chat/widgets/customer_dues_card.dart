import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';

class CustomerDuesCard extends StatelessWidget {
  final Map<String, dynamic> payload;

  const CustomerDuesCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final double totalDues = (payload['totalDues'] as num?)?.toDouble() ?? 0.0;
    final List<dynamic> customers = payload['customers'] as List<dynamic>? ?? [];
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
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Iconsax.user_minus,
                    color: AppColors.error,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MARKET CREDIT SUMMARY',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        'Total Outstanding: ₹${totalDues.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0, thickness: 1.0, color: Colors.white24),

            if (customers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    '🎉 Awesome! No outstanding customer dues.',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customers.length > 5 ? 5 : customers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final customer = Map<String, dynamic>.from(customers[index] as Map);
                  final name = customer['name'] as String? ?? 'Unknown';
                  final balance = (customer['balance'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14.0,
                              backgroundColor: AppColors.error.withOpacity(0.2),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            if (customers.length > 5) ...[
              const SizedBox(height: 10.0),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '+ ${customers.length - 5} more customers',
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
