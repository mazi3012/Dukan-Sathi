import 'package:schemantic/schemantic.dart';
import 'package:uuid/uuid.dart';

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
    'description': data['description']?.toString(),
    'is_service': data['is_service'] as bool? ?? false,
    'gst_rate': (data['gst_rate'] as num?)?.toDouble() ?? 0.0,
    'hsn_sac_code': data['hsn_sac_code']?.toString(),
    'cost_price': (data['cost_price'] as num?)?.toDouble() ?? 0.0,
    'metadata': data['metadata'] as Map<String, dynamic>? ?? {},
  });
}

Future<List<Product>> findInventoryProducts(String rawQuery, [String? shopId]) async {
  final query = rawQuery.trim();
  if (query.isEmpty) {
    return <Product>[];
  }

  var select = supabase
      .from('products')
      .select('id, shop_id, name, price, stock_quantity, category, cost_price')
      .ilike('name', '%$query%');

  if (shopId != null) {
    select = select.eq('shop_id', shopId);
  }

  final response = await select;

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
    var tokenSelect = supabase
        .from('products')
        .select('id, shop_id, name, price, stock_quantity, category, cost_price')
        .ilike('name', '%$token%');

    if (shopId != null) {
      tokenSelect = tokenSelect.eq('shop_id', shopId);
    }

    final tokenResponse = await tokenSelect;

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
    final shopId = await getShopIdForUser(context.context?['userIdentifier'] as String?);
    return findInventoryProducts(query, shopId);
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
    final shopId = await getShopIdForUser(context.context?['userIdentifier'] as String?);
    
    var query = supabase
        .from('products')
        .select('id, shop_id, name, price, stock_quantity, category, cost_price')
        .eq('shop_id', shopId);

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

final SchemanticType<Map<String, dynamic>> proposeProductsInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'products': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'price': {'type': 'number'},
            'stock_quantity': {'type': 'integer', 'default': 0},
            'category': {'type': 'string'},
            'description': {'type': 'string'},
            'is_service': {'type': 'boolean', 'default': false},
            'gst_rate': {'type': 'number', 'default': 0},
            'hsn_sac_code': {'type': 'string'},
            'cost_price': {'type': 'number'},
            'metadata': {'type': 'object'},
          },
          'required': ['name', 'price', 'category'],
        },
      },
    },
    'required': ['products'],
    'additionalProperties': false,
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

final proposeProductsTool =
    ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
  name: 'proposeProducts',
  description:
      'Propose one or more products or services to be added to the inventory. This creates a draft that REQUIRES human approval.',
  inputSchema: proposeProductsInputSchema,
  fn: (input, context) async {
    final products = (input['products'] as List<dynamic>)
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();

    final shopId = await getShopIdForUser(context.context?['userIdentifier'] as String?);

    final response = await supabase.from('draft_product_batches').insert({
      'shop_id': shopId,
      'proposed_products': products,
      'status': 'PENDING',
    }).select('id').single();

    return {
      'message':
          'Product draft created. Human approval is required to finalize.',
      'batchId': response['id'],
      'itemCount': products.length,
    };
  },
);

final proposeProducts = proposeProductsTool;

Future<Map<String, dynamic>> createProductBatchRequest({
  required String userIdentifier,
  required List<Map<String, dynamic>> products,
}) async {
  if (products.isEmpty) {
    return {
      'success': false,
      'message': 'No products were provided.',
    };
  }

  final shopId = await getShopIdForUser(userIdentifier);
  final response = await supabase.from('draft_product_batches').insert({
    'shop_id': shopId,
    'proposed_products': products,
    'status': 'PENDING',
  }).select('id').single();

  return {
    'success': true,
    'batchId': response['id'],
    'itemCount': products.length,
    'products': products,
  };
}

Future<Map<String, dynamic>> createProductDeletionRequest({
  required String userIdentifier,
  required String rawQuery,
  String? reason,
}) async {
  final normalizedQuery = rawQuery.toLowerCase().trim();
  final shopId = await getShopIdForUser(userIdentifier);

  final listQuery = normalizedQuery.contains('last item') ||
          normalizedQuery.contains('last one') ||
          normalizedQuery.contains('first item') ||
          normalizedQuery.contains('first one') ||
          normalizedQuery.contains('1st one')
      ? await supabase
          .from('products')
          .select('id, shop_id, name, price, stock_quantity, category, cost_price')
          .eq('shop_id', shopId)
          .limit(50)
      : null;

  final matches = listQuery == null
      ? await findInventoryProducts(rawQuery, shopId)
      : (listQuery as List<dynamic>).map((row) => _productFromRow(row as Map)).toList();

  if (matches.isEmpty) {
    return {
      'success': false,
      'message': 'No products matched "$rawQuery".',
    };
  }

  final selectedProducts = normalizedQuery.contains('last item') ||
          normalizedQuery.contains('last one')
      ? [matches.last]
      : normalizedQuery.contains('first item') ||
              normalizedQuery.contains('first one') ||
              normalizedQuery.contains('1st one')
          ? [matches.first]
          : matches.length > 1 && matches.first.name.toLowerCase() != rawQuery.toLowerCase()
              ? [matches.first]
              : matches;

  final requestId = const Uuid().v4();
  final payload = selectedProducts.map((product) {
    return {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'stock_quantity': product.stockQuantity,
      'category': product.category,
      'cost_price': product.costPrice,
    };
  }).toList();

  await supabase.from('draft_product_deletions').insert({
    'id': requestId,
    'shop_id': shopId,
    'requested_by': userIdentifier,
    'products': payload,
    'reason': reason,
    'status': 'PENDING',
  });

  return {
    'success': true,
    'requestId': requestId,
    'productName': payload.first['name']?.toString() ?? rawQuery,
    'itemCount': payload.length,
    'products': payload,
  };
}

final SchemanticType<Map<String, dynamic>> requestProductDeletionInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'productName': {'type': 'string'},
      'product_name': {'type': 'string'},
      'reason': {'type': 'string'},
    },
    'required': ['productName'],
    'additionalProperties': false,
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

final requestProductDeletionTool =
    ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
  name: 'deleteProduct',
  description:
      'Create a human-approval request before deleting one or more products from inventory.',
  inputSchema: requestProductDeletionInputSchema,
  fn: (input, context) async {
    final rawName = ((input['productName'] as String?) ?? (input['product_name'] as String?))?.trim() ?? '';
    final reason = (input['reason'] as String?)?.trim();
    if (rawName.isEmpty) {
      return {
        'success': false,
        'message': 'Product name is required.',
      };
    }

    final result = await createProductDeletionRequest(
      userIdentifier: context.context?['userIdentifier']?.toString() ?? '',
      rawQuery: rawName,
      reason: reason,
    );

    if (result['success'] != true) {
      return result;
    }

    return {
      'success': true,
      'message': '''🗑 *Product Deletion Request Created*

Delete Request ID: ${result['requestId']}
Items: ${result['itemCount']}

Human approval is required before any product is removed.''',
      'requestId': result['requestId'],
      'itemCount': result['itemCount'],
      'products': result['products'],
    };
  },
);

final requestProductDeletion = requestProductDeletionTool;
