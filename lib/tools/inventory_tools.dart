import 'package:schemantic/schemantic.dart';
import 'package:supabase/supabase.dart';

import '../runtime/genkit_runtime.dart';
import '../models/product.dart';

final SchemanticType<Map<String, dynamic>> checkInventoryInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'productName': {'type': 'string'},
    },
    'required': ['productName'],
    'additionalProperties': false,
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

SupabaseClient createMockSupabaseClient() {
  return SupabaseClient(
    'https://mock.supabase.co',
    'mock-anon-key',
  );
}

final checkInventory = ai.defineTool<Map<String, dynamic>, List<Product>>(
  name: 'checkInventory',
  description: 'Find inventory items that match a product name fragment.',
  inputSchema: checkInventoryInputSchema,
  fn: (productName, context) async {
    final query = productName['productName'] as String;
    final client = createMockSupabaseClient();
    try {
      final response = await client
          .from('products')
          .select('id, shop_id, name, price, stock_quantity, category')
          .ilike('name', '%$query%');

      return (response as List<dynamic>)
          .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      final normalizedQuery = query.toLowerCase();
      final fallbackProducts = <Product>[
        const Product(
          id: 'prod-atta-01',
          shopId: 'shop-demo-01',
          name: 'Aashirvaad Atta 10kg',
          price: 420.0,
          stockQuantity: 24,
          category: 'Staples',
        ),
        const Product(
          id: 'prod-rice-01',
          shopId: 'shop-demo-01',
          name: 'Fortune Basmati Rice 5kg',
          price: 575.0,
          stockQuantity: 18,
          category: 'Staples',
        ),
      ];

      return fallbackProducts
          .where((product) => product.name.toLowerCase().contains(normalizedQuery))
          .toList();
    }
  },
);
