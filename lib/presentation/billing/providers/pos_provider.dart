import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/session.dart';
import '../../../models/cart_item.dart';
import '../../../models/draft_approval.dart';
import '../../../services/gst_calculator.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/sync/sync_manager.dart';

class POSInvoiceState {
  final String approvalId;
  final String? customerId;
  final String customerName;
  final String customerState;
  final List<CartItem> items;
  final String gstType; // 'CGST_SGST' or 'IGST'
  final String discountType; // 'PERCENT' or 'FLAT'
  final double discountValue;
  final double discountAmount;
  final double subtotalBeforeDiscount;
  final double subtotalAfterDiscount;
  final Map<String, dynamic> taxBreakdown;
  final double totalAmount;
  final String paymentStatus; // 'PAID', 'UNPAID', 'PARTIAL'
  final double amountPaid;
  final double dueAmount;
  final bool isApproved;
  final String? invoiceNumber;

  POSInvoiceState({
    required this.approvalId,
    this.customerId,
    required this.customerName,
    required this.customerState,
    required this.items,
    required this.gstType,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.subtotalBeforeDiscount,
    required this.subtotalAfterDiscount,
    required this.taxBreakdown,
    required this.totalAmount,
    required this.paymentStatus,
    required this.amountPaid,
    required this.dueAmount,
    this.isApproved = false,
    this.invoiceNumber,
  });

  factory POSInvoiceState.empty() {
    return POSInvoiceState(
      approvalId: const Uuid().v4(),
      customerName: 'Walk-in Customer',
      customerState: UserSession().shopConfig.state,
      items: [],
      gstType: 'CGST_SGST',
      discountType: 'PERCENT',
      discountValue: 0.0,
      discountAmount: 0.0,
      subtotalBeforeDiscount: 0.0,
      subtotalAfterDiscount: 0.0,
      taxBreakdown: {},
      totalAmount: 0.0,
      paymentStatus: 'UNPAID',
      amountPaid: 0.0,
      dueAmount: 0.0,
    );
  }

  POSInvoiceState copyWith({
    String? approvalId,
    String? customerId,
    String? customerName,
    String? customerState,
    List<CartItem>? items,
    String? gstType,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    double? subtotalBeforeDiscount,
    double? subtotalAfterDiscount,
    Map<String, dynamic>? taxBreakdown,
    double? totalAmount,
    String? paymentStatus,
    double? amountPaid,
    double? dueAmount,
    bool? isApproved,
    String? invoiceNumber,
  }) {
    return POSInvoiceState(
      approvalId: approvalId ?? this.approvalId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerState: customerState ?? this.customerState,
      items: items ?? this.items,
      gstType: gstType ?? this.gstType,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      subtotalBeforeDiscount: subtotalBeforeDiscount ?? this.subtotalBeforeDiscount,
      subtotalAfterDiscount: subtotalAfterDiscount ?? this.subtotalAfterDiscount,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountPaid: amountPaid ?? this.amountPaid,
      dueAmount: dueAmount ?? this.dueAmount,
      isApproved: isApproved ?? this.isApproved,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approval_id': approvalId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_state': customerState,
      'proposed_items': items.map((i) => i.toJson()).toList(),
      'gst_type': gstType,
      'discount_type': discountType,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'subtotal_before_discount': subtotalBeforeDiscount,
      'subtotal_after_discount': subtotalAfterDiscount,
      'proposed_tax_breakdown': taxBreakdown,
      'proposed_total': totalAmount,
      'payment_status': paymentStatus,
      'amount_paid': amountPaid,
      'due_amount': dueAmount,
      'approval_status': isApproved ? 'APPROVED' : 'PENDING',
      'invoice_number': invoiceNumber,
    };
  }

  factory POSInvoiceState.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['proposed_items'] ?? json['items'] ?? []) as List<dynamic>;
    final parsedItems = itemsList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return CartItem(
        productId: map['productId'] as String,
        productName: map['productName']?.toString() ?? map['name']?.toString() ?? 'Item',
        quantity: (map['quantity'] as num).toInt(),
        unitPrice: (map['unitPrice'] as num).toDouble(),
        gstRate: (map['gstRate'] as num?)?.toDouble() ?? 18.0,
      );
    }).toList();

    return POSInvoiceState(
      approvalId: (json['approval_id'] ?? json['approvalId'] ?? const Uuid().v4()).toString(),
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString() ?? 'Walk-in Customer',
      customerState: json['customer_state']?.toString() ?? json['customerState']?.toString() ?? UserSession().shopConfig.state,
      items: parsedItems,
      gstType: json['gst_type']?.toString() ?? json['gstType']?.toString() ?? 'CGST_SGST',
      discountType: json['discount_type']?.toString() ?? json['discountType']?.toString() ?? 'PERCENT',
      discountValue: (json['discount_value'] ?? json['discountValue'] ?? 0.0) as double,
      discountAmount: (json['discount_amount'] ?? json['discountAmount'] ?? 0.0) as double,
      subtotalBeforeDiscount: (json['subtotal_before_discount'] ?? json['subtotalBeforeDiscount'] ?? 0.0) as double,
      subtotalAfterDiscount: (json['subtotal_after_discount'] ?? json['subtotalAfterDiscount'] ?? 0.0) as double,
      taxBreakdown: Map<String, dynamic>.from(json['proposed_tax_breakdown'] ?? json['taxBreakdown'] ?? {}),
      totalAmount: (json['proposed_total'] ?? json['total_amount'] ?? json['totalAmount'] ?? 0.0) as double,
      paymentStatus: json['payment_status']?.toString() ?? json['paymentStatus']?.toString() ?? 'UNPAID',
      amountPaid: (json['amount_paid'] ?? json['amountPaid'] ?? 0.0) as double,
      dueAmount: (json['due_amount'] ?? json['dueAmount'] ?? 0.0) as double,
      isApproved: json['approval_status'] == 'APPROVED' || json['status'] == 'approved',
      invoiceNumber: json['invoice_number']?.toString(),
    );
  }
}

class POSNotifier extends StateNotifier<POSInvoiceState> {
  POSNotifier() : super(POSInvoiceState.empty());

  void setDraft(Map<String, dynamic> payload) {
    state = POSInvoiceState.fromJson(payload);
    recalculate();
  }

  void reset() {
    state = POSInvoiceState.empty();
  }

  void addItem(CartItem item) {
    final existingIndex = state.items.indexWhere((i) => i.productId == item.productId);
    List<CartItem> updatedItems;

    if (existingIndex != -1) {
      updatedItems = List<CartItem>.from(state.items);
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
    } else {
      updatedItems = [...state.items, item];
    }

    state = state.copyWith(items: updatedItems);
    recalculate();
  }

  void updateItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    recalculate();
  }

  void updateItemPrice(String productId, double price) {
    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(unitPrice: price);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    recalculate();
  }

  void removeItem(String productId) {
    final updatedItems = state.items.where((i) => i.productId != productId).toList();
    state = state.copyWith(items: updatedItems);
    recalculate();
  }

  void updateGSTType(String gstType) {
    state = state.copyWith(gstType: gstType);
    recalculate();
  }

  void updateDiscount(String discountType, double discountValue) {
    state = state.copyWith(
      discountType: discountType,
      discountValue: discountValue,
    );
    recalculate();
  }

  void updatePayment(String paymentStatus, double amountPaid) {
    state = state.copyWith(
      paymentStatus: paymentStatus,
      amountPaid: amountPaid,
    );
    recalculate();
  }

  void setCustomer(String? id, String name, String stateCode) {
    state = state.copyWith(
      customerId: id,
      customerName: name,
      customerState: stateCode,
    );
    recalculate();
  }

  void recalculate() {
    final shopConfig = UserSession().shopConfig;

    // 1. Calculate base subtotal
    double subtotal = 0.0;
    for (final item in state.items) {
      subtotal += item.quantity * item.unitPrice;
    }

    // 2. Resolve discount amount
    double discountAmount = 0.0;
    if (state.discountType == 'PERCENT') {
      discountAmount = subtotal * (state.discountValue / 100);
    } else {
      discountAmount = state.discountValue;
    }
    discountAmount = discountAmount.clamp(0.0, subtotal);

    // 3. Set customer state based on GST Type (IGST triggers out-of-state)
    String customerState = state.customerState;
    if (state.gstType == 'IGST') {
      customerState = shopConfig.state == 'DL' ? 'MH' : 'DL'; // Force inter-state
    } else {
      customerState = shopConfig.state; // Local CGST/SGST
    }

    // 4. Calculate detailed Indian GST breakdown
    final taxBreakdown = GSTCalculator.calculateTax(
      items: state.items,
      shopConfig: shopConfig,
      customerState: customerState,
      invoiceDiscount: discountAmount,
    );

    // 5. Update amount paid and outstanding dues
    double finalTotal = taxBreakdown.totalAmount;
    double paid = 0.0;
    if (state.paymentStatus == 'PAID') {
      paid = finalTotal;
    } else if (state.paymentStatus == 'PARTIAL') {
      paid = state.amountPaid.clamp(0.0, finalTotal);
    }

    state = state.copyWith(
      discountAmount: discountAmount,
      subtotalBeforeDiscount: taxBreakdown.subtotal,
      subtotalAfterDiscount: taxBreakdown.subtotal,
      taxBreakdown: taxBreakdown.toJson(),
      totalAmount: finalTotal,
      amountPaid: paid,
      dueAmount: finalTotal - paid,
    );
  }

  Future<bool> finalizeInvoice() async {
    if (state.items.isEmpty) return false;

    final session = UserSession();
    final shopId = session.shopId!;
    final saleId = const Uuid().v4();
    final draftInvoiceId = const Uuid().v4();
    final invoiceNo = 'INV-${state.approvalId.substring(0, 13).replaceAll('-', '').toUpperCase()}';

    try {
      // 1. Save local transaction log in SQFlite database
      final saleRepo = SaleRepository();
      await saleRepo.saveSale({
        'id': saleId,
        'invoice_number': invoiceNo,
        'shop_id': shopId,
        'invoice_id': draftInvoiceId,
        'customer_id': state.customerId,
        'customer_name': state.customerName,
        'customer_state': state.customerState,
        'amount': state.totalAmount,
        'amount_paid': state.amountPaid,
        'due_amount': state.dueAmount,
        'payment_status': state.paymentStatus,
        'discount_type': state.discountType,
        'discount_value': state.discountValue,
        'discount_amount': state.discountAmount,
        'subtotal_before_discount': state.subtotalBeforeDiscount,
        'subtotal_after_discount': state.subtotalAfterDiscount,
        'timestamp': DateTime.now().toIso8601String(),
        'payment_method': 'cash', // Default to cash for direct POS checkout
        'status': 'approved',
      });

      // 2. Adjust local inventories and register operations with SyncManager
      final productRepo = ProductRepository();
      final allProducts = await productRepo.getProducts(shopId);
      final syncManager = SyncManager.instance;

      for (final item in state.items) {
        final pIndex = allProducts.indexWhere((p) => p.id == item.productId);
        if (pIndex != -1) {
          final p = allProducts[pIndex];
          final updatedProduct = p.copyWith(
            stockQuantity: (p.stockQuantity - item.quantity).clamp(0, 999999),
          );
          await productRepo.updateProduct(updatedProduct);
        }

        // Add stocks adjustments background sync queue
        await syncManager.queueOperation(
          tableName: 'products',
          action: 'ADJUST_STOCK',
          recordId: item.productId,
          payload: {'delta': -item.quantity},
        );
      }

      // 3. Queue invoice insertion with cloud background sync queue
      await syncManager.queueOperation(
        tableName: 'draft_invoices',
        action: 'INSERT',
        recordId: draftInvoiceId,
        payload: {
          'id': draftInvoiceId,
          'shop_id': shopId,
          'customer_id': state.customerId,
          'customer_name': state.customerName,
          'items': state.items.map((i) => i.toJson()).toList(),
          'total_amount': state.totalAmount,
          'tax_breakdown': state.taxBreakdown,
          'status': 'approved',
          'draft_approval_id': state.approvalId,
        },
      );

      state = state.copyWith(
        isApproved: true,
        invoiceNumber: invoiceNo,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final posProvider = StateNotifierProvider<POSNotifier, POSInvoiceState>((ref) {
  return POSNotifier();
});
