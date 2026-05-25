import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../main/pages/main_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/database.dart';
import '../../../core/session.dart';
import 'package:dukansathi_new/data/repositories/sale_repository.dart';
import 'package:dukansathi_new/data/local/local_database.dart';
import '../widgets/pos_checkout_dialog.dart';
import '../../../services/invoice_pdf_generator.dart';
import '../../../models/draft_approval.dart';
import '../../../models/cart_item.dart';
import '../../../models/tax_breakdown.dart';
import 'invoice_pdf_preview_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/sales_provider.dart';



class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  int? _selectedSaleIndex;
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  double _todayRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    Future.microtask(() {
      ref.read(salesProvider.notifier).fetchSales();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreSales();
    }
  }

  final SaleRepository _saleRepo = SaleRepository();
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<void> _fetchSales() async {
    await ref.read(salesProvider.notifier).fetchSales(forceRefresh: true);
  }

  Future<void> _loadMoreSales() async {
    await ref.read(salesProvider.notifier).loadMoreSales();
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

  Future<Map<String, dynamic>> _fetchDraftInvoiceDetails(String invoiceId) async {
    // 1. Check if we are online and fetch from Supabase
    try {
      final res = await supabase
          .from('draft_invoices')
          .select('items, tax_breakdown')
          .eq('id', invoiceId)
          .single();
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      debugPrint("Error fetching draft invoice from supabase: $e");
    }

    // 2. Fall back to local sync queue if offline/error
    try {
      final queueItems = await _localDb.queryAll(
        'sync_queue',
        where: "table_name = 'draft_invoices' AND record_id = ?",
        whereArgs: [invoiceId],
      );
      if (queueItems.isNotEmpty) {
        final payloadStr = queueItems.first['payload'] as String;
        final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
        return {
          'items': payload['items'],
          'tax_breakdown': payload['tax_breakdown'],
        };
      }
    } catch (e) {
      debugPrint("Error reading sync queue: $e");
    }

    return {};
  }

  Future<void> _viewInvoicePdf(Map<String, dynamic> sale, Map<String, dynamic> draftData) async {
    try {
      final session = UserSession();
      final shopConfig = session.shopConfig;
      final invoiceId = sale['invoice_id'] ?? '';
      final invoiceNo = sale['invoice_number'] ?? 'INV-N/A';

      final itemsList = (draftData['items'] ?? []) as List<dynamic>;
      final List<CartItem> cartItems = itemsList.map((itemJson) {
        final json = Map<String, dynamic>.from(itemJson as Map);
        final pId = (json['productId'] ?? json['product_id'] ?? '').toString();
        final finalPId = pId.isNotEmpty ? pId : 'temp-${const Uuid().v4().substring(0, 8)}';
        return CartItem(
          productId: finalPId,
          productName: json['productName']?.toString() ?? json['name']?.toString() ?? 'Item',
          quantity: (json['quantity'] as num?)?.toInt() ?? 1,
          unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
          gstRate: (json['gstRate'] as num?)?.toDouble() ?? 18.0,
        );
      }).toList();

      final taxJson = draftData['tax_breakdown'] ?? {};
      final taxBreakdown = TaxBreakdown.fromJson(Map<String, dynamic>.from(taxJson as Map));

      double originalSubtotal = 0.0;
      for (final item in cartItems) {
        originalSubtotal += item.quantity * item.unitPrice;
      }

      final draftApproval = DraftApproval(
        approvalId: invoiceId,
        shopId: session.shopId ?? '',
        customerId: sale['customer_id']?.toString(),
        customerName: sale['customer_name'] ?? 'Walk-in Customer',
        customerState: sale['customer_state'] ?? shopConfig.state,
        proposedItems: cartItems,
        proposedTaxBreakdown: taxBreakdown,
        proposedTotal: (sale['amount'] as num?)?.toDouble() ?? taxBreakdown.totalAmount,
        subtotalBeforeDiscount: (sale['subtotal_before_discount'] as num?)?.toDouble() ?? originalSubtotal,
        subtotalAfterDiscount: (sale['subtotal_after_discount'] as num?)?.toDouble() ?? taxBreakdown.subtotal,
        discountType: sale['discount_type']?.toString(),
        discountValue: (sale['discount_value'] as num?)?.toDouble(),
        discountAmount: (sale['discount_amount'] as num?)?.toDouble() ?? 0.0,
        amountPaid: (sale['amount_paid'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: (sale['payment_status'] ?? 'PAID').toString(),
        dueAmount: (sale['due_amount'] as num?)?.toDouble() ?? 0.0,
        approvalStatus: ApprovalStatus.approved,
        reviewedBy: session.userId ?? 'merchant',
        reviewedAt: DateTime.tryParse(sale['timestamp'] ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(sale['timestamp'] ?? '') ?? DateTime.now(),
      );

      final productDetails = <String, Map<String, dynamic>>{};
      for (final item in cartItems) {
        productDetails[item.productId] = {
          'name': item.productName,
          'hsn_sac_code': '-',
          'gst_rate': item.gstRate,
        };
      }

      final generatedPdf = await InvoicePdfGenerator.generateApprovedInvoicePdfOffline(
        approval: draftApproval,
        invoiceNumber: invoiceNo,
        shopName: (session.shopName != null && session.shopName!.isNotEmpty) ? session.shopName! : 'Dukan Sathi',
        shopState: shopConfig.state,
        gstNumber: shopConfig.gstRegistrationNumber,
        businessType: shopConfig.businessType,
        customerName: draftApproval.customerName ?? 'Walk-in Customer',
        customerPhone: null,
        productDetails: productDetails,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoicePdfPreviewScreen(
              pdfBytes: generatedPdf.bytes,
              invoiceNumber: invoiceNo,
              caption: generatedPdf.caption,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Failed to generate PDF preview: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to generate PDF: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmDeleteSale(Map<String, dynamic> sale, {required bool isMobileBottomSheet}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invNum = sale['invoice_number'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) {
        bool isConfirmed = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Permanently Delete?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightOnSurface,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You are about to permanently delete Invoice #$invNum. This action will remove this receipt and all its line items from your ledger and database forever.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        isConfirmed = !isConfirmed;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isConfirmed,
                            activeColor: AppColors.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setDialogState(() {
                                isConfirmed = val ?? false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "I confirm I want to permanently delete this invoice.",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
                ElevatedButton(
                  onPressed: isConfirmed
                      ? () async {
                          Navigator.pop(context); // close dialog
                          final id = sale['id'];
                          await ref.read(salesProvider.notifier).deleteSale(id);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Invoice deleted successfully"),
                                backgroundColor: AppColors.success,
                              ),
                            );

                            if (isMobileBottomSheet) {
                              Navigator.pop(context); // close mobile bottom sheet
                            }

                            setState(() {
                              _selectedSaleIndex = null;
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor: isDark 
                        ? Colors.white.withOpacity(0.06) 
                        : Colors.black.withOpacity(0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    "Permanently Delete",
                    style: TextStyle(
                      color: isConfirmed 
                          ? Colors.white 
                          : (isDark ? Colors.white30 : Colors.black38),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);
    final salesState = ref.watch(salesProvider);
    _sales = salesState.sales;
    _isLoading = salesState.isLoading;
    _isLoadingMore = salesState.isLoadingMore;
    _todayRevenue = salesState.todayRevenue;

    // Reactive auto-selection and out-of-bounds safety logic
    if (_sales.isEmpty) {
      _selectedSaleIndex = null;
    } else if (_selectedSaleIndex == null) {
      _selectedSaleIndex = 0;
    } else if (_selectedSaleIndex! >= _sales.length) {
      _selectedSaleIndex = 0;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: isDesktop ? 0 : 90),
        child: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.55),
              builder: (context) => const POSCheckoutDialog(),
            ).then((_) => _fetchSales()); // Refresh sales list when closed!
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Iconsax.add, color: Colors.white),
          label: const Text("New Bill", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ).animate().scale(delay: 500.ms),
      ),
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
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
        ),
        Expanded(
          flex: 60,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
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
          ref.watch(salesProvider).isLoading
              ? SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).iconTheme.color ?? Colors.white),
                      ),
                    ),
                  ),
                )
              : IconButton(
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _sales.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _sales.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }
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
              Row(
                children: [
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: AppColors.error),
                    onPressed: () => _confirmDeleteSale(sale, isMobileBottomSheet: isMobileBottomSheet),
                  ),
                ],
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
          
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchDraftInvoiceDetails(sale['invoice_id'] ?? ''),
            builder: (context, snapshot) {
              List<dynamic> items = [];
              Map<String, dynamic> taxBreakdown = {};

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                items = (snapshot.data!['items'] ?? []) as List<dynamic>;
                taxBreakdown = (snapshot.data!['tax_breakdown'] ?? {}) as Map<String, dynamic>;
              }

              // Fallback if no items found (legacy/mock sales)
              if (items.isEmpty) {
                items = [
                  {
                    'productName': 'General Sale Item',
                    'quantity': 1,
                    'unitPrice': subtotal,
                    'gstRate': 18.0,
                  }
                ];
              }

              final draftData = snapshot.data ?? {
                'items': items,
                'tax_breakdown': taxBreakdown.isNotEmpty ? taxBreakdown : {
                  'total_amount': amount,
                  'subtotal': subtotal,
                  'breakdown': [],
                }
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LINE ITEMS", 
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final item = entry.value;
                    final name = item['productName']?.toString() ?? item['name']?.toString() ?? "Item";
                    final qty = (item['quantity'] as num).toInt();
                    final unitPrice = (item['unitPrice'] as num).toDouble();
                    final gstRate = (item['gstRate'] as num?)?.toDouble() ?? 18.0;
                    final double lineTotal = qty * unitPrice;

                    final breakdown = taxBreakdown['breakdown'] as List<dynamic>?;
                    final useAdjusted = breakdown != null && breakdown.length == items.length;

                    double taxableValue;
                    double taxAmount;
                    double totalWithTax;
                    bool isDiscounted = false;

                    if (useAdjusted) {
                      final br = Map<String, dynamic>.from(breakdown[entry.key] as Map);
                      final cgst = (br['cgst'] as num?)?.toDouble() ?? 0.0;
                      final sgst = (br['sgst'] as num?)?.toDouble() ?? 0.0;
                      final igst = (br['igst'] as num?)?.toDouble() ?? 0.0;

                      taxAmount = cgst + sgst + igst;
                      totalWithTax = (br['totalWithTax'] as num?)?.toDouble() ?? (lineTotal + taxAmount);
                      taxableValue = totalWithTax - taxAmount;
                      if (taxableValue < lineTotal) {
                        isDiscounted = true;
                      }
                    } else {
                      taxableValue = lineTotal;
                      taxAmount = taxableValue * (gstRate / 100);
                      totalWithTax = taxableValue + taxAmount;
                    }

                    final gstRateStr = gstRate == gstRate.roundToDouble() ? '${gstRate.toInt()}%' : '${gstRate.toStringAsFixed(1)}%';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Text(
                                "₹${totalWithTax.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isDiscounted
                                    ? '$qty × ₹${unitPrice.toStringAsFixed(2)} (Taxable: ₹${taxableValue.toStringAsFixed(2)})'
                                    : '$qty × ₹${unitPrice.toStringAsFixed(2)}',
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'GST $gstRateStr (+₹${taxAmount.toStringAsFixed(2)})',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
                          onPressed: () => _viewInvoicePdf(sale, draftData),
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
                          onPressed: () => _viewInvoicePdf(sale, draftData),
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
                  ),
                ],
              );
            },
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
