import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  final Map<String, dynamic> payload;

  const AnalyticsSummaryCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final double revenue = (payload['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final int orders = (payload['total_orders'] as num?)?.toInt() ?? 0;
    final double aov = (payload['average_order_value'] as num?)?.toDouble() ?? 0.0;
    final double? profit = (payload['gross_profit'] as num?)?.toDouble() ?? (payload['gross_profit_estimate'] as num?)?.toDouble();
    final String profitMsg = payload['gross_profit_message'] as String? ?? '';
    final String period = (payload['period'] as String? ?? 'All Time').replaceAll('_', ' ').toUpperCase();

    final int pending = (payload['pending_count'] as num?)?.toInt() ?? 0;
    final double pendingRev = (payload['pending_revenue'] as num?)?.toDouble() ?? 0.0;

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
                    Iconsax.chart_215,
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
                        'BUSINESS INSIGHTS',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        period,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0, thickness: 1.0, color: Colors.white24),
            
            // Grid of Metrics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              children: [
                _buildMetricTile(
                  context: context,
                  label: 'Total Revenue',
                  value: '₹${revenue.toStringAsFixed(0)}',
                  icon: Iconsax.money_send,
                  color: AppColors.success,
                ),
                _buildMetricTile(
                  context: context,
                  label: 'Total Orders',
                  value: orders.toString(),
                  icon: Iconsax.shopping_bag5,
                  color: Colors.blueAccent,
                ),
                _buildMetricTile(
                  context: context,
                  label: 'Avg Order Value',
                  value: '₹${aov.toStringAsFixed(0)}',
                  icon: Iconsax.trend_up,
                  color: Colors.cyan,
                ),
                _buildMetricTile(
                  context: context,
                  label: 'Gross Profit',
                  value: profit != null ? '₹${profit.toStringAsFixed(0)}' : 'N/A',
                  icon: Iconsax.wallet_3,
                  color: Colors.orangeAccent,
                ),
              ],
            ),

            if (pending > 0) ...[
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.info_circle, color: AppColors.warning, size: 18.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Pending Approvals: $pending (₹${pendingRev.toStringAsFixed(0)})',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.lightOnSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (profitMsg.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              Text(
                profitMsg,
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

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16.0),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
