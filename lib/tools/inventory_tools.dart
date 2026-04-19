import 'package:schemantic/schemantic.dart';

import '../core/database.dart';
import '../runtime/genkit_runtime.dart';
import '../models/product.dart';

Product _productFromRow(Map row) {
  final data = Map<String, dynamic>.from(row);
  return Product.fromJson({
    'id': data['id']?.toString() ?? '',
    'shop_id': data['shop_id']?.toString() ?? '',
    'name': data['name']?.toString() ?? '',
    'price': (data['price'] as num?)?.toDouble() ?? 0.0,
    'stock_quantity': (data['stock_quantity'] as num?)?.toInt() ?? 0,
    'category': data['category']?.toString() ?? '',
  });
}

Future<List<Product>> findInventoryProducts(String rawQuery) async {
  final query = rawQuery.trim();
  if (query.isEmpty) {
    return <Product>[];
  }

  final response = await supabase
      .from('products')
      .select('id, shop_id, name, price, stock_quantity, category')
      .ilike('name', '%$query%');

  if ((response as List).isNotEmpty) {
    return response
        .map((row) => _productFromRow(row as Map))
        .toList();
  }

  // Fall back to token match for minor spelling differences (e.g., ashirvad vs aashirvaad).
  final tokens = query
      .split(RegExp(r'\s+'))
      .map((t) => t.trim())
      .where((t) => t.length >= 3)
      .toList();

  if (tokens.isEmpty) {
    return <Product>[];
  }

  final byId = <String, Product>{};
  for (final token in tokens) {
    final tokenResponse = await supabase
        .from('products')
        .select('id, shop_id, name, price, stock_quantity, category')
        .ilike('name', '%$token%');

    for (final row in (tokenResponse as List<dynamic>)) {
      final product = _productFromRow(row as Map);
      byId[product.id] = product;
    }
  }

  return byId.values.toList();
}

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

final checkInventoryTool = ai.defineTool<Map<String, dynamic>, List<Product>>(
  name: 'checkInventory',
  description: 'Find inventory items that match a product name fragment.',
  inputSchema: checkInventoryInputSchema,
  fn: (input, context) async {
    final query = (input['productName'] as String?) ?? '';
    return findInventoryProducts(query);
  },
);

final checkInventory = checkInventoryTool;

final SchemanticType<Map<String, dynamic>> browseCatalogInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'category': {'type': 'string'},
    },
    'additionalProperties': false,
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

final browseCatalogTool =
    ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
  name: 'browseCatalogTool',
  description:
      "Use this ONLY when the user asks for a list of available products, 'what do you sell?', or wants to see items in a category.",
  inputSchema: browseCatalogInputSchema,
  fn: (input, context) async {
    final category = (input['category'] as String?)?.trim();
    final query = supabase
        .from('products')
        .select('id, shop_id, name, price, stock_quantity, category');

    final rows = (category != null && category.isNotEmpty)
        ? await query.eq('category', category).limit(20)
        : await query.limit(20);

    final products = (rows as List<dynamic>)
        .map((row) => _productFromRow(row as Map))
        .toList();

    if (products.isEmpty) {
      return {
        'message': 'Our catalog is currently being updated.',
        'items': <Map<String, dynamic>>[],
      };
    }

    return {
      'message': 'Catalog items',
      'items': products.map((p) => p.toJson()).toList(),
    };
  },
);

final browseCatalog = browseCatalogTool;
