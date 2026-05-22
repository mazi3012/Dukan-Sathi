import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';

class CustomerDueDetailCard extends StatelessWidget {
  final Map<String, dynamic> payload;

  const CustomerDueDetailCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final String customerName = payload['customerName'] as String? ?? 'Customer';
    final double balance = (payload['balance'] as num?)?.toDouble() ?? 0.0;
    final List<dynamic> recentUnpaid = payload['recentUnpaid'] as List<dynamic>? ?? [];
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
                CircleAvatar(
                  radius: 18.0,
                  backgroundColor: AppColors.error.withOpacity(0.15),
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Total Dues: ₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0, thickness: 1.0, color: Colors.white24),

            Text(
              'RECENT UNPAID INVOICES',
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 10.0),

            if (recentUnpaid.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'No specific unpaid invoices found.',
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
                itemCount: recentUnpaid.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final sale = Map<String, dynamic>.from(recentUnpaid[index] as Map);
                  final invoiceNumber = sale['invoiceNumber'] as String? ?? 'INV-?';
                  final due = (sale['due'] as num?)?.toDouble() ?? 0.0;
                  final status = sale['paymentStatus'] as String? ?? 'UNPAID';
                  final date = sale['date'] as String? ?? '';

                  return Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoiceNumber,
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '$date • $status',
                              style: TextStyle(
                                fontSize: 11.0,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${due.toStringAsFixed(2)}',
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
          ],
        ),
      ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0.0),
    );
  }
}
