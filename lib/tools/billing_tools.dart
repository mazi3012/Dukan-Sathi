import 'package:schemantic/schemantic.dart';

import '../core/database.dart';
import '../models/cart_item.dart';
import '../models/draft_approval.dart';
import '../models/draft_invoice.dart';
import '../models/shop_config.dart';
import '../runtime/genkit_runtime.dart';
import '../services/gst_calculator.dart';

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
    final shopId = (input['shopId'] as String?) ?? await getShopIdForUser(context.context?['userIdentifier'] as String?);
    final customerId = input['customerId'] as String?;
    final customerState = input['customerState'] as String?;
    final requestedItems = Map<String, dynamic>.from(
      input['requestedItems'] as Map,
    );

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

      final rows = await supabase
          .from('products')
          .select('id, price, name, shop_id')
          .eq('shop_id', shopId)
          .or('id.eq.$productName,name.ilike.%$productName%')
          .limit(1);

      final productList = rows as List<dynamic>;
      if (productList.isEmpty) {
        throw StateError('Product "$productName" not in inventory. Please ensure you are using the correct name or ID.');
      }

      final product = Map<String, dynamic>.from(productList.first as Map);
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
  },
);

final createDraftInvoice = createDraftInvoiceTool;
