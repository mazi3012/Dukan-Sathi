import 'package:schemantic/schemantic.dart';

import '../core/database.dart';
import '../models/cart_item.dart';
import '../models/draft_approval.dart';
import '../models/draft_invoice.dart';
import '../models/shop_config.dart';
import '../runtime/genkit_runtime.dart';
import '../services/gst_calculator.dart';

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
      'customerState': {'type': 'string'},
      'requestedItems': {
        'type': 'object',
        'additionalProperties': {'type': 'integer'},
      },
    },
    'required': ['requestedItems'],
    'additionalProperties': false,
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
    );
  },
);

Future<Map<String, dynamic>> createDraftInvoiceRequest({
  required Map<String, dynamic> input,
  required String? userIdentifier,
}) async {
  final shopId = (input['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
  final customerId = input['customerId'] as String?;
  final customerState = input['customerState'] as String?;
  final requestedItems = Map<String, dynamic>.from(
    input['requestedItems'] as Map,
  );

    final allShopProductsRows = await supabase
        .from('products')
        .select('id, price, name, shop_id')
        .eq('shop_id', shopId);
    final allShopProducts = (allShopProductsRows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    // Fetch shop config for GST calculations
    final shopRows = await supabase
        .from('shops')
        .select('id, state, gst_registration_number, gst_mode, business_type, created_at')
        .eq('id', shopId)
        .single();

    final shopData = Map<String, dynamic>.from(shopRows as Map);
    
    // Determine GST mode from database
    final gstModeStr = shopData['gst_mode'] as String? ?? 'REGISTERED';
    final gstMode = GSTMode.values.firstWhere(
      (e) => e.name == gstModeStr.toLowerCase(),
      orElse: () => GSTMode.registered,
    );

    final shopConfig = ShopConfig(
      shopId: shopId,
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

      items.add(
        CartItem(
          productId: productId,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );
    }

    // Calculate tax using GST calculator
    final taxBreakdown = GSTCalculator.calculateTax(
      items: items,
      shopConfig: shopConfig,
      customerState: customerState,
    );

    // Create pending approval ID
    final approvalId = GSTCalculator.generateApprovalId();

    // Insert draft_approval into database with pending status
    await supabase.from('draft_approvals').insert({
      'approval_id': approvalId,
      'shop_id': shopId,
      'customer_id': customerId,
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
      },
      'proposed_total': taxBreakdown.totalAmount,
      'approval_status': 'PENDING',
    }).select();

    // Return response showing approval pending + tax breakdown
    return {
      'approvalId': approvalId,
      'shopId': shopId,
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
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
