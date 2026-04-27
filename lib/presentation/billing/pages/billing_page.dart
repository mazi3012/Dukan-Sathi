import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/database.dart';
import '../../../core/session.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    final shopId = UserSession().shopId;
    if (shopId == null) return;

    setState(() => _isLoading = true);

    try {
      final res = await supabase
          .from('sales')
          .select()
          .eq('shop_id', shopId)
          .order('timestamp', ascending: false);
      
      if (mounted) {
        setState(() {
          _sales = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Billing] Fetch error: $e');
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
                      : _sales.isEmpty
                          ? _buildEmptyState()
                          : _buildSalesList(),
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
            "Sales History",
            style: Theme.of(context).textTheme.displaySmall,
          ),
          IconButton(
            onPressed: _fetchSales,
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
          const Icon(Iconsax.receipt_item, size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          const Text(
            "No sales recorded yet",
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            "Use Sathi AI in Telegram to create invoices!",
            style: TextStyle(color: AppColors.primary.withOpacity(0.5)),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildSalesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _sales.length,
      itemBuilder: (context, index) {
        final sale = _sales[index];
        final invNum = sale['invoice_number'] ?? 'N/A';
        final customer = sale['customer_name'] ?? 'Walk-in Customer';
        final amount = (sale['amount'] as num?)?.toDouble() ?? 0;
        final timestamp = DateTime.parse(sale['timestamp']);
        final status = sale['status'] ?? 'completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: GlassBox(
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.receipt, color: AppColors.success),
              ),
              title: Text(
                "Invoice #$invNum",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(timestamp),
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${amount.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
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
