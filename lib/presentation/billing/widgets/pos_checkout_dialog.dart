import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/barcode_scanner_dialog.dart';
import '../../../models/cart_item.dart';
import '../../../models/product.dart';
import '../../../models/customer.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../core/session.dart';
import '../providers/pos_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../../services/invoice_pdf_generator.dart';
import '../pages/invoice_pdf_preview_screen.dart';
import '../../../models/draft_approval.dart';

class POSCheckoutDialog extends ConsumerStatefulWidget {
  const POSCheckoutDialog({super.key});

  @override
  ConsumerState<POSCheckoutDialog> createState() => _POSCheckoutDialogState();
}

class _POSCheckoutDialogState extends ConsumerState<POSCheckoutDialog> {
  final ProductRepository _productRepo = ProductRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoadingProducts = false;
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
    Future.microtask(() {
      ref.read(customersProvider.notifier).fetchCustomers();
    });
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoadingProducts = true);
    final shopId = UserSession().shopId ?? '';
    try {
      final products = await _productRepo.getProducts(shopId);
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoadingProducts = false;
      });
    } catch (_) {
      setState(() => _isLoadingProducts = false);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || 
                          (p.barcode != null && p.barcode!.contains(query)))
            .toList();
      }
    });
  }

  void _openBarcodeScanner(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => BarcodeScannerDialog(
        onProductScanned: (product) {
          final cartItem = CartItem(
            productId: product.id,
            productName: product.name,
            quantity: 1,
            unitPrice: product.price,
            gstRate: product.gstRate,
          );
          ref.read(posProvider.notifier).addItem(cartItem);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Added ${product.name} via barcode search!"),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Future<void> _finalizeAndPrint(POSInvoiceState invoice) async {
    if (invoice.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot finalize an empty cart."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isFinalizing = true);

    final success = await ref.read(posProvider.notifier).finalizeInvoice();

    if (mounted) {
      setState(() => _isFinalizing = false);
      if (success) {
        final updatedState = ref.read(posProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Invoice Completed and Saved Locally!"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Close POS dialog

        // Automatically launch Invoice PDF offline preview
        _generatePOSPdfPreview(updatedState);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error saving POS invoice locally."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _generatePOSPOSPdfPreview(POSInvoiceState invoice) async {
    // Standard mock helper
  }

  Future<void> _generatePOSPdfPreview(POSInvoiceState invoice) async {
    try {
      final session = UserSession();
      final shopConfig = session.shopConfig;

      final draftApproval = DraftApproval.fromJson({
        'approval_id': invoice.approvalId,
        'shop_id': session.shopId ?? '',
        'customer_id': invoice.customerId,
        'customer_name': invoice.customerName,
        'customer_state': invoice.customerState,
        'proposed_items': invoice.items.map((i) => i.toJson()).toList(),
        'proposed_tax_breakdown': invoice.taxBreakdown,
        'proposed_total': invoice.totalAmount,
        'subtotal_before_discount': invoice.subtotalBeforeDiscount,
        'subtotal_after_discount': invoice.subtotalAfterDiscount,
        'discount_type': invoice.discountType,
        'discount_value': invoice.discountValue,
        'discount_amount': invoice.discountAmount,
        'amount_paid': invoice.amountPaid,
        'payment_status': invoice.paymentStatus,
        'due_amount': invoice.dueAmount,
        'approval_status': 'APPROVED',
        'reviewed_by': session.userId ?? 'merchant',
        'reviewed_at': DateTime.now().toIso8601String(),
      });

      final productDetails = <String, Map<String, dynamic>>{};
      for (final item in invoice.items) {
        productDetails[item.productId] = {
          'name': item.productName,
          'hsn_sac_code': '-',
          'gst_rate': item.gstRate,
        };
      }

      final generatedPdf = await InvoicePdfGenerator.generateApprovedInvoicePdfOffline(
        approval: draftApproval,
        invoiceNumber: invoice.invoiceNumber ?? 'INV-POS-DRAFT',
        shopName: (session.shopName != null && session.shopName!.isNotEmpty) ? session.shopName! : 'Dukan Sathi',
        shopState: shopConfig.state,
        gstNumber: shopConfig.gstRegistrationNumber,
        businessType: shopConfig.businessType,
        customerName: invoice.customerName,
        customerPhone: null,
        productDetails: productDetails,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoicePdfPreviewScreen(
              pdfBytes: generatedPdf.bytes,
              invoiceNumber: invoice.invoiceNumber ?? 'INV-POS',
              caption: generatedPdf.caption,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("POS PDF error: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = ref.watch(posProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 720),
        child: GlassBox(
          borderRadius: 24,
          child: Row(
            children: [
              // Left Section: Products Search & Catalog
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Iconsax.search_normal_1, color: Colors.white54, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      onChanged: _filterProducts,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Search products by name or barcode...",
                                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Iconsax.scan, color: AppColors.primary, size: 28),
                            onPressed: () => _openBarcodeScanner(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Product Catalog",
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          TextButton.icon(
                            icon: const Icon(Iconsax.add_circle, size: 16, color: AppColors.primary),
                            label: const Text("Add Custom Item", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _showAddCustomItemDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Products Grid/List
                      Expanded(
                        child: _isLoadingProducts
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredProducts.isEmpty
                                ? const Center(child: Text("No items match search filter.", style: TextStyle(color: Colors.white38)))
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 2.2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = _filteredProducts[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            ref.read(posProvider.notifier).addItem(
                                              CartItem(
                                                productId: product.id,
                                                productName: product.name,
                                                quantity: 1,
                                                unitPrice: product.price,
                                                gstRate: product.gstRate,
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  product.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      "₹${product.price.toStringAsFixed(2)}",
                                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.05),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        "${product.stockQuantity} Left",
                                                        style: TextStyle(
                                                          color: product.stockQuantity <= 5 ? Colors.redAccent : Colors.white70,
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
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Divider
              Container(width: 1, color: isDark ? Colors.white12 : Colors.black12),

              // Right Section: Cart and Checkout
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "POS Cart",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          TextButton(
                            onPressed: () => ref.read(posProvider.notifier).reset(),
                            child: const Text("Clear All", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Customer Selection Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.user, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.customerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    invoice.customerId == null ? "Walk-in" : "Dukan Customer",
                                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Iconsax.edit, size: 12, color: AppColors.primary),
                              label: const Text("Change", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: _showCustomerSelectionDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cart Items list
                      Expanded(
                        child: invoice.items.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.shopping_cart, color: Colors.white24, size: 40),
                                    SizedBox(height: 12),
                                    Text("POS Cart is empty.", style: TextStyle(color: Colors.white38, fontSize: 13)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: invoice.items.length,
                                itemBuilder: (context, index) {
                                  final item = invoice.items[index];
                                  return InkWell(
                                    onTap: () => _showEditCartItemDialog(item),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName ?? 'Product',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "₹${item.unitPrice.toStringAsFixed(2)} each",
                                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Quantity adjusts
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, color: Colors.white70, size: 16),
                                              onPressed: () {
                                                ref.read(posProvider.notifier).updateItemQuantity(
                                                  item.productId,
                                                  item.quantity - 1,
                                                );
                                              },
                                            ),
                                            Text(
                                              "${item.quantity}",
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add, color: Colors.white70, size: 16),
                                              onPressed: () {
                                                ref.read(posProvider.notifier).updateItemQuantity(
                                                  item.productId,
                                                  item.quantity + 1,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ));
                                },
                              ),
                      ),
                      const Divider(color: Colors.white10, height: 24),

                      // GST Type & Tax Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("GST Option:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Row(
                            children: [
                              _buildGstTab(ref, "Intra (CGST+SGST)", invoice.gstType == 'CGST_SGST', 'CGST_SGST'),
                              const SizedBox(width: 8),
                              _buildGstTab(ref, "Inter (IGST)", invoice.gstType == 'IGST', 'IGST'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Discount Option
                      Row(
                        children: [
                          const Text("Discount:  ", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Expanded(
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: TextField(
                                controller: _discountController,
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "e.g. 10% or 50",
                                  hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                                ),
                                onSubmitted: (val) {
                                  final isPercent = val.contains('%');
                                  final value = double.tryParse(val.replaceAll('%', '').trim()) ?? 0;
                                  ref.read(posProvider.notifier).updateDiscount(
                                    isPercent ? 'PERCENT' : 'AMOUNT',
                                    value,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bill Totals
                      _buildSummaryRow("Subtotal", "₹${invoice.subtotalBeforeDiscount.toStringAsFixed(2)}"),
                      if (invoice.discountAmount > 0)
                        _buildSummaryRow("Discount", "-₹${invoice.discountAmount.toStringAsFixed(2)}", color: AppColors.success),
                      _buildSummaryRow("CGST + SGST (Tax)", "₹${(invoice.totalAmount - invoice.subtotalAfterDiscount).toStringAsFixed(2)}"),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            "₹${invoice.totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Checkout button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isFinalizing ? null : () => _finalizeAndPrint(invoice),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isFinalizing
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                              : const Text("Approve & Print Invoice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGstTab(WidgetRef ref, String label, bool active, String value) {
    return InkWell(
      onTap: () => ref.read(posProvider.notifier).updateGSTType(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? AppColors.primary : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : Colors.white60,
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: TextStyle(color: color ?? Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
    );
  }

  void _showCustomerSelectionDialog() {
    final customersState = ref.read(customersProvider);
    final customersList = customersState.customers;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String searchQuery = '';
    bool isCreating = false;
    final newNameController = TextEditingController();
    final newPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filtered = customersList.where((c) {
            final name = c['name']?.toString().toLowerCase() ?? '';
            final phone = c['phone']?.toString() ?? '';
            return name.contains(searchQuery.toLowerCase()) || phone.contains(searchQuery);
          }).toList();

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCreating ? "New Customer" : "Select Customer",
                  style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCreating) ...[
                      // Search field
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.search_normal, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface, fontSize: 13),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Search by name or phone...",
                                  hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    searchQuery = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Walk-in Option
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                          child: const Icon(Iconsax.user, color: Colors.white70, size: 16),
                        ),
                        title: const Text("Walk-in Customer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: const Text("Default customer profile", style: TextStyle(color: Colors.white30, fontSize: 10)),
                        onTap: () {
                          ref.read(posProvider.notifier).setCustomer(null, 'Walk-in Customer', UserSession().shopConfig.state);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(color: Colors.white10),
                      // Customers List
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("No customers match search.", style: TextStyle(color: Colors.white38, fontSize: 12)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final c = filtered[idx];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Iconsax.user, color: AppColors.primary, size: 16),
                              ),
                              title: Text(c['name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(c['phone'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              onTap: () {
                                ref.read(posProvider.notifier).setCustomer(c['id'], c['name'], c['state'] ?? UserSession().shopConfig.state);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      const Divider(color: Colors.white10),
                      // Quick create trigger
                      TextButton.icon(
                        icon: const Icon(Iconsax.user_add, size: 16, color: AppColors.primary),
                        label: const Text("Quick Register New Customer", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() {
                            isCreating = true;
                          });
                        },
                      ),
                    ] else ...[
                      // Create fields
                      TextField(
                        controller: newNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: "Enter customer name",
                          hintStyle: TextStyle(color: Colors.white30),
                          labelText: "Name *",
                          labelStyle: TextStyle(color: AppColors.primary),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: newPhoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: "Enter phone number",
                          hintStyle: TextStyle(color: Colors.white30),
                          labelText: "Phone Number *",
                          labelStyle: TextStyle(color: AppColors.primary),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isCreating = false;
                              });
                            },
                            child: const Text("Back", style: TextStyle(color: Colors.white54)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final name = newNameController.text.trim();
                              final phone = newPhoneController.text.trim();
                              if (name.isEmpty || phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Name and phone are required"), backgroundColor: AppColors.warning),
                                );
                                return;
                              }

                              final shopId = UserSession().shopId ?? '';
                              final newId = const Uuid().v4();
                              final c = Customer(
                                id: newId,
                                shopId: shopId,
                                name: name,
                                phone: phone,
                                currentBalance: 0.0,
                              );
                              
                              await CustomerRepository().saveCustomer(c);
                              await ref.read(customersProvider.notifier).fetchCustomers();

                              ref.read(posProvider.notifier).setCustomer(newId, name, UserSession().shopConfig.state);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text("Save & Select", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomItemDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    double selectedGst = 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add Custom Item",
                style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "Enter custom service or item name",
                      labelText: "Item Name *",
                      labelStyle: TextStyle(color: AppColors.primary),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "0.00",
                            labelText: "Price *",
                            labelStyle: TextStyle(color: AppColors.primary),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "1",
                            labelText: "Quantity *",
                            labelStyle: TextStyle(color: AppColors.primary),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("GST Rate *", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: selectedGst,
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                            isExpanded: true,
                            items: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                              return DropdownMenuItem<double>(
                                value: rate,
                                child: Text("${rate.toStringAsFixed(0)}%"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedGst = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final price = double.tryParse(priceController.text.trim()) ?? -1;
                        final qty = int.tryParse(qtyController.text.trim()) ?? -1;

                        if (name.isEmpty || price < 0 || qty < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all required fields correctly"), backgroundColor: AppColors.warning),
                          );
                          return;
                        }

                        final customId = 'CUSTOM-${const Uuid().v4()}';
                        final item = CartItem(
                          productId: customId,
                          productName: name,
                          quantity: qty,
                          unitPrice: price,
                          gstRate: selectedGst,
                        );

                        ref.read(posProvider.notifier).addItem(item);
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Added custom item: $name"), backgroundColor: AppColors.success),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text("Add to Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCartItemDialog(CartItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: item.productName);
    final priceController = TextEditingController(text: item.unitPrice.toString());
    final qtyController = TextEditingController(text: item.quantity.toString());
    double selectedGst = item.gstRate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Edit Cart Item",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: "Item Name *",
                      labelStyle: TextStyle(color: AppColors.primary),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: "Price *",
                            labelStyle: TextStyle(color: AppColors.primary),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: "Quantity *",
                            labelStyle: TextStyle(color: AppColors.primary),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("GST Rate *", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: selectedGst,
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                            isExpanded: true,
                            items: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                              return DropdownMenuItem<double>(
                                value: rate,
                                child: Text("${rate.toStringAsFixed(0)}%"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedGst = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(posProvider.notifier).removeItem(item.productId);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Removed ${item.productName} from cart"), backgroundColor: AppColors.error),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final price = double.tryParse(priceController.text.trim()) ?? -1;
                            final qty = int.tryParse(qtyController.text.trim()) ?? -1;

                            if (name.isEmpty || price < 0 || qty < 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please fill all required fields correctly"), backgroundColor: AppColors.warning),
                              );
                              return;
                            }

                            final updated = CartItem(
                              productId: item.productId,
                              productName: name,
                              quantity: qty,
                              unitPrice: price,
                              gstRate: selectedGst,
                            );

                            ref.read(posProvider.notifier).updateCartItem(updated);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
