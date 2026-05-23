import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/session.dart';
import '../../../core/database.dart';
import '../../../services/invoice_pdf_generator.dart';
import '../../billing/pages/invoice_pdf_preview_screen.dart';
import '../../../models/cart_item.dart';
import '../../../models/draft_approval.dart';
import '../../../models/tax_breakdown.dart';
import '../../../services/gst_calculator.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/sync/sync_manager.dart';
import '../../../models/customer.dart';


class InvoiceDraftCard extends StatefulWidget {
  final Map<String, dynamic>? payload;
  const InvoiceDraftCard({super.key, this.payload});
  @override
  State<InvoiceDraftCard> createState() => _InvoiceDraftCardState();
}


class _InvoiceDraftCardState extends State<InvoiceDraftCard> {
  late Map<String, dynamic> _data;
  bool _isLoading = false;
  bool _isApproving = false;
  bool _showAdvanced = false;
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final FocusNode _paidAmountFocusNode = FocusNode();
  Map<String, dynamic> _normalizePayload(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    try {
      // Deep serialize nested models (e.g. CartItem, TaxBreakdown) to pure Map/List
      return jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error normalizing payload: $e");
      return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    _data = _normalizePayload(widget.payload);
    _discountController.text = (_data['discount_value'] ?? _data['discountValue'] ?? _data['discount']?['discountValue'] ?? 0).toString();
    _paidAmountController.text = (_data['amount_paid'] ?? _data['amountPaid'] ?? _data['payment']?['amountPaid'] ?? 0).toString();
  }
  @override
  void dispose() {
    _discountController.dispose();
    _paidAmountController.dispose();
    _paidAmountFocusNode.dispose();
    super.dispose();
  }
  @override
  void didUpdateWidget(InvoiceDraftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.payload != oldWidget.payload && widget.payload != null) {
      setState(() {
        _data = _normalizePayload(widget.payload);
        _discountController.text = (_data['discount_value'] ?? _data['discountValue'] ?? _data['discount']?['discountValue'] ?? 0).toString();
        _paidAmountController.text = (_data['amount_paid'] ?? _data['amountPaid'] ?? _data['payment']?['amountPaid'] ?? 0).toString();
      });
    }
  }
  String get _approvalId {
    final rawId = (_data['approval_id'] ?? _data['approvalId'] ?? '').toString();
    if (rawId.isEmpty) {
      final generatedId = const Uuid().v4();
      _data['approval_id'] = generatedId;
      return generatedId;
    }
    return rawId;
  }

  TaxBreakdown _getValidTaxBreakdown() {
    final shopConfig = UserSession().shopConfig;
    final itemsList = (_data['proposed_items'] ?? _data['items'] ?? []) as List<dynamic>;
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

    final gstType = _data['gst_type'] ?? _data['gstType'] ?? 'CGST_SGST';
    String customerState = shopConfig.state;
    if (gstType == 'IGST') {
      customerState = shopConfig.state == 'DL' ? 'MH' : 'DL';
    }

    final discAmt = (_data['discount_amount'] ?? _data['discountAmount'] ?? 0.0) as num;
    
    return GSTCalculator.calculateTax(
      items: cartItems,
      shopConfig: shopConfig,
      customerState: customerState,
      invoiceDiscount: discAmt.toDouble(),
    );
  }

  void _recalculateLocalDraft(Map<String, dynamic> updatedData) {
    final shopConfig = UserSession().shopConfig;

    // 1. Parse items into CartItem safely
    final itemsList = (updatedData['proposed_items'] ?? updatedData['items'] ?? []) as List<dynamic>;
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

    // 2. Resolve GST type and customerState
    final gstType = updatedData['gst_type'] ?? updatedData['gstType'] ?? 'CGST_SGST';
    String customerState = shopConfig.state;
    if (gstType == 'IGST') {
      customerState = shopConfig.state == 'DL' ? 'MH' : 'DL'; // force inter-state
    }

    // 3. Resolve discount and apply
    final discountType = updatedData['discount_type'] ?? updatedData['discountType'] ?? 'PERCENT';
    final discountValue = (updatedData['discount_value'] ?? updatedData['discountValue'] ?? 0.0) as num;
    final discountValueDouble = discountValue.toDouble();

    double subtotal = 0.0;
    for (final item in cartItems) {
      subtotal += item.quantity * item.unitPrice;
    }

    double discountAmount = 0.0;
    if (discountType == 'PERCENT') {
      discountAmount = subtotal * (discountValueDouble / 100);
    } else {
      discountAmount = discountValueDouble;
    }
    discountAmount = discountAmount.clamp(0.0, subtotal);

    // 4. Calculate tax
    final taxBreakdown = GSTCalculator.calculateTax(
      items: cartItems,
      shopConfig: shopConfig,
      customerState: customerState,
      invoiceDiscount: discountAmount,
    );

    // 5. Update payment details
    final paymentStatus = updatedData['payment_status'] ?? updatedData['paymentStatus'] ?? 'UNPAID';
    double amountPaid = 0.0;
    if (paymentStatus == 'PAID') {
      amountPaid = taxBreakdown.totalAmount;
    } else if (paymentStatus == 'PARTIAL') {
      final amt = updatedData['amount_paid'] ?? updatedData['amountPaid'] ?? 0.0;
      amountPaid = (amt is num) ? amt.toDouble() : 0.0;
      amountPaid = amountPaid.clamp(0.0, taxBreakdown.totalAmount);
    }

    setState(() {
      _data = {
        ...updatedData,
        'proposed_items': cartItems.map((c) => c.toJson()).toList(),
        'gst_type': gstType,
        'discount_type': discountType,
        'discount_value': discountValueDouble,
        'discount_amount': discountAmount,
        'subtotal_before_discount': taxBreakdown.subtotal,
        'subtotal_after_discount': taxBreakdown.subtotal,
        'proposed_tax_breakdown': taxBreakdown.toJson(),
        'proposed_total': taxBreakdown.totalAmount,
        'payment_status': paymentStatus,
        'amount_paid': amountPaid,
        'due_amount': taxBreakdown.totalAmount - amountPaid,
      };
      
      _discountController.text = discountValueDouble > 0 
          ? (discountType == 'PERCENT' ? '${discountValueDouble.toStringAsFixed(0)}%' : discountValueDouble.toStringAsFixed(2))
          : '';
      _paidAmountController.text = amountPaid > 0 ? amountPaid.toStringAsFixed(2) : '';
    });
  }

  Future<void> _updateDraft(String type, Map<String, dynamic> extra) async {
    final aid = _approvalId;
    if (aid.isEmpty) {
      debugPrint("Warning: approvalId is empty in _data: $_data");
    }
    setState(() => _isLoading = true);

    // Organic delay for premium micro-animations
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final updatedData = Map<String, dynamic>.from(_data);

      if (type == 'edit_item') {
        final productId = extra['productId'] as String;
        final newQty = extra['quantity'] as int;
        final newPrice = extra['unitPrice'] as double?;

        final items = List<dynamic>.from(updatedData['proposed_items'] ?? updatedData['items'] ?? []);
        for (int i = 0; i < items.length; i++) {
          final item = Map<String, dynamic>.from(items[i]);
          if (item['productId'] == productId) {
            item['quantity'] = newQty;
            if (newPrice != null) {
              item['unitPrice'] = newPrice;
            }
            items[i] = item;
            break;
          }
        }
        updatedData['proposed_items'] = items;
      } else if (type == 'gst') {
        updatedData['gst_type'] = extra['gstType'];
      } else if (type == 'payment') {
        updatedData['payment_status'] = extra['paymentStatus'];
        if (extra.containsKey('amountPaid')) {
          updatedData['amount_paid'] = extra['amountPaid'];
        }
      } else if (type == 'discount') {
        updatedData['discount_type'] = extra['discountType'];
        updatedData['discount_value'] = extra['discountValue'];
      }

      _recalculateLocalDraft(updatedData);

      if (type == 'payment' && (updatedData['payment_status'] ?? updatedData['paymentStatus']) == 'PARTIAL' && !extra.containsKey('amountPaid')) {
        _paidAmountFocusNode.requestFocus();
      }

    } catch (e) {
      debugPrint("Error in _updateDraft: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: ${e.toString()}"),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    final qtyCtrl = TextEditingController(text: item['quantity']?.toString());
    final priceCtrl = TextEditingController(text: item['unitPrice']?.toString());
    final name = item['productName']?.toString() ?? item['name']?.toString() ?? "Item";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkBackground,
          title: Text("Edit $name", style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.darkGlassBorder)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Unit Price',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.darkGlassBorder)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final newQty = int.tryParse(qtyCtrl.text.trim());
                final newPrice = double.tryParse(priceCtrl.text.trim());
                if (newQty != null && newQty > 0) {
                  Navigator.pop(context);
                  _updateDraft('edit_item', {
                    'productId': item['productId'],
                    'quantity': newQty,
                    'unitPrice': newPrice,
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateAndOpenPdf(String aid, String invoiceNo) async {
    try {
      final session = UserSession();
      final shopConfig = session.shopConfig;

      final validTax = _getValidTaxBreakdown();

      final itemsList = (_data['proposed_items'] ?? _data['items'] ?? []) as List<dynamic>;
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

      // Construct DraftApproval model locally with the standard constructor
      final draftApproval = DraftApproval(
        approvalId: aid,
        shopId: session.shopId ?? '',
        customerId: (_data['customer_id'] ?? _data['customerId'])?.toString(),
        customerName: _data['customer_name'] ?? _data['customerName'] ?? 'Walk-in Customer',
        customerState: _data['customer_state'] ?? _data['customerState'] ?? shopConfig.state,
        proposedItems: cartItems,
        proposedTaxBreakdown: validTax,
        proposedTotal: (_data['proposed_total'] ?? _data['proposedTotal'] ?? validTax.totalAmount as num).toDouble(),
        subtotalBeforeDiscount: (_data['subtotal_before_discount'] ?? _data['subtotalBeforeDiscount'] ?? validTax.subtotal as num).toDouble(),
        subtotalAfterDiscount: (_data['subtotal_after_discount'] ?? _data['subtotalAfterDiscount'] ?? validTax.subtotal as num).toDouble(),
        discountType: (_data['discount_type'] ?? _data['discountType'])?.toString(),
        discountValue: (_data['discount_value'] ?? _data['discountValue'] as num?)?.toDouble(),
        discountAmount: (_data['discount_amount'] ?? _data['discountAmount'] ?? 0.0 as num).toDouble(),
        amountPaid: (_data['amount_paid'] ?? _data['amountPaid'] ?? 0.0 as num).toDouble(),
        paymentStatus: (_data['payment_status'] ?? _data['paymentStatus'] ?? 'UNPAID').toString(),
        dueAmount: (_data['due_amount'] ?? _data['dueAmount'] ?? (validTax.totalAmount - (_data['amount_paid'] ?? 0.0)) as num).toDouble(),
        approvalStatus: ApprovalStatus.approved,
        reviewedBy: session.userId ?? 'merchant',
        reviewedAt: DateTime.now(),
        createdAt: DateTime.now(),
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
    } catch (pdfError) {
      debugPrint("Failed to automatically generate preview: $pdfError");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invoice approved, but preview generation failed."),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _approveDraft() async {
    final currentPaymentStatus = (_data['payment_status'] ?? _data['paymentStatus'] ?? 'UNPAID').toString();
    final currentAmountPaid = (_data['amount_paid'] ?? _data['amountPaid'] ?? 0.0);
    final amountPaidVal = (currentAmountPaid is num) ? currentAmountPaid.toDouble() : 0.0;

    if (currentPaymentStatus == 'PARTIAL' && amountPaidVal <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter the paid amount before approving a partial payment invoice."),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final aid = _approvalId;
    final String shortId = aid.length > 13 ? aid.substring(0, 13) : aid;
    final invoiceNo = 'INV-${shortId.replaceAll('-', '').toUpperCase()}';
    final customerName = (_data['customer_name'] ?? _data['customerName'])?.toString() ?? "Walk-in Customer";

    // Show the premium step-by-step progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ApprovalProgressDialog(
        invoiceNo: invoiceNo,
        customerName: customerName,
        onFinish: () async {
          // Auto generate and show PDF preview offline!
          await _generateAndOpenPdf(aid, invoiceNo);
        },
      ),
    );

    try {
      final session = UserSession();
      final shopId = session.shopId!;
      final shopConfig = session.shopConfig;
      final saleId = const Uuid().v4();
      final draftInvoiceId = const Uuid().v4();

      final validTax = _getValidTaxBreakdown();

      // Parse items safely
      final itemsList = (_data['proposed_items'] ?? _data['items'] ?? []) as List<dynamic>;
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

      String? customerId = (_data['customer_id'] ?? _data['customerId'])?.toString();
      final customerState = _data['customer_state'] ?? _data['customerState'] ?? shopConfig.state;
      
      // Auto-save new customer if needed
      if (customerId == null && customerName != 'Walk-in Customer' && customerName.trim().isNotEmpty) {
        final normalizedName = customerName.trim();
        String? existingId;
        try {
          final existing = await supabase
              .from('customers')
              .select('id')
              .eq('shop_id', shopId)
              .ilike('name', normalizedName)
              .maybeSingle();
          if (existing != null) {
            existingId = (existing as Map)['id']?.toString();
          }
        } catch (e) {
          debugPrint("Error checking existing customer: $e");
        }

        if (existingId != null && existingId.isNotEmpty) {
          customerId = existingId;
        } else {
          final newCustId = const Uuid().v4();
          final customerRepo = CustomerRepository();
          final generatedPhone = 'AUTO-${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4().substring(0, 6)}';
          await customerRepo.saveCustomer(Customer(
            id: newCustId,
            shopId: shopId,
            name: normalizedName,
            phone: generatedPhone,
            currentBalance: 0.0,
          ));
          customerId = newCustId;
        }
      }

      final proposedTotal = (_data['proposed_total'] ?? _data['proposedTotal'] ?? validTax.totalAmount as num).toDouble();

      final subtotalBeforeDiscount = (_data['subtotal_before_discount'] ?? _data['subtotalBeforeDiscount'] ?? validTax.subtotal as num).toDouble();
      final subtotalAfterDiscount = (_data['subtotal_after_discount'] ?? _data['subtotalAfterDiscount'] ?? validTax.subtotal as num).toDouble();
      final discountType = (_data['discount_type'] ?? _data['discountType'])?.toString();
      final discountValue = (_data['discount_value'] ?? _data['discountValue'] as num?)?.toDouble();
      final discountAmount = (_data['discount_amount'] ?? _data['discountAmount'] ?? 0.0).toDouble();

      final dueAmount = proposedTotal - amountPaidVal;
      
      final syncManager = SyncManager.instance;

      // 1. Insert Draft Invoice record — direct on web, queued on mobile/desktop
      // This is necessary because sales table has a foreign key referencing draft_invoices
      final draftInvoicePayload = {
        'id': draftInvoiceId,
        'shop_id': shopId,
        'customer_id': customerId,
        'customer_name': customerName,
        'items': cartItems.map((c) => c.toJson()).toList(),
        'total_amount': proposedTotal,
        'tax_breakdown': _data['proposed_tax_breakdown'] ?? validTax.toJson(),
        'status': 'approved',
        'draft_approval_id': null, // avoid foreign key violation as there is no draft approval record in supabase
      };
      if (kIsWeb) {
        await supabase.from('draft_invoices').insert(draftInvoicePayload);
      } else {
        await syncManager.queueOperation(
          tableName: 'draft_invoices',
          action: 'INSERT',
          recordId: draftInvoiceId,
          payload: draftInvoicePayload,
        );
      }

      // 2. Save locally to SQFlite sales table
      final saleRepo = SaleRepository();
      final saleMap = {
        'id': saleId,
        'invoice_number': invoiceNo,
        'shop_id': shopId,
        'invoice_id': draftInvoiceId,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_state': customerState,
        'amount': proposedTotal,
        'amount_paid': amountPaidVal,
        'due_amount': dueAmount,
        'payment_status': currentPaymentStatus,
        'discount_type': discountType,
        'discount_value': discountValue,
        'discount_amount': discountAmount,
        'subtotal_before_discount': subtotalBeforeDiscount,
        'subtotal_after_discount': subtotalAfterDiscount,
        'timestamp': DateTime.now().toIso8601String(),
        'payment_method': 'pending',
        'status': 'approved',
      };

      await saleRepo.saveSale(saleMap);

      // 3. Adjust product stock — web-aware (adjustStock handles kIsWeb internally)
      final productRepo = ProductRepository();

      for (final item in cartItems) {
        // adjustStock is web-aware: uses Supabase RPC on web, local queue on mobile
        await productRepo.adjustStock(item.productId, -item.quantity);
      }

      // 4. Update local draft status & invoice details
      setState(() {
        _data['approval_status'] = 'APPROVED';
        _data['invoice_number'] = invoiceNo;
      });

    } catch (e, stack) {
      debugPrint("Approve error: $e\n$stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Approval error: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // Guard: empty or malformed payload
    if (_data.isEmpty) {
      return const _StaticPlaceholder();
    }

    // Guard: missing required items — show diagnostic error instead of blank box
    final itemsRaw = _data['proposed_items'] ?? _data['items'];
    if (itemsRaw == null || (itemsRaw as List).isEmpty) {
      return _ErrorPlaceholder(
        message: 'Draft data is missing item details.\nPayload keys: ${_data.keys.join(', ')}',
      );
    }
    final isApproved = _data['approval_status'] == 'APPROVED';
    final items = (_data['proposed_items'] ?? _data['items']) as List<dynamic>? ?? [];
    final tax = _data['proposed_tax_breakdown'] ?? _data['taxBreakdown'] ?? {};
    final customerName = (_data['customer_name'] ?? _data['customerName'])?.toString() ?? "Walk-in Customer";
    final totalAmount = (tax['total_amount'] ?? tax['totalAmount'] ?? 0.0).toDouble();
    final gstType = _data['gst_type'] ?? _data['gstType'] ?? 'CGST_SGST';
    final paymentStatus = _data['payment_status'] ?? _data['paymentStatus'] ?? 'UNPAID';
    final discAmt = (_data['discount_amount'] ?? _data['discountAmount'] ?? _data['discount']?['discountAmount'] ?? 0.0).toDouble();
    return GlassBox(
      blur: 25,
      opacity: 0.15,
      border: Border.all(
        color: isApproved ? AppColors.success.withOpacity(0.4) : Theme.of(context).primaryColor.withOpacity(0.3),
        width: 1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isApproved ? Iconsax.tick_circle : Iconsax.edit,
                      color: isApproved ? AppColors.success : Theme.of(context).primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isApproved ? "Approved Invoice" : "Draft Invoice",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isApproved ? AppColors.success : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (!isApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      "EDITING",
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
              ],
            ),
            const Divider(color: AppColors.darkGlassBorder, height: 24),
            
            // Item List — Indian GST style with per-item tax detail
            ...items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final name = item['productName']?.toString() ?? item['name']?.toString() ?? "Item";
              final qty = (item['quantity'] as num).toInt();
              final unitPrice = (item['unitPrice'] as num).toDouble();
              final gstRate = (item['gstRate'] as num?)?.toDouble() ?? 18.0;
              final taxableValue = qty * unitPrice;
              final taxAmount = taxableValue * (gstRate / 100);
              final totalWithTax = taxableValue + taxAmount;
              final gstRateStr = gstRate == gstRate.roundToDouble() ? '${gstRate.toInt()}%' : '${gstRate.toStringAsFixed(1)}%';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Name + Edit + Total
                    Row(
                      children: [
                        Container(
                          width: 22, height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$idx', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        if (!isApproved)
                          GestureDetector(
                            onTap: () => _showEditItemDialog(Map<String, dynamic>.from(item)),
                            child: Icon(Iconsax.edit, size: 14, color: Theme.of(context).primaryColor),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Row 2: Qty × Rate = Taxable | GST% | Tax Amt
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$qty × ₹${unitPrice.toStringAsFixed(2)} = ₹${taxableValue.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        if (discAmt == 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('GST $gstRateStr', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+₹${taxAmount.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.amber.shade300, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 12),
                    // Row 3: Total including tax
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Total: ', style: TextStyle(fontSize: 11)),
                        Text(
                          '₹${(discAmt > 0 ? taxableValue : totalWithTax).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 16),
            
            // Tax Breakdown Tray
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading ? Column(
                children: [
                  const AppSkeleton(width: double.infinity, height: 16, margin: EdgeInsets.only(bottom: 8)),
                  const AppSkeleton(width: double.infinity, height: 16, margin: EdgeInsets.only(bottom: 8)),
                  AppSkeleton(width: MediaQuery.of(context).size.width * 0.4, height: 16, margin: const EdgeInsets.only(bottom: 8)),
                ],
              ) : Column(
                children: [
                  // Show Items Total → Discount → Taxable Value when discount is applied
                  if (discAmt > 0) ...[
                    _buildTaxLine("Items Total", "₹${(_data['subtotal_before_discount'] ?? _data['subtotalBeforeDiscount'] ?? tax['subtotal'] ?? 0.0).toStringAsFixed(2)}"),
                    () {
                      final discType = (_data['discount_type'] ?? _data['discountType'])?.toString();
                      final discVal = (_data['discount_value'] ?? _data['discountValue'] ?? 0.0);
                      final discValNum = (discVal is num) ? discVal.toDouble() : 0.0;
                      final label = discType == 'PERCENT' ? "Discount (${discValNum.toStringAsFixed(1)}%)" : "Discount";
                      return _buildTaxLine(label, "-₹${discAmt.toStringAsFixed(2)}", color: AppColors.success);
                    }(),
                    _buildTaxLine("Taxable Value", "₹${(_data['subtotal_after_discount'] ?? _data['subtotalAfterDiscount'] ?? tax['subtotal'] ?? 0.0).toStringAsFixed(2)}"),
                  ] else
                    _buildTaxLine("Subtotal", "₹${(tax['subtotal'] ?? 0.0).toStringAsFixed(2)}"),
                  if (tax['rate_wise_summary'] != null && (tax['rate_wise_summary'] as List).isNotEmpty)
                    ...(tax['rate_wise_summary'] as List).map((entry) {
                      final rate = (entry['rate'] as num).toDouble();
                      if (rate <= 0) return const SizedBox.shrink();
                      final isIGST = gstType == 'IGST';
                      if (isIGST) {
                        final igst = (entry['igst'] as num).toDouble();
                        return _buildTaxLine("IGST (${rate == rate.roundToDouble() ? rate.toInt() : rate.toStringAsFixed(1)}%)", "₹${igst.toStringAsFixed(2)}");
                      } else {
                        final cgst = (entry['cgst'] as num).toDouble();
                        final sgst = (entry['sgst'] as num).toDouble();
                        final halfRate = rate / 2;
                        final halfRateStr = halfRate == halfRate.roundToDouble() ? halfRate.toInt() : halfRate.toStringAsFixed(1);
                        return Column(
                          children: [
                            _buildTaxLine("CGST ($halfRateStr%)", "₹${cgst.toStringAsFixed(2)}"),
                            _buildTaxLine("SGST ($halfRateStr%)", "₹${sgst.toStringAsFixed(2)}"),
                          ],
                        );
                      }
                    })
                  else ...[
                    if ((tax['cgst_amount'] ?? tax['cgstAmount'] ?? 0.0) > 0)
                      _buildTaxLine("CGST", "₹${(tax['cgst_amount'] ?? tax['cgstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                    if ((tax['sgst_amount'] ?? tax['sgstAmount'] ?? 0.0) > 0)
                      _buildTaxLine("SGST", "₹${(tax['sgst_amount'] ?? tax['sgstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                    if ((tax['igst_amount'] ?? tax['igstAmount'] ?? 0.0) > 0)
                      _buildTaxLine("IGST", "₹${(tax['igst_amount'] ?? tax['igstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                  ],
                ],
              ),
            ),
            
            if (!isApproved) ...[
              const SizedBox(height: 24),
              // Advanced Toggle
              _buildSectionLabel("Adjustments & Payment"),
              const SizedBox(height: 12),
              _buildAdvancedControls(gstType, paymentStatus).animate().fadeIn().slideY(begin: 0.05),
            ],
            const SizedBox(height: 24),
            
            // Grand Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Amount",
                        style: TextStyle(
                          fontSize: 14, 
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isApproved ? "Invoice Finalized" : "Draft Calculation",
                        style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                      ),
                    ],
                  ),
                  _isLoading ? const AppSkeleton(width: 120, height: 36, borderRadius: 8) : Text(
                    "₹${totalAmount.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
                ],
              ),
            ),

            // Payment Summary (Paid / Due)
            if (_isLoading) ...[
               const SizedBox(height: 8),
               const AppSkeleton(width: double.infinity, height: 16, margin: EdgeInsets.only(bottom: 4)),
               const AppSkeleton(width: double.infinity, height: 16, margin: EdgeInsets.only(bottom: 4)),
            ] else if (paymentStatus == 'PARTIAL' || paymentStatus == 'UNPAID') ...[
              const SizedBox(height: 8),
              () {
                final amtPaid = (_data['amount_paid'] ?? _data['amountPaid'] ?? 0.0);
                final paidVal = (amtPaid is num) ? amtPaid.toDouble() : 0.0;
                final dueVal = totalAmount - paidVal;
                return Column(
                  children: [
                    if (paymentStatus == 'PARTIAL' && paidVal > 0)
                      _buildTaxLine("Amount Paid", "₹${paidVal.toStringAsFixed(2)}", color: AppColors.success),
                    _buildTaxLine(
                      "Balance Due",
                      "₹${dueVal.toStringAsFixed(2)}",
                      color: AppColors.error,
                    ),
                  ],
                );
              }(),
            ] else if (paymentStatus == 'PAID') ...[
              const SizedBox(height: 8),
              _buildTaxLine("Fully Paid", "₹${totalAmount.toStringAsFixed(2)}", color: AppColors.success),
            ],
            
            const SizedBox(height: 20),
            
            // Action Buttons
            if (!isApproved)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isApproving ? null : _approveDraft,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isApproving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Iconsax.tick_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Approve & Print", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Iconsax.trash, color: AppColors.error),
                    ),
                  ),
                ],
              )
            else
              _buildApprovedActions(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
  Widget _buildAdvancedControls(String currentGst, String paymentStatus) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          // GST Switcher
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("GST Type:", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSmallToggle(
                    "Intra-state (CGST+SGST)",
                    currentGst == 'CGST_SGST',
                    () => _updateDraft('gst', {'gstType': 'CGST_SGST'}),
                  ),
                  _buildSmallToggle(
                    "Inter-state (IGST)",
                    currentGst == 'IGST',
                    () => _updateDraft('gst', {'gstType': 'IGST'}),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Payment Status:", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSmallToggle("Unpaid", paymentStatus == 'UNPAID', () => _updateDraft('payment', {'paymentStatus': 'UNPAID'})),
                  _buildSmallToggle("Partial", paymentStatus == 'PARTIAL', () => _updateDraft('payment', {'paymentStatus': 'PARTIAL'})),
                  _buildSmallToggle("Paid", paymentStatus == 'PAID', () => _updateDraft('payment', {'paymentStatus': 'PAID'})),
                ],
              ),
            ],
          ),
          if (paymentStatus == 'PARTIAL') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text("Amount Paid:", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _paidAmountController,
                    focusNode: _paidAmountFocusNode,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 12),
                    decoration: _inputDecoration("₹ 0.00"),
                    onSubmitted: (val) => _updateDraft('payment', {
                      'paymentStatus': 'PARTIAL',
                      'amountPaid': double.tryParse(val) ?? 0,
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final val = _paidAmountController.text.trim();
                    final amount = double.tryParse(val) ?? 0;
                    if (amount > 0) {
                      _updateDraft('payment', {
                        'paymentStatus': 'PARTIAL',
                        'amountPaid': amount,
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Enter a valid amount greater than 0"),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).primaryColor),
                    ),
                    child: Text("Save", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Discount
          Row(
            children: [
              Text("Discount:", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 12),
                  decoration: _inputDecoration("e.g. 10% or 50"),
                  onSubmitted: (val) {
                    final isPercent = val.contains('%');
                    final value = double.tryParse(val.replaceAll('%', '').trim()) ?? 0;
                    _updateDraft('discount', {
                      'discountType': isPercent ? 'PERCENT' : 'AMOUNT',
                      'discountValue': value,
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final val = _discountController.text.trim();
                  if (val.isEmpty) return;
                  final isPercent = val.contains('%');
                  final value = double.tryParse(val.replaceAll('%', '').trim()) ?? 0;
                  if (value > 0) {
                    _updateDraft('discount', {
                      'discountType': isPercent ? 'PERCENT' : 'AMOUNT',
                      'discountValue': value,
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter a valid discount value (e.g. 10% or 50)"),
                        backgroundColor: AppColors.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).primaryColor),
                  ),
                  child: Text("Apply", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  InputDecoration _inputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 12),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
  Widget _buildSmallToggle(String label, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: active ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: active ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? Theme.of(context).primaryColor : (isDark ? Colors.white10 : Colors.black12)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Theme.of(context).primaryColor : (isDark ? Colors.white54 : Colors.black54),
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLineItem(String name, String qtyPrice, String total, {VoidCallback? onEdit}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                Text(qtyPrice, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          if (onEdit != null) ...[
            Text(total, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEdit,
              child: Icon(Iconsax.edit, size: 16, color: Theme.of(context).primaryColor),
            ),
          ] else
            Text(total, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _buildTaxLine(String label, String amount, {Color? color}) {
    final defaultColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: defaultColor, fontSize: 13)),
          Text(amount, style: TextStyle(color: color ?? Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13)),
        ],
      ),
    );
  }
  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).primaryColor.withOpacity(0.6),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
  Widget _buildApprovedActions() {
    final aid = _approvalId;
    final String shortId = aid.length > 8 ? aid.substring(0, 8) : aid;
    final invoiceNo = _data['invoice_number'] as String? ??
        _data['invoiceNumber'] as String? ??
        'INV-${aid.isNotEmpty ? shortId.toUpperCase() : 'DRAFT'}';
    return Column(
      children: [
        // Primary: View & Print button
        GestureDetector(
          onTap: () async => _generateAndOpenPdf(aid, invoiceNo),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.82)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.document_download, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'View, Print & Share Invoice PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ).animate().shimmer(duration: 1800.ms),
        if (kIsWeb) ...[
          const SizedBox(height: 10),
          // Secondary: Direct browser download on Web
          GestureDetector(
            onTap: () async {
              try {
                final generatedPdf = await _buildPdfForDownload(aid, invoiceNo);
                // savePdfToTemp on web triggers browser download automatically
                await generatedPdf;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📥 PDF download started in your browser!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Download failed: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.import, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Download PDF to Device',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Generates PDF bytes and triggers download (web) or returns file (native).
  Future<dynamic> _buildPdfForDownload(String aid, String invoiceNo) async {
    final session = UserSession();
    final shopConfig = session.shopConfig;

    final validTax = _getValidTaxBreakdown();

    final itemsList = (_data['proposed_items'] ?? _data['items'] ?? []) as List<dynamic>;
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

    // Construct DraftApproval model locally with the standard constructor
    final draftApproval = DraftApproval(
      approvalId: aid,
      shopId: session.shopId ?? '',
      customerId: (_data['customer_id'] ?? _data['customerId'])?.toString(),
      customerName: _data['customer_name'] ?? _data['customerName'] ?? 'Walk-in Customer',
      customerState: _data['customer_state'] ?? _data['customerState'] ?? shopConfig.state,
      proposedItems: cartItems,
      proposedTaxBreakdown: validTax,
      proposedTotal: (_data['proposed_total'] ?? _data['proposedTotal'] ?? validTax.totalAmount as num).toDouble(),
      subtotalBeforeDiscount: (_data['subtotal_before_discount'] ?? _data['subtotalBeforeDiscount'] ?? validTax.subtotal as num).toDouble(),
      subtotalAfterDiscount: (_data['subtotal_after_discount'] ?? _data['subtotalAfterDiscount'] ?? validTax.subtotal as num).toDouble(),
      discountType: (_data['discount_type'] ?? _data['discountType'])?.toString(),
      discountValue: (_data['discount_value'] ?? _data['discountValue'] as num?)?.toDouble(),
      discountAmount: (_data['discount_amount'] ?? _data['discountAmount'] ?? 0.0 as num).toDouble(),
      amountPaid: (_data['amount_paid'] ?? _data['amountPaid'] ?? 0.0 as num).toDouble(),
      paymentStatus: (_data['payment_status'] ?? _data['paymentStatus'] ?? 'UNPAID').toString(),
      dueAmount: (_data['due_amount'] ?? _data['dueAmount'] ?? (validTax.totalAmount - (_data['amount_paid'] ?? 0.0)) as num).toDouble(),
      approvalStatus: ApprovalStatus.approved,
      reviewedBy: session.userId ?? 'merchant',
      reviewedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final productDetails = <String, Map<String, dynamic>>{};
    for (final item in cartItems) {
      productDetails[item.productId] = {
        'name': item.productName,
        'hsn_sac_code': '-',
        'gst_rate': item.gstRate,
      };
    }

    final generated = await InvoicePdfGenerator.generateApprovedInvoicePdfOffline(
      approval: draftApproval,
      invoiceNumber: invoiceNo,
      shopName: (session.shopName?.isNotEmpty == true) ? session.shopName! : 'Dukan Sathi',
      shopState: shopConfig.state,
      gstNumber: shopConfig.gstRegistrationNumber,
      businessType: shopConfig.businessType,
      customerName: draftApproval.customerName ?? 'Walk-in Customer',
      customerPhone: null,
      productDetails: productDetails,
    );
    return generated.file; // On web this already triggered the download
  }
}

class _StaticPlaceholder extends StatelessWidget {
  const _StaticPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            SizedBox(height: 12),
            Text('Preparing Draft...', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final String message;
  const _ErrorPlaceholder({required this.message});
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      blur: 15,
      opacity: 0.1,
      border: Border.all(color: AppColors.error.withOpacity(0.4)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, color: AppColors.warning, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Invoice draft could not be rendered',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ApprovalProgressDialog extends StatefulWidget {
  final String invoiceNo;
  final String customerName;
  final VoidCallback onFinish;

  const ApprovalProgressDialog({
    super.key,
    required this.invoiceNo,
    required this.customerName,
    required this.onFinish,
  });

  @override
  State<ApprovalProgressDialog> createState() => _ApprovalProgressDialogState();
}

class _ApprovalProgressDialogState extends State<ApprovalProgressDialog> {
  int _activeStep = 0;
  bool _isError = false;
  String _errorMessage = '';

  final List<String> _steps = [
    "Verifying invoice parameters & customer state",
    "Writing finalized billing record to SQLite database",
    "Recalculating local store inventory stock counts",
    "Queueing background synchronization tasks",
    "Generating print-ready GST-compliant PDF invoice",
  ];

  @override
  void initState() {
    super.initState();
    _startApproval();
  }

  Future<void> _startApproval() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _activeStep = 1);

      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _activeStep = 2);

      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _activeStep = 3);

      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _activeStep = 4);

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _activeStep = 5);

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      widget.onFinish();

    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // Non-dismissible
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xEC15151A) : const Color(0xF4FFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isError
                  ? AppColors.error.withOpacity(0.3)
                  : (_activeStep == 5 ? AppColors.success.withOpacity(0.4) : theme.primaryColor.withOpacity(0.2)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_activeStep == 5 ? AppColors.success : theme.primaryColor).withOpacity(0.12),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Header Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (_isError
                      ? AppColors.error
                      : (_activeStep == 5 ? AppColors.success : theme.primaryColor)).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (_isError
                        ? AppColors.error
                        : (_activeStep == 5 ? AppColors.success : theme.primaryColor)).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: _isError
                    ? const Icon(Iconsax.warning_2, color: AppColors.error, size: 30)
                    : (_activeStep == 5
                        ? const Icon(Iconsax.tick_circle, color: AppColors.success, size: 32)
                        : const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )),
              ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),

              // Title
              Text(
                _isError
                    ? "Approval Failed"
                    : (_activeStep == 5 ? "Invoice Finalized!" : "Approving Invoice"),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isError
                    ? "An error occurred during finalization."
                    : (_activeStep == 5 ? "Billing record generated successfully." : "Assembling POS transaction ledger..."),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 24),

              // Step Checklist
              ...List.generate(_steps.length, (index) {
                final isDone = _activeStep > index;
                final isActive = _activeStep == index;

                Widget leadingWidget = const Icon(Iconsax.clock, size: 16, color: Colors.white24);

                if (isDone) {
                  leadingWidget = const Icon(Iconsax.tick_circle, color: AppColors.success, size: 18)
                      .animate()
                      .scale(duration: 200.ms, curve: Curves.easeOutBack);
                } else if (isActive && !_isError) {
                  leadingWidget = const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else if (_isError && isActive) {
                  leadingWidget = const Icon(Iconsax.close_circle, color: AppColors.error, size: 18);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: leadingWidget,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _steps[index],
                          style: TextStyle(
                            fontSize: 13,
                            color: isDone
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : (isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white30 : Colors.black38)),
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Action at completion or error
              if (_activeStep == 5) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Launch Print & PDF Viewer",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
              ] else if (_isError) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: AppColors.error, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
