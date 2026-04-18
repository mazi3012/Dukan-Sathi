import 'package:schemantic/schemantic.dart';

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

final createDraftInvoice = ai.defineTool<Map<String, dynamic>, DraftInvoice>(
  name: 'createDraftInvoice',
  description: 'Create a draft invoice from requested product quantities.',
  inputSchema: createDraftInvoiceInputSchema,
  fn: (input, context) async {
    final shopId = input['shopId'] as String;
    final customerId = input['customerId'] as String?;
    final requestedItems = Map<String, dynamic>.from(
      input['requestedItems'] as Map,
    );

    final catalog = <String, double>{
      'atta': 420.0,
      'rice': 575.0,
      'sugar': 48.0,
      'oil': 170.0,
      'salt': 22.0,
    };

    final items = <CartItem>[];
    double totalAmount = 0;

    requestedItems.forEach((productName, quantityValue) {
      final quantity = (quantityValue as num).toInt();
      final unitPrice = catalog[productName.toLowerCase()] ?? 0.0;
      items.add(
        CartItem(
          productId: 'mock-${productName.toLowerCase()}',
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );
      totalAmount += unitPrice * quantity;
    });

    return DraftInvoice(
      id: 'draft-${DateTime.now().microsecondsSinceEpoch}',
      shopId: shopId,
      customerId: customerId,
      items: items,
      totalAmount: totalAmount,
    );
  },
);
