import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../main/pages/main_layout.dart';
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
          if (_sales.isNotEmpty && _selectedSaleIndex == null) {
            _selectedSaleIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('[Billing] Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMobileInvoiceDetail(BuildContext context, Map<String, dynamic> sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: GlassBox(
                borderRadius: 24,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: _buildInvoiceDetail(sale, isMobileBottomSheet: true),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening AI Invoice Generator...')),
          );
        },
        backgroundColor: AppColors.primary,
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
                  : _buildSalesList(isDesktop: false),
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
                        : _buildSalesList(isDesktop: true),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 60,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 24.0, bottom: 20.0),
            child: GlassBox(
              child: _selectedSaleIndex != null && _selectedSaleIndex! < _sales.length
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildInvoiceDetail(_sales[_selectedSaleIndex!]),
                    )
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
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Iconsax.menu, size: 24),
                  onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                "Sales History",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Text(
                    "Today's Collection", 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "₹${_todayRevenue.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDark ? AppColors.primary : AppColors.lightPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.lightPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.wallet_3, color: isDark ? AppColors.primary : AppColors.lightPrimary),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.2, curve: Curves.easeOut).fadeIn(),
    );
  }

  Widget _buildSalesList({required bool isDesktop}) {
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
        final isSelected = isDesktop && _selectedSaleIndex == index;

        Color statusColor;
        if (paymentStatus == 'PAID') {
          statusColor = AppColors.success;
        } else if (paymentStatus == 'PARTIAL') {
          statusColor = Colors.orange;
        } else {
          statusColor = AppColors.error;
        }

        final cardBorder = isSelected 
            ? Border.all(color: AppColors.primary, width: 1.5)
            : Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.08) : AppColors.lightGlassBorder);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(sale['id'].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
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
              border: cardBorder,
              child: ListTile(
                onTap: () {
                  setState(() {
                    _selectedSaleIndex = index;
                  });
                  if (!isDesktop) {
                    _showMobileInvoiceDetail(context, sale);
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.receipt, color: statusColor, size: 20),
                ),
                title: Text(
                  "Invoice #$invNum",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      customer,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        paymentStatus.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().slideY(begin: 0.1, delay: (index * 40).ms).fadeIn();
      },
    );
  }

  Widget _buildInvoiceDetail(Map<String, dynamic> sale, {bool isMobileBottomSheet = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invNum = sale['invoice_number'] ?? 'N/A';
    final customer = sale['customer_name'] ?? 'Walk-in Customer';
    final amount = (sale['amount'] as num?)?.toDouble() ?? 0;
    final paidAmount = (sale['amount_paid'] as num?)?.toDouble() ?? 0;
    final dueAmount = (sale['due_amount'] as num?)?.toDouble() ?? 0;
    final discountAmount = (sale['discount_amount'] as num?)?.toDouble() ?? 0;
    final subtotal = (sale['subtotal_before_discount'] as num?)?.toDouble() ?? amount;
    final status = sale['payment_status'] ?? 'PAID';
    final timestamp = DateTime.parse(sale['timestamp']);
    final paymentMethod = sale['payment_method'] ?? 'cash';
    final customerState = sale['customer_state'] ?? '';

    Color statusColor = AppColors.success;
    if (status == 'PARTIAL') {
      statusColor = Colors.orange;
    } else if (status == 'UNPAID') {
      statusColor = AppColors.error;
    }

    return Padding(
      padding: EdgeInsets.all(isMobileBottomSheet ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt Header bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "DUKAN SATHI TICKET",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Invoice #$invNum",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMMM dd, yyyy  •  hh:mm a').format(timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 20),
          
          // Customer & Shop details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BILLED TO", 
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      customer,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (customerState.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text("State Code: $customerState", style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PAYMENT METHOD", 
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          paymentMethod == 'cash' 
                              ? Iconsax.wallet_money 
                              : (paymentMethod == 'upi' ? Iconsax.mobile : Iconsax.card),
                          size: 18, 
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          paymentMethod.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Dotted digital receipt container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                _buildReceiptRow("Subtotal", "₹${subtotal.toStringAsFixed(2)}"),
                if (discountAmount > 0) ...[
                  const SizedBox(height: 10),
                  _buildReceiptRow("Discounts", "-₹${discountAmount.toStringAsFixed(2)}", isDiscount: true),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),
                _buildReceiptRow(
                  "Total Amount", 
                  "₹${amount.toStringAsFixed(2)}", 
                  isBold: true,
                  customColor: isDark ? AppColors.primary : AppColors.lightPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Dues structure cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Amount Paid", style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        "₹${paidAmount.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: dueAmount > 0 ? AppColors.error.withOpacity(0.08) : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dueAmount > 0 ? AppColors.error.withOpacity(0.15) : Colors.grey.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dues Remaining", 
                        style: TextStyle(
                          color: dueAmount > 0 ? AppColors.error : Colors.grey, 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${dueAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 18, 
                          color: dueAmount > 0 ? AppColors.error : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          
          // Receipt action tools
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading Receipt PDF...')),
                    );
                  },
                  icon: const Icon(Iconsax.document_download),
                  label: const Text("Download PDF"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sharing Receipt #$invNum...')),
                    );
                  },
                  icon: const Icon(Iconsax.share),
                  label: const Text("Share"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, bool isDiscount = false, Color? customColor}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 16 : 14,
      color: isDiscount 
          ? AppColors.error 
          : (customColor ?? (isBold ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodySmall?.color)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
