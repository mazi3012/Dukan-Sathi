import 'package:schemantic/schemantic.dart';

import '../core/database.dart';
import '../shared/models/cart_item.dart';
import '../shared/models/shop_config.dart';
import '../runtime/genkit_runtime.dart';
import '../shared/services/gst_calculator.dart';

String _normalizeProductQuery(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _queryTokens(String input) {
  return _normalizeProductQuery(input)
      .split(' ')
      .where((token) => token.isNotEmpty && !RegExp(r'^\d+$').hasMatch(token))
      .toList();
}

String? _normalizeDiscountType(dynamic value) {
  final normalized = value?.toString().trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized == 'PERCENT' || normalized == 'AMOUNT') {
    return normalized;
  }
  throw StateError('discountType must be PERCENT or AMOUNT.');
}

String? _normalizePaymentStatus(dynamic value) {
  final normalized = value?.toString().trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized == 'PAID' || normalized == 'PARTIAL' || normalized == 'UNPAID') {
    return normalized;
  }
  throw StateError('paymentStatus must be PAID, PARTIAL, or UNPAID.');
}

String? _normalizeCustomerName(dynamic value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}

String? _extractCustomerNameFromPrompt(String input) {
  var text = input.toLowerCase().trim();
  text = text
      .replaceAll(RegExp(r'^(please\s+)?(make|create|generate|draft)\s+(a\s+)?(bill|invoice)\s*(for|with|to)?\s*'), '')
      .replaceAll(RegExp(r'\.$'), '')
      .trim();

  if (text.isEmpty) return null;

  final stopWords = {
    'he', 'she', 'they', 'customer', 'buyer', 'bought', 'took', 'takes', 'take',
    'brought', 'want', 'needs', 'need', 'please', 'for', 'to', 'the', 'a', 'an',
    'of', 'item', 'items', 'product', 'products', 'with', 'and', 'plus', 'has', 'have', 'got'
  };

  final tokens = text.split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
  final nameTokens = <String>[];
  for (final token in tokens) {
    if (RegExp(r'^\d+$').hasMatch(token)) break;
    if (stopWords.contains(token)) break;
    nameTokens.add(token);
  }

  if (nameTokens.isEmpty) return null;

  return nameTokens.map((token) => token[0].toUpperCase() + token.substring(1)).join(' ');
}

double _roundToTwoDecimals(double value) => (value * 100).round() / 100;

bool _isMissingColumnError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('could not find the') && text.contains('column');
}

/// Computes invoice-level discount amounts WITHOUT mutating item unit prices.
/// Per Section 15(3)(a) CGST Act, the discount is applied to the aggregate
/// subtotal to establish taxable value. Items are returned unchanged.
Map<String, dynamic> _applyDiscountToItems({
  required List<CartItem> items,
  required String? discountType,
  required double? discountValue,
}) {
  final subtotal = _roundToTwoDecimals(
    items.fold<double>(0.0, (sum, item) => sum + (item.unitPrice * item.quantity)),
  );

  if (subtotal <= 0) {
    return {
      'subtotalBeforeDiscount': 0.0,
      'discountAmount': 0.0,
      'subtotalAfterDiscount': 0.0,
      'items': items, // original items unchanged
    };
  }

  var discountAmount = 0.0;
  if (discountType != null && discountValue != null) {
    if (discountType == 'PERCENT') {
      if (discountValue < 0 || discountValue > 100) {
        throw StateError('discountValue must be between 0 and 100 for percent discounts.');
      }
      discountAmount = subtotal * (discountValue / 100.0);
    } else {
      if (discountValue < 0) {
        throw StateError('discountValue must be non-negative for fixed amount discounts.');
      }
      discountAmount = discountValue;
    }
  }

  if (discountAmount > subtotal) {
    throw StateError('Discount cannot be greater than subtotal.');
  }

  final subtotalAfterDiscount = _roundToTwoDecimals(subtotal - discountAmount);

  return {
    'subtotalBeforeDiscount': subtotal,
    'discountAmount': _roundToTwoDecimals(discountAmount),
    'subtotalAfterDiscount': subtotalAfterDiscount,
    'items': items, // original items unchanged — no unit price mutation
  };
}

Map<String, dynamic>? _matchRequestedProduct(
  List<Map<String, dynamic>> products,
  String requestedName,
) {
  final normalizedRequested = _normalizeProductQuery(requestedName);
  final requestedTokens = _queryTokens(requestedName);

  for (final product in products) {
    final productId = product['id']?.toString().trim();
    final productName = product['name']?.toString().trim() ?? '';
    if (productId == requestedName.trim() ||
        _normalizeProductQuery(productName) == normalizedRequested) {
      return product;
    }
  }

  if (requestedTokens.isEmpty) {
    return null;
  }

  Map<String, dynamic>? bestMatch;
  double bestScore = 0;

  for (final product in products) {
    final productName = product['name']?.toString().trim() ?? '';
    final productTokens = _queryTokens(productName).toSet();
    if (productTokens.isEmpty) {
      continue;
    }

    final intersection = requestedTokens.where(productTokens.contains).length;
    if (intersection == 0) {
      continue;
    }

    final score = intersection / requestedTokens.length;
    if (score > bestScore) {
      bestScore = score;
      bestMatch = product;
    }
  }

  if (bestScore >= 0.5) {
    return bestMatch;
  }

  return null;
}

final SchemanticType<Map<String, dynamic>> createDraftInvoiceInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'shopId': {'type': 'string'},
      'customerId': {'type': 'string'},
      'customerName': {'type': 'string'},
      'customerState': {'type': 'string'},
      'discountType': {'type': 'string', 'enum': ['PERCENT', 'AMOUNT']},
      'discountValue': {'type': 'number'},
      'paymentStatus': {'type': 'string', 'enum': ['PAID', 'PARTIAL', 'UNPAID']},
      'amountPaid': {'type': 'number'},
      'requestedItems': {
        'type': 'object',
        'additionalProperties': {'type': 'integer'},
      },
      'userPrompt': {'type': 'string'},
    },
    'required': ['requestedItems'],
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

final createDraftInvoiceTool = ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
  name: 'createDraftInvoice',
  description: 'Create a draft invoice with GST tax calculations. Requires human approval before finalization.',
  inputSchema: createDraftInvoiceInputSchema,
  fn: (input, context) async {
    return createDraftInvoiceRequest(
      input: input,
      userIdentifier: context.context?['userIdentifier'] as String?,
      shopId: context.context?['shopId'] as String?,
    );
  },
);

Future<Map<String, dynamic>> createDraftInvoiceRequest({
  required Map<String, dynamic> input,
  required String? userIdentifier,
  String? shopId,
}) async {
  final rawShopId = input['shopId'] as String?;
  final effectiveShopId = (isValidUuid(rawShopId) ? rawShopId : null) ?? 
                 shopId ?? 
                 await getShopIdForUser(userIdentifier);
  final customerId = input['customerId'] as String?;
  final customerNameInput = _normalizeCustomerName(input['customerName']);
  final userPrompt = input['userPrompt'] as String?;
  
  // Fallback name extraction from prompt if missing
  String? extractedName;
  if (customerNameInput == null && userPrompt != null) {
    extractedName = _extractCustomerNameFromPrompt(userPrompt);
  }

  final customerName = customerNameInput ?? extractedName;
  final customerState = input['customerState'] as String?;
  final discountType = _normalizeDiscountType(input['discountType']);
  final discountValue = (input['discountValue'] as num?)?.toDouble();
  final paymentStatusInput = _normalizePaymentStatus(input['paymentStatus']);
  final amountPaidInput = (input['amountPaid'] as num?)?.toDouble();
  final requestedItems = Map<String, dynamic>.from(
    input['requestedItems'] as Map,
  );

  if ((discountType == null) != (discountValue == null)) {
    throw StateError('discountType and discountValue must be provided together.');
  }

  String? resolvedCustomerId = customerId;
  String? resolvedCustomerName = customerName;

  if (resolvedCustomerName != null && resolvedCustomerId == null) {
    final customerRows = await supabase
        .from('customers')
        .select('id, name')
        .eq('shop_id', effectiveShopId)
        .ilike('name', resolvedCustomerName)
        .maybeSingle();
    if (customerRows != null) {
      final customerData = Map<String, dynamic>.from(customerRows as Map);
      resolvedCustomerId = customerData['id']?.toString();
      resolvedCustomerName = customerData['name']?.toString().trim() ?? resolvedCustomerName;
    }
  }

  if (resolvedCustomerName == null && resolvedCustomerId != null) {
    final customerRows = await supabase
        .from('customers')
        .select('name')
        .eq('shop_id', effectiveShopId)
        .eq('id', resolvedCustomerId)
        .maybeSingle();
    if (customerRows != null) {
      resolvedCustomerName = (customerRows as Map)['name']?.toString().trim();
    }
  }

    final allShopProductsRows = await supabase
        .from('products')
        .select('id, price, name, shop_id, gst_rate, hsn_sac_code')
        .eq('shop_id', effectiveShopId);
    final allShopProducts = (allShopProductsRows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    // Fetch shop config for GST calculations
    final shopRows = await supabase
        .from('shops')
        .select('id, state, gst_registration_number, gst_mode, business_type, created_at')
        .eq('id', effectiveShopId)
        .single();

    final shopData = Map<String, dynamic>.from(shopRows as Map);
    
    // Determine GST mode from database
    final gstModeStr = shopData['gst_mode'] as String? ?? 'REGISTERED';
    final gstMode = GSTMode.values.firstWhere(
      (e) => e.name == gstModeStr.toLowerCase(),
      orElse: () => GSTMode.registered,
    );

    final shopConfig = ShopConfig(
      shopId: effectiveShopId,
      state: shopData['state'] as String,
      gstRegistrationNumber: shopData['gst_registration_number'] as String?,
      gstMode: gstMode,
      businessType: shopData['business_type'] as String? ?? 'Retail',
      createdAt: DateTime.parse(shopData['created_at'] as String),
    );

    // Build CartItems from requested products
    final items = <CartItem>[];

    for (final entry in requestedItems.entries) {
      final productName = entry.key;
      final quantity = (entry.value as num).toInt();

      final product = _matchRequestedProduct(allShopProducts, productName);
      if (product == null) {
        final suggestions = allShopProducts
            .map((row) => row['name']?.toString().trim())
            .whereType<String>()
            .take(5)
            .join(', ');
        throw StateError(
          'Product "$productName" not in inventory. Try a shorter name or a product ID. Available examples: ${suggestions.isEmpty ? 'none' : suggestions}.',
        );
      }

      final unitPrice = (product['price'] as num).toDouble();
      final productId = product['id'] as String;
      // Resolve GST rate: use product's gst_rate if set (>0), else default 18%
      final rawGstRate = (product['gst_rate'] as num?)?.toDouble() ?? 0.0;
      final gstRate = rawGstRate > 0 ? rawGstRate : 18.0;

      items.add(
        CartItem(
          productId: productId,
          productName: product['name']?.toString() ?? productName,
          quantity: quantity,
          unitPrice: unitPrice,
          gstRate: gstRate,
        ),
      );
    }

    final originalItems = items.map((item) => item.toJson()).toList();

    final billingAdjustments = _applyDiscountToItems(
      items: items,
      discountType: discountType,
      discountValue: discountValue,
    );
    // Items are returned unchanged (original unit prices preserved)
    final subtotalBeforeDiscount = billingAdjustments['subtotalBeforeDiscount'] as double;
    final discountAmount = billingAdjustments['discountAmount'] as double;
    final subtotalAfterDiscount = billingAdjustments['subtotalAfterDiscount'] as double;

    // Calculate tax using GST calculator with invoice-level discount
    final taxBreakdown = GSTCalculator.calculateTax(
      items: items,
      shopConfig: shopConfig,
      customerState: customerState,
      invoiceDiscount: discountAmount,
    );

    final finalTotal = taxBreakdown.totalAmount;

    final paymentStatus = paymentStatusInput ??
        (amountPaidInput == null || amountPaidInput <= 0
            ? 'UNPAID'
            : amountPaidInput >= finalTotal
                ? 'PAID'
                : 'PARTIAL');

    var resolvedAmountPaid = amountPaidInput ?? 0.0;
    if (paymentStatus == 'PAID') {
      resolvedAmountPaid = finalTotal;
    } else if (paymentStatus == 'PARTIAL' && resolvedAmountPaid <= 0) {
      throw StateError('amountPaid is required when paymentStatus is PARTIAL.');
    } else if (paymentStatus == 'UNPAID') {
      resolvedAmountPaid = 0.0;
    }

    if (resolvedAmountPaid < 0) {
      throw StateError('amountPaid cannot be negative.');
    }

    if (resolvedAmountPaid > finalTotal) {
      throw StateError('amountPaid cannot exceed the final total.');
    }

    final dueAmount = _roundToTwoDecimals(finalTotal - resolvedAmountPaid);

    // Create pending approval ID
    final approvalId = GSTCalculator.generateApprovalId();

    final draftApprovalPayload = {
      'approval_id': approvalId,
      'shop_id': effectiveShopId,
      'customer_id': resolvedCustomerId,
      'customer_name': resolvedCustomerName,
      'customer_state': customerState,
      'created_at': DateTime.now().toIso8601String(),
      'original_items': originalItems,
      'original_subtotal': subtotalBeforeDiscount,
      'proposed_items': items.map((item) => item.toJson()).toList(),
      'proposed_tax_breakdown': {
        'subtotal': taxBreakdown.subtotal,
        'cgst_amount': taxBreakdown.cgstAmount,
        'sgst_amount': taxBreakdown.sgstAmount,
        'igst_amount': taxBreakdown.igstAmount,
        'gst_mode': taxBreakdown.gstMode,
        'applicable_state': taxBreakdown.applicableState,
        'tax_slab': taxBreakdown.taxSlab,
        'total_amount': taxBreakdown.totalAmount,
        'breakdown': taxBreakdown.breakdown,
        'rate_wise_summary': taxBreakdown.rateWiseSummary,
      },
      'proposed_total': finalTotal,
      'subtotal_before_discount': subtotalBeforeDiscount,
      'subtotal_after_discount': subtotalAfterDiscount,
      'discount_type': discountType,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'payment_status': paymentStatus,
      'amount_paid': resolvedAmountPaid,
      'due_amount': dueAmount,
      'approval_status': 'PENDING',
    };

    // Insert draft_approval into database with pending status.
    // Fallback keeps draft creation working on databases that have not yet applied
    // the latest billing/customer columns.
    try {
      await supabase.from('draft_approvals').insert(draftApprovalPayload).select('approval_id');
    } catch (e) {
      if (!_isMissingColumnError(e)) {
        rethrow;
      }

      final legacyPayload = {
        'approval_id': approvalId,
      'shop_id': effectiveShopId,
      'customer_id': resolvedCustomerId,
      'created_at': DateTime.now().toIso8601String(),
        'proposed_items': items.map((item) => item.toJson()).toList(),
        'proposed_tax_breakdown': {
          'subtotal': taxBreakdown.subtotal,
          'cgst_amount': taxBreakdown.cgstAmount,
          'sgst_amount': taxBreakdown.sgstAmount,
          'igst_amount': taxBreakdown.igstAmount,
          'gst_mode': taxBreakdown.gstMode,
          'applicable_state': taxBreakdown.applicableState,
          'tax_slab': taxBreakdown.taxSlab,
          'total_amount': taxBreakdown.totalAmount,
          'breakdown': taxBreakdown.breakdown,
          'rate_wise_summary': taxBreakdown.rateWiseSummary,
        },
        'proposed_total': finalTotal,
        'approval_status': 'PENDING',
      };

      await supabase.from('draft_approvals').insert(legacyPayload).select('approval_id');
    }

    // Return response showing approval pending + tax breakdown
    return {
      'approvalId': approvalId,
      'shopId': effectiveShopId,
      'customerId': resolvedCustomerId,
      'customerName': resolvedCustomerName,
      'customerState': customerState,
      'items': items.map((item) => item.toJson()).toList(),
      'discount': {
        'discountType': discountType,
        'discountValue': discountValue,
        'discountAmount': discountAmount,
        'subtotalBeforeDiscount': subtotalBeforeDiscount,
        'subtotalAfterDiscount': subtotalAfterDiscount,
      },
      'payment': {
        'paymentStatus': paymentStatus,
        'amountPaid': resolvedAmountPaid,
        'dueAmount': dueAmount,
      },
      'taxBreakdown': {
        'subtotal': taxBreakdown.subtotal,
        'cgstAmount': taxBreakdown.cgstAmount,
        'sgstAmount': taxBreakdown.sgstAmount,
        'igstAmount': taxBreakdown.igstAmount,
        'gstMode': taxBreakdown.gstMode,
        'applicableState': taxBreakdown.applicableState,
        'taxSlab': taxBreakdown.taxSlab,
        'totalAmount': taxBreakdown.totalAmount,
      },
      'requiresApproval': true,
      'message': 'Draft invoice created with tax calculation. Awaiting your approval to finalize.\n\nApproval ID: $approvalId',
    };
}

final createDraftInvoice = createDraftInvoiceTool;
