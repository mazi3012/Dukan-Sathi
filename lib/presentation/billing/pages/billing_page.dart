import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_layout.dart';
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
  double _todayRevenue = 0;
  int? _selectedSaleIndex;

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _isLoading = true);
    
    final shopId = UserSession().shopId;
    if (shopId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await supabase
          .from('sales')
          .select()
          .eq('shop_id', shopId)
          .order('timestamp', ascending: false);
      
      if (mounted) {
        double today = 0;
        final now = DateTime.now();
        for (var s in res) {
          final tsStr = s['timestamp'] as String?;
          if (tsStr != null) {
            final ts = DateTime.tryParse(tsStr);
            if (ts != null && ts.year == now.year && ts.month == now.month && ts.day == now.day) {
              today += ((s['amount_paid'] as num?)?.toDouble() ?? 0);
            }
          }
        }

        setState(() {
          _sales = List<Map<String, dynamic>>.from(res);
          _todayRevenue = today;
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
          SafeArea(
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(),
              desktop: _buildDesktopLayout(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening AI Invoice Generator...')),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text("New Bill", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildAppBar(),
        _isLoading ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonSummaryCard()) : _buildSalesSummary(),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? _buildListSkeleton()
              : _sales.isEmpty
                  ? _buildEmptyState()
                  : _buildSalesList(),
        ),
        const SizedBox(height: 80), // Padding for bottom bar
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 40,
          child: Column(
            children: [
              _buildAppBar(),
              _isLoading ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonSummaryCard()) : _buildSalesSummary(),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? _buildListSkeleton()
                    : _sales.isEmpty
                        ? _buildEmptyState()
                        : _buildSalesList(),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 60,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 20.0, bottom: 20.0),
            child: GlassBox(
              child: _selectedSaleIndex != null && _selectedSaleIndex! < _sales.length
                  ? _buildInvoiceDetail(_sales[_selectedSaleIndex!])
                  : const EmptyState(
                      title: "Select an Invoice",
                      subtitle: "Choose an invoice from the list to view its details.",
                      icon: Iconsax.document_text,
                    ),
            ),
          ),
        ),
      ],
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
            icon: Icon(Iconsax.refresh, color: Theme.of(context).iconTheme.color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: "No Invoices Yet",
      subtitle: "Once you create bills via AI Chat or Manual entry, they'll appear here.",
      icon: Iconsax.receipt_21,
      actionLabel: "Generate New Bill",
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening AI Invoice Generator...')));
      },
    );
  }

  Widget _buildListSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }

  Widget _buildSalesSummary() {
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
                  Text("Today's Collection", style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  Text(
                    "₹${_todayRevenue.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
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
                child: Icon(Iconsax.wallet_3, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.lightPrimary),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.2, curve: Curves.easeOut).fadeIn(),
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
        final paymentStatus = sale['payment_status'] ?? 'PAID';

        Color statusColor;
        if (paymentStatus == 'PAID') {
          statusColor = AppColors.success;
        } else if (paymentStatus == 'PARTIAL') statusColor = Colors.orange;
        else statusColor = AppColors.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: Dismissible(
            key: Key(sale['id'].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Share PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 10),
                  Icon(Iconsax.message, color: Colors.white),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing Invoice #$invNum via WhatsApp...')),
              );
              return false;
            },
            child: GlassBox(
              child: ListTile(
                onTap: () {
                  setState(() {
                    _selectedSaleIndex = index;
                  });
                },
                contentPadding: const EdgeInsets.all(15),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.receipt, color: statusColor),
                ),
                title: Text(
                  "Invoice #$invNum",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(timestamp),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${amount.toStringAsFixed(0)}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        paymentStatus.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().slideY(begin: 0.1, delay: (index * 50).ms).fadeIn();
      },
    );
  }

  Widget _buildInvoiceDetail(Map<String, dynamic> sale) {
    final invNum = sale['invoice_number'] ?? 'N/A';
    final customer = sale['customer_name'] ?? 'Walk-in Customer';
    final amount = (sale['amount'] as num?)?.toDouble() ?? 0;
    
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Invoice Details", style: Theme.of(context).textTheme.headlineSmall),
              const Icon(Iconsax.receipt_2, size: 30, color: AppColors.primary),
            ],
          ),
          const Divider(height: 40),
          Text("Invoice #$invNum", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Customer: $customer", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount:", style: TextStyle(fontSize: 18)),
              Text("₹${amount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Iconsax.document_download),
                  label: const Text("Download PDF"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Iconsax.share),
                  label: const Text("Share"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
