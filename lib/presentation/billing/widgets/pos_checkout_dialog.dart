import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/barcode_scanner_dialog.dart';
import '../../../models/cart_item.dart';
import '../../../models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../core/session.dart';
import '../providers/pos_provider.dart';
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

                      const Text(
                        "Product Catalog",
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
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
                                  return Container(
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
                                  );
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
}
