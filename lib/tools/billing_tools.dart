import 'package:schemantic/schemantic.dart';

import '../core/database.dart';
import '../models/cart_item.dart';
import '../models/draft_invoice.dart';
import '../runtime/genkit_runtime.dart';

final SchemanticType<Map<String, dynamic>> createDraftInvoiceInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'shopId': {'type': 'string'},
      'customerId': {'type': 'string'},
      'requestedItems': {
        'type': 'object',
        'additionalProperties': {'type': 'integer'},
      },
    },
    'required': ['shopId', 'requestedItems'],
    'additionalProperties': false,
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

final createDraftInvoiceTool = ai.defineTool<Map<String, dynamic>, DraftInvoice>(
  name: 'createDraftInvoice',
  description: 'Create a draft invoice from requested product quantities.',
  inputSchema: createDraftInvoiceInputSchema,
  fn: (input, context) async {
    final shopId = input['shopId'] as String;
    final customerId = input['customerId'] as String?;
    final requestedItems = Map<String, dynamic>.from(
      input['requestedItems'] as Map,
    );

    final items = <CartItem>[];
    double totalAmount = 0;

    for (final entry in requestedItems.entries) {
      final productName = entry.key;
      final quantity = (entry.value as num).toInt();

      final rows = await supabase
          .from('products')
          .select('id, price, name, shop_id')
          .eq('shop_id', shopId)
          .ilike('name', '%$productName%')
          .limit(1);

      final productList = rows as List<dynamic>;
      if (productList.isEmpty) {
        throw StateError('Not in inventory');
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
      totalAmount += unitPrice * quantity;
    }

    final inserted = await supabase
        .from('draft_invoices')
        .insert({
          'shop_id': shopId,
          'customer_id': customerId,
          'items': items.map((item) => item.toJson()).toList(),
          'total_amount': totalAmount,
          'status': 'draft',
        })
        .select('id, shop_id, customer_id, items, total_amount, status')
        .single();

    return DraftInvoice.fromJson(
      Map<String, dynamic>.from(inserted as Map),
    );
  },
);

final createDraftInvoice = createDraftInvoiceTool;
