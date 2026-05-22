import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';

class PaymentConfirmationCard extends StatelessWidget {
  final Map<String, dynamic> payload;

  const PaymentConfirmationCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final String customerName = payload['customerName'] as String? ?? 'Customer';
    final double amount = (payload['amount'] as num?)?.toDouble() ?? 0.0;
    final String paymentMethod = payload['paymentMethod'] as String? ?? 'cash';
    final double newBalance = (payload['newBalance'] as num?)?.toDouble() ?? 0.0;
    final String message = payload['message'] as String? ?? 'Payment Recorded';
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
                    Iconsax.verify5,
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
                        'PAYMENT RECORDED',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0, thickness: 1.0, color: Colors.white24),

            // Payment metrics row
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount Received',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.lightOnSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30.0,
                    width: 1.0,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          paymentMethod.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),

            // New balance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining Balance:',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                Text(
                  '₹${newBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                    color: newBalance > 0 ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 10.0),
              Text(
                message,
                style: TextStyle(
                  fontSize: 11.0,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ],
        ),
      ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0.0),
    );
  }
}
