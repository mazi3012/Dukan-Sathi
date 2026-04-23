import 'dart:io';
import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:dukansathi_new/models/product.dart';
import 'package:dukansathi_new/services/approval_formatter.dart';
import 'package:dukansathi_new/services/invoice_pdf_generator.dart';
import 'package:dukansathi_new/tools/analytics_tools.dart';
import 'package:dukansathi_new/tools/approval_tools.dart';
import 'package:dukansathi_new/flows/onboarding_flow.dart';
import 'package:dukansathi_new/tools/billing_tools.dart';
import 'package:dukansathi_new/core/database.dart';
import 'package:dukansathi_new/models/draft_approval.dart';
import 'package:dukansathi_new/tools/inventory_tools.dart';
import 'package:genkit/genkit.dart';
import 'package:teledart/teledart.dart' as tg;
import 'package:teledart/model.dart' as tg;

final Map<int, Chat> activeSessions = {};

// Track pending rejection flows: chatId -> approvalId
final Map<int, String> pendingRejections = {};
// Track pending image import confirmation: chatId -> telegram file URL
final Map<int, String> pendingImageImports = {};

const String _systemPrompt =
  "You are the AI brain for Dukan Sathi Pro, a retail shop assistant. CRITICAL RULES: "
  "1. NEVER make up, guess, or hallucinate product names, prices, stock, or any data. ONLY use real data from tool responses. "
  "2. If inventory/catalog is empty, say so plainly — never invent sample products. "
  "3. No narration (never say 'I am checking' or 'Let me look up'). Use tools silently, output final result only. "
  "4. If you create a draft invoice, ALWAYS include the Approval ID in the format 'Approval ID: [ID]'. "
  "5. If you propose adding products, ALWAYS include the Batch ID in the format 'Batch ID: [ID]'. "
  "6. customerId and customerState are OPTIONAL — do NOT ask for them; call the tool immediately. "
  "7. For specific product lookups, use checkInventory. For full product lists, use browseCatalogTool. "
  "8. For business analytics (revenue, orders, approval status), use businessInsightsTool. Available metrics: total_revenue, total_orders, approved_count, pending_count, rejected_count, average_order_value, approval_rate. "
  "9. Present analytics in clear format: 'Total Revenue: ₹X | Orders: Y | Approved: Z | Pending: W | Rejected: V'. "
  "10. For product deletion, use deleteProduct and always include 'Delete Request ID: [ID]' in the response so Telegram can show approval buttons.";

final checkInventoryTool = checkInventory;
final catalogTool = browseCatalog;
final createDraftInvoiceTool = createDraftInvoice;
final analyticsTool = businessInsightsTool;
final proposeProductsTool = proposeProducts;
final requestProductDeletionTool = requestProductDeletion;

// ─── HELPER: check if user has already completed onboarding ────────────────
Future<bool> _isUserOnboarded(String userIdentifier) async {
  try {
    await supabase
        .from('shops')
        .select('id')
        .eq('created_by', userIdentifier)
        .eq('onboarding_completed', true)
        .single();
    return true;
  } catch (e) {
    // No onboarded shop found for this user
    return false;
  }
}

// ─── HELPER: build invoice keyboard ───────────────────────────────────────────
tg.InlineKeyboardMarkup _buildInvoiceKeyboard(String approvalId, String currentGstType, bool isRegistered) {
  final List<tg.InlineKeyboardButton> row1 = [];

  // For registered shops: show GST switch button
  if (isRegistered) {
    if (currentGstType == 'IGST') {
      row1.add(tg.InlineKeyboardButton(
        text: '🔄 Switch to CGST/SGST',
        callbackData: 'gst_cgst_$approvalId',
      ));
    } else {
      row1.add(tg.InlineKeyboardButton(
        text: '🔄 Switch to IGST',
        callbackData: 'gst_igst_$approvalId',
      ));
    }
  }

  final List<tg.InlineKeyboardButton> row2 = [
    tg.InlineKeyboardButton(text: '❌ REJECT', callbackData: 'reject_$approvalId'),
    tg.InlineKeyboardButton(text: '✅ APPROVE', callbackData: 'approve_$approvalId'),
  ];

  return tg.InlineKeyboardMarkup(
    inlineKeyboard: isRegistered ? [row1, row2] : [row2],
  );
}

// ─── HELPER: build formatted invoice message from DB ─────────────────────────
Future<String> _buildInvoiceMessage(
  Map<String, dynamic> draftData,
  String customerName,
) async {
  final approval = DraftApproval.fromJson(draftData);
  final itemDescriptions = <String>[];
  for (final item in approval.proposedItems) {
    try {
      final pRes = await supabase
          .from('products')
          .select('name')
          .eq('id', item.productId)
          .single();
      final pName = (pRes as Map)['name'] as String? ?? item.productId;
      itemDescriptions.add('${ item.quantity}x $pName @ ₹${item.unitPrice.toStringAsFixed(2)}');
    } catch (_) {
      itemDescriptions.add('${item.quantity}x ${item.productId}');
    }
  }
  return ApprovalFormatter.formatApprovalMessage(
    approval: approval,
    customerName: customerName,
    itemDescriptions: itemDescriptions,
  );
}

Future<Map<String, dynamic>?> _getLatestPendingProductDeletionForShop(
  String userIdentifier,
) async {
  try {
    final shopId = await getShopIdForUser(userIdentifier);
    final rows = await supabase
        .from('draft_product_deletions')
        .select()
        .eq('shop_id', shopId)
        .eq('status', 'PENDING')
        .order('requested_at', ascending: false)
        .limit(1);

    final items = rows as List<dynamic>;
    if (items.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(items.first as Map);
  } catch (_) {
    return null;
  }
}

String _buildProductDeletionMessage(Map<String, dynamic> requestData) {
  final products = (requestData['products'] as List<dynamic>? ?? const [])
      .map((product) => Map<String, dynamic>.from(product as Map))
      .toList();
  final rawProductName = (requestData['productName']?.toString().isNotEmpty ?? false)
    ? requestData['productName'].toString()
    : products.isNotEmpty
      ? (products.first['name']?.toString() ?? 'product')
      : 'product';
  final normalizedProductName = _normalizeDeletionProductName(rawProductName);
  final displayRequestId = _buildDeletionDisplayRequestId(rawProductName, requestData['requestId']?.toString() ?? requestData['id']?.toString() ?? '');
  final note = products.length == 1
      ? 'Note: This product will be permanently deleted if you press DELETE.'
      : 'Note: These products will be permanently deleted if you press DELETE.';
  final itemSummary = products.isEmpty
      ? '• No matching products found'
      : products
          .map((product) {
            final name = product['name']?.toString() ?? 'Unnamed product';
            final price = product['price'] is num
                ? (product['price'] as num).toStringAsFixed(0)
                : product['price']?.toString() ?? '-';
            final stock = product['stock_quantity']?.toString() ?? '-';
            return '• $name | Price: ₹$price | Stock: $stock';
          })
          .join('\n');

  return '''🗑 *Product Deletion Draft*

Action: deleteProduct
Target: $normalizedProductName

$itemSummary

Delete Request ID: $displayRequestId

$note''';
}

String _normalizeDeletionProductName(String rawName) {
  final lower = rawName.toLowerCase().trim();
  final withoutSizes = lower
      .replaceAll(RegExp(r'\b\d+(?:\.\d+)?\s*(kg|g|mg|ml|l|pcs|pc|pack|packet)\b'), '')
      .replaceAll(RegExp(r'\b\d+(?:\.\d+)?\b'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final words = withoutSizes
      .split(' ')
      .where((word) => word.isNotEmpty)
      .where((word) => !{'organic', 'packaged', 'pure', 'fresh', 'natural', 'premium'}.contains(word))
      .toList();

  if (words.isEmpty) {
    return lower;
  }

  return words.join(' ');
}

String _buildDeletionDisplayRequestId(String rawName, String requestId) {
  final normalized = _normalizeDeletionProductName(rawName);
  final initials = normalized
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase())
      .join();
  final shortHash = requestId.hashCode.abs().toString().padLeft(4, '0').substring(0, 4);
  return 'DEL-${initials.isEmpty ? 'XX' : initials}-$shortHash';
}

bool _looksLikeBulkAddRequest(String input) {
  final n = input.toLowerCase();
  final hasAddIntent = n.contains('add product') || n.contains('add products') ||
      n.contains('bulk add') || n.contains('new product') ||
      n.contains('new products') || n.contains('create product') ||
      n.contains('create products') || n.contains('upload');
  final hasListMarkers = input.contains('\n') || input.contains('|') || input.contains(',');
  return hasAddIntent && hasListMarkers;
}

List<Map<String, dynamic>> _parseBulkProductDraft(String text) {
  final products = <Map<String, dynamic>>[];
  final lines = text.split(RegExp(r'\r?\n'));

  for (final rawLine in lines) {
    var line = rawLine.trim();
    if (line.isEmpty) continue;

    line = line.replaceFirst(RegExp(r'^[\-\*\d\s\.)\]]+'), '');
    if (!line.contains('|') && !line.contains(',')) {
      continue;
    }

    final parts = line.contains('|')
        ? line.split('|').map((part) => part.trim()).where((part) => part.isNotEmpty).toList()
        : line.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

    if (parts.length < 3) continue;

    final name = parts[0];
    final priceText = parts[1].replaceAll(RegExp(r'[^0-9.]'), '');
    final price = double.tryParse(priceText);
    final category = parts[2];
    final stockText = parts.length >= 4 ? parts[3].replaceAll(RegExp(r'[^0-9]'), '') : '0';
    final stock = int.tryParse(stockText) ?? 0;
    final description = parts.length >= 5 ? parts.sublist(4).join(' | ') : null;

    if (name.isEmpty || price == null || category.isEmpty) continue;

    products.add({
      'name': name,
      'price': price,
      'stock_quantity': stock,
      'category': category,
      if (description != null && description.isNotEmpty) 'description': description,
      'is_service': false,
      'gst_rate': 0,
      'metadata': {},
    });
  }

  return products;
}

String _buildProductBatchMessage(String batchId, List<Map<String, dynamic>> products) {
  final itemLines = products.take(10).map((product) {
    final name = product['name']?.toString() ?? 'Unnamed product';
    final price = product['price'] is num ? (product['price'] as num).toStringAsFixed(0) : product['price']?.toString() ?? '-';
    final stock = product['stock_quantity']?.toString() ?? '0';
    final category = product['category']?.toString() ?? '-';
    return '• $name | ₹$price | $category | Stock: $stock';
  }).join('\n');

  return '''📦 *Product Draft Created*

$itemLines

Batch ID: $batchId

Human approval is required before these products are added to inventory.''';
}

bool _isYesReply(String input) {
  final n = input.toLowerCase().trim();
  return n == 'yes' || n == 'y' || n == 'haan' || n == 'ha' ||
      n == 'ok' || n == 'okay' || n == 'confirm' || n == 'approve';
}

bool _isNoReply(String input) {
  final n = input.toLowerCase().trim();
  return n == 'no' || n == 'n' || n == 'cancel' || n == 'stop' || n == 'skip';
}

Map<String, dynamic>? _tryParseJsonObject(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {}

  final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false).firstMatch(raw);
  if (fenceMatch != null) {
    final inside = fenceMatch.group(1)?.trim();
    if (inside != null && inside.isNotEmpty) {
      try {
        final decoded = jsonDecode(inside);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
  }

  return null;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
  return null;
}

Future<List<Map<String, dynamic>>> _extractProductsFromImageUrl(String imageUrl) async {
  final response = await ai.generate(
    model: appModel(),
    messages: [
      Message(
        role: Role.user,
        content: [
          TextPart(
            text:
                'Extract product rows from this image. Return ONLY a strict JSON object with key "products" as an array. '
                'Each product must include: name (string), price (number), category (string), stock_quantity (integer). '
                'Optional fields: description, gst_rate, hsn_sac_code. '
                'If stock is not visible, set stock_quantity to 0. If category is unknown, set category to "General".',
          ),
          MediaPart(media: Media(contentType: 'image/jpeg', url: imageUrl)),
        ],
      ),
    ],
  );

  final text = response.text.trim();
  final parsed = _tryParseJsonObject(text);
  if (parsed == null) {
    return [];
  }

  final rows = (parsed['products'] as List<dynamic>? ?? const [])
      .map((row) => Map<String, dynamic>.from(row as Map))
      .map((row) {
        final price = _asDouble(row['price']);
        final name = row['name']?.toString().trim();
        final category = row['category']?.toString().trim();
        if (name == null || name.isEmpty || price == null || category == null || category.isEmpty) {
          return <String, dynamic>{};
        }
        return {
          'name': name,
          'price': price,
          'category': category,
          'stock_quantity': _asInt(row['stock_quantity']) ?? 0,
          if ((row['description']?.toString().trim().isNotEmpty ?? false)) 'description': row['description'].toString().trim(),
          'is_service': false,
          'gst_rate': _asDouble(row['gst_rate']) ?? 0,
          if ((row['hsn_sac_code']?.toString().trim().isNotEmpty ?? false)) 'hsn_sac_code': row['hsn_sac_code'].toString().trim(),
          'metadata': {},
        };
      })
      .where((row) => row.isNotEmpty)
      .toList();

  return rows;
}

bool _looksLikeDeleteRequest(String input) {
  final n = input.toLowerCase();
  return n.contains('delete') || n.contains('remove') ||
      n.contains('archive') || n.contains('discard') ||
      n.contains('delete the last item') || n.contains('delete the last one') ||
      n.contains('delete the first item') || n.contains('delete the first one') ||
      n.contains('delete the 1st one') || n.contains('delete it') ||
      n.contains('remove the last item') || n.contains('remove the last one') ||
      n.contains('remove the first item') || n.contains('remove the first one');
}

// ─── CHAT SESSION ─────────────────────────────────────────────────────────────
class Chat {
  Chat({required this.model, required this.tools, required this.systemPrompt, required this.userIdentifier});

  final String model;
  final List<String> tools;
  final String systemPrompt;
  final String userIdentifier;
  final List<Message> _history = [];

  bool _isBillingIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('bill') || n.contains('invoice') || n.contains('draft') || n.contains('बिल');
  }

  bool _isCatalogIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('what do you sell') || n.contains('what do we sell') ||
        n.contains('what item') || n.contains('what items') ||
        n.contains('catalog') || n.contains('list product') || n.contains('show product') ||
        n.contains('show item') || n.contains('available product') ||
        n.contains('what do you have') || n.contains('what do we have') ||
        n.contains('items do you have') || n.contains('items do we have') ||
        n.contains('show my product') || n.contains('view product') ||
        n.contains('our product') || n.contains('our inventory') ||
        n.contains('list inventory') || n.contains('see inventory') ||
        n.contains('show inventory');
  }

  bool _isInventoryIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('stock') || n.contains('inventory') || n.contains('price') ||
        n.contains('how many') || n.contains('quantity') || n.contains('left') ||
        n.contains('available') || n.contains('have');
  }

  bool _isAnalyticsIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('total sales') || n.contains('revenue') || n.contains('analytics') ||
        n.contains('insight') || n.contains('how much did') || n.contains('profit') ||
        n.contains('profit margin') || n.contains('earnings') || n.contains('total earnings') ||
        n.contains('how many orders') || n.contains('order count') || n.contains('approval') ||
        n.contains('pending') || n.contains('rejected') || n.contains('approved') ||
        n.contains('average order') || n.contains('approval rate');
  }

  bool _isAddProductIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('add product') || n.contains('add item') || n.contains('new product') ||
        n.contains('new item') || n.contains('create product') || n.contains('add service') ||
        n.contains('add these') || n.contains('bulk add') || n.contains('upload');
  }

  bool _isDeleteProductIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('delete product') || n.contains('remove product') ||
        n.contains('delete item') || n.contains('remove item') ||
        n.contains('delete this product') || n.contains('remove this product') ||
        n.contains('archive product') || n.contains('discard product');
  }

  String _extractInventoryQuery(String input) {
    var n = input.toLowerCase();
    final noise = ['what is the price of', 'price of', 'how many', 'do we have',
      'we have', 'in stock', 'stock of', 'quantity of', 'available', 'please'];
    for (final p in noise) { n = n.replaceAll(p, ' '); }
    n = n.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return n;
  }

  String? _extractCategory(String input) {
    final n = input.toLowerCase();
    for (final c in ['staples', 'snacks', 'beverages', 'dairy']) {
      if (n.contains(c)) { return c[0].toUpperCase() + c.substring(1); }
    }
    return null;
  }

  String _formatPrice(double p) => p == p.roundToDouble() ? p.toInt().toString() : p.toStringAsFixed(2);

  String _formatInventoryReply(List<Product> products) {
    if (products.isEmpty) return 'Not in inventory.';
    if (products.length == 1) {
      final p = products.first;
      return '${p.name}: ₹${_formatPrice(p.price)}, ${p.stockQuantity} units in stock.';
    }
    return products.take(5).map((p) => '${p.name}: ₹${_formatPrice(p.price)}, ${p.stockQuantity} units').join('\n');
  }

  String _formatCatalogReply(Map<String, dynamic> payload) {
    final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    if (items.isEmpty) {
      return '🏪 Your catalog is empty right now.\n\nTip: Say *"Add product: [name], price [X], category [Y]"* to add your first product!';
    }
    final header = '📦 *Your Products (${items.length}):*\n\n';
    final lines = items.take(20).map((p) =>
      '• *${p.name}* — ₹${_formatPrice(p.price)} (${p.stockQuantity} in stock)'
    ).join('\n');
    return header + lines;
  }

  Map<String, int> _parseBillingRequestedItems(String input) {
    var text = input.toLowerCase().trim();
    text = text
        .replaceAll(RegExp(r'^(please\s+)?(make|create|generate)\s+(a\s+)?(bill|invoice)\s*(for|with)?\s*'), '')
        .replaceAll(RegExp(r'\.$'), '')
        .trim();

    if (text.isEmpty) {
      return {};
    }

    final parts = text
        .split(RegExp(r'\s*(?:,| and )\s*'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final requested = <String, int>{};

    for (final part in parts) {
      final qtyFirst = RegExp(r'^(\d+)\s*x?\s+(.+)$').firstMatch(part);
      final qtyLast = RegExp(r'^(.+?)\s*x\s*(\d+)$').firstMatch(part);

      String? name;
      int? qty;

      if (qtyFirst != null) {
        qty = int.tryParse(qtyFirst.group(1)!);
        name = qtyFirst.group(2)?.trim();
      } else if (qtyLast != null) {
        qty = int.tryParse(qtyLast.group(2)!);
        name = qtyLast.group(1)?.trim();
      }

      if (qty == null || qty <= 0 || name == null || name.isEmpty) {
        continue;
      }

      name = name
          .replaceAll(RegExp(r'\b(of|item|items|product|products)\b'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (name.isEmpty) {
        continue;
      }

      requested[name] = (requested[name] ?? 0) + qty;
    }

    return requested;
  }

  Future<String> sendMessage(String? text) async {
    final input = (text ?? '').trim();
    if (input.isEmpty) return '';

    if (_isCatalogIntent(input)) {
      // Direct catalog lookup scoped to this user's shop (bypasses tool abstraction)
      try {
        final shopId = await getShopIdForUser(userIdentifier);
        final category = _extractCategory(input);
        var query = supabase
            .from('products')
            .select('id, shop_id, name, price, stock_quantity, category')
            .eq('shop_id', shopId);
        if (category != null) query = query.eq('category', category);
        final rows = await query.limit(20);
        final products = (rows as List<dynamic>)
            .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList();
        final reply = _formatCatalogReply({'items': products.map((p) => p.toJson()).toList()});
        _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
        _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
        return reply;
      } catch (e) {
        return '⚠️ Could not load catalog: $e';
      }
    }

    if (_isInventoryIntent(input) && !_isBillingIntent(input) && !_isAddProductIntent(input)) {
      final query = _extractInventoryQuery(input);
      final products = await findInventoryProducts(query.isEmpty ? input : query);
      final reply = _formatInventoryReply(products);
      _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
      _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
      return reply;
    }

    if (_isBillingIntent(input)) {
      final requestedItems = _parseBillingRequestedItems(input);
      if (requestedItems.isNotEmpty) {
        try {
          final result = await createDraftInvoiceRequest(
            input: {'requestedItems': requestedItems},
            userIdentifier: userIdentifier,
          );
          final reply = (result['message'] as String?) ?? 'Draft invoice created.\n\nApproval ID: ${result['approvalId']}';
          _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
          _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
          return reply;
        } catch (e) {
          final reply = e.toString().replaceFirst('Bad state: ', '').trim();
          _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
          _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
          return reply;
        }
      }
    }

    _history.add(Message(role: Role.user, content: [TextPart(text: input)]));

    // Select tools based on intent
    List<String> selectedTools = [];
    if (_isBillingIntent(input)) {
      selectedTools = ['createDraftInvoice'];
    } else if (_isAnalyticsIntent(input)) {
      selectedTools = ['businessInsightsTool'];
    } else if (_isAddProductIntent(input)) {
      selectedTools = ['proposeProducts'];
    } else if (_isDeleteProductIntent(input)) {
      selectedTools = ['deleteProduct'];
    }

    Future<dynamic> runGenerate() => ai.generate(
      model: appModel(model),
      messages: [
        Message(role: Role.system, content: [TextPart(text: systemPrompt)]),
        ..._history,
      ],
      toolNames: selectedTools,
      context: {'userIdentifier': userIdentifier},
    );

    dynamic response;
    try {
      response = await runGenerate();
    } catch (e) {
      final err = e.toString();
      if (err.contains('Multiple tools') || err.contains('INVALID_ARGUMENT')) {
        response = await ai.generate(
          model: appModel(model),
          messages: [
            Message(role: Role.system, content: [TextPart(text: systemPrompt)]),
            ..._history,
          ],
          toolNames: <String>[],
          context: {'userIdentifier': userIdentifier},
        );
      } else {
        rethrow;
      }
    }

    final reply = response.text.trim();
    _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
    return reply;
  }
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
Future<void> main(List<String> arguments) async {
  final env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) env.load(['.env']);

  final modelId = Platform.environment['MODEL_ID'] ?? env['MODEL_ID'] ?? 'gemini-3.1-flash-lite-preview';
  final token = Platform.environment['TELEGRAM_BOT_TOKEN'] ?? env['TELEGRAM_BOT_TOKEN'];

  initializeBackend();

  if (token == null || token.isEmpty) throw StateError('TELEGRAM_BOT_TOKEN is not set.');

  final bot = tg.TeleDart(token, tg.Event(''));

  // ─── CALLBACK QUERY HANDLER ─────────────────────────────────────────────
  bot.onCallbackQuery().listen((query) async {
    final chatId = query.from.id;
    final data = query.data ?? '';
    final msgId = query.message!.messageId;

    // ── ONBOARDING CALLBACKS (all prefixed ob_) ─────────────────────────
    if (data.startsWith('ob_')) {
      await bot.answerCallbackQuery(query.id);
      try {
        final result = await processOnboardingCallback(chatId, data);
        if (result != null) {
          // Always send as a NEW message so subsequent text input is handled cleanly
          await bot.sendMessage(chatId, result.text,
              parseMode: 'Markdown', replyMarkup: result.keyboard);
        }
      } catch (e) {
        stderr.writeln('[onboarding-callback] $e');
        await bot.sendMessage(chatId, '⚠️ Something went wrong. Please try again.');
      }
      return;
    }

    // ── APPROVE ──────────────────────────────────────────────────────────
    if (data.startsWith('approve_')) {
      final approvalId = data.replaceFirst('approve_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Processing...');
      try {
        final result = await approveDraftInvoice(approvalId: approvalId, reviewedBy: chatId.toString());
        if (result['success'] == true) {
          try {
            final pdf = await InvoicePdfGenerator.generateApprovedInvoicePdf(
              approvalId: approvalId,
              invoiceNumber: result['invoiceNumber'] as String,
            );
            await bot.sendDocument(
              chatId,
              pdf.file,
              caption: pdf.caption,
            );
          } catch (pdfError) {
            stderr.writeln('Error generating/sending invoice PDF: $pdfError');
            await bot.sendMessage(
              chatId,
              'Invoice was approved and saved, but the PDF could not be generated right now.',
            );
          }
          await bot.editMessageText(
            '${result['message'] as String}\n\n📄 PDF invoice sent.',
            chatId: chatId,
            messageId: msgId,
            parseMode: 'Markdown',
          );
        } else {
          await bot.answerCallbackQuery(query.id, text: '❌ ${result['error']}', showAlert: true);
        }
      } catch (e) {
        stderr.writeln('Error approving: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to approve. Try again.', showAlert: true);
      }

    // ── REJECT ──────────────────────────────────────────────────────────
    } else if (data.startsWith('reject_')) {
      final approvalId = data.replaceFirst('reject_', '');
      pendingRejections[chatId] = approvalId;
      await bot.editMessageText(
        '❌ *Rejection*\n\nPlease type the reason for rejecting this invoice:',
        chatId: chatId,
        messageId: msgId,
        parseMode: 'Markdown',
      );
      await bot.answerCallbackQuery(query.id);

    // ── SWITCH TO IGST ──────────────────────────────────────────────────
    } else if (data.startsWith('gst_igst_')) {
      final approvalId = data.replaceFirst('gst_igst_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Switching to IGST...');
      try {
        final result = await switchGstType(approvalId: approvalId, newGstType: 'IGST');
        if (result['success'] == true) {
          final draftData = await getApprovalDetails(approvalId);
          if (draftData != null) {
            final msg = await _buildInvoiceMessage(draftData, query.from.firstName);
            await bot.editMessageText(msg, chatId: chatId, messageId: msgId,
              parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, 'IGST', true));
          }
        }
      } catch (e) {
        stderr.writeln('Error switching to IGST: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to switch. Try again.', showAlert: true);
      }

    // ── SWITCH TO CGST/SGST ─────────────────────────────────────────────
    } else if (data.startsWith('gst_cgst_')) {
      final approvalId = data.replaceFirst('gst_cgst_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Switching to CGST/SGST...');
      try {
        final result = await switchGstType(approvalId: approvalId, newGstType: 'CGST_SGST');
        if (result['success'] == true) {
          final draftData = await getApprovalDetails(approvalId);
          if (draftData != null) {
            final msg = await _buildInvoiceMessage(draftData, query.from.firstName);
            await bot.editMessageText(msg, chatId: chatId, messageId: msgId,
              parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, 'CGST_SGST', true));
          }
        }
      } catch (e) {
        stderr.writeln('Error switching to CGST/SGST: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to switch. Try again.', showAlert: true);
      }

    // ── APPROVE PRODUCT BATCH ──────────────────────────────────────────
    } else if (data.startsWith('p_approve_')) {
      final batchId = data.replaceFirst('p_approve_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Adding to inventory...');
      try {
        final result = await approveProductBatch(batchId: batchId, reviewedBy: chatId.toString());
        if (result['success'] == true) {
          await bot.editMessageText(
            result['message'] as String,
            chatId: chatId,
            messageId: msgId,
            parseMode: 'Markdown',
          );
        } else {
          await bot.answerCallbackQuery(query.id, text: '❌ ${result['error']}', showAlert: true);
        }
      } catch (e) {
        stderr.writeln('Error approving batch: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to approve. Try again.', showAlert: true);
      }

    // ── REJECT PRODUCT BATCH ──────────────────────────────────────────
    } else if (data.startsWith('p_reject_')) {
      final batchId = data.replaceFirst('p_reject_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Rejecting...');
      try {
        final result = await rejectProductBatch(batchId: batchId, reviewedBy: chatId.toString());
        if (result['success'] == true) {
          await bot.editMessageText(
            result['message'] as String,
            chatId: chatId,
            messageId: msgId,
            parseMode: 'Markdown',
          );
        } else {
          await bot.answerCallbackQuery(query.id, text: '❌ ${result['error']}', showAlert: true);
        }
      } catch (e) {
        stderr.writeln('Error rejecting batch: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to reject. Try again.', showAlert: true);
      }

    // ── APPROVE PRODUCT DELETION ─────────────────────────────────────
    } else if (data.startsWith('d_approve_')) {
      final requestId = data.replaceFirst('d_approve_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Deleting products...');
      try {
        final result = await approveProductDeletion(requestId: requestId, reviewedBy: chatId.toString());
        if (result['success'] == true) {
          await bot.editMessageText(
            result['message'] as String,
            chatId: chatId,
            messageId: msgId,
            parseMode: 'Markdown',
          );
        } else {
          await bot.answerCallbackQuery(query.id, text: '❌ ${result['error']}', showAlert: true);
        }
      } catch (e) {
        stderr.writeln('Error approving product deletion: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to delete. Try again.', showAlert: true);
      }

    // ── REJECT PRODUCT DELETION ──────────────────────────────────────
    } else if (data.startsWith('d_reject_')) {
      final requestId = data.replaceFirst('d_reject_', '');
      pendingRejections[chatId] = 'delete:$requestId';
      await bot.editMessageText(
        '''❌ *Deletion Rejection*

      Please type the reason for rejecting this product deletion request:''',
        chatId: chatId,
        messageId: msgId,
        parseMode: 'Markdown',
      );
      await bot.answerCallbackQuery(query.id);
    }
  });

  // ─── MESSAGE HANDLER ────────────────────────────────────────────────────
  bot.onMessage().listen((message) async {
    print('Incoming message from ${message.chat.id}: ${message.text}');
    final text = message.text?.trim();
    final caption = message.caption?.trim();

    final chatId = message.chat.id;
    final customerName = message.from?.firstName ?? 'Customer';
    final userIdentifier = message.from?.username ?? message.from?.firstName ?? chatId.toString();

    // ── Image-only intake for inventory import ─────────────────────────
    if ((message.photo?.isNotEmpty ?? false)) {
      try {
        final bestPhoto = (message.photo!..sort((a, b) => (a.fileSize ?? 0).compareTo(b.fileSize ?? 0))).last;
        final tgFile = await bot.getFile(bestPhoto.fileId);
        final filePath = tgFile.filePath;

        if (filePath == null || filePath.isEmpty) {
          await bot.sendMessage(chatId, 'I could not read that image. Please try sending it again.');
          return;
        }

        final imageUrl = 'https://api.telegram.org/file/bot$token/$filePath';
        pendingImageImports[chatId] = imageUrl;

        if (caption != null && caption.isNotEmpty && _looksLikeBulkAddRequest(caption)) {
          final products = _parseBulkProductDraft(caption);
          if (products.isNotEmpty) {
            final draft = await createProductBatchRequest(
              userIdentifier: userIdentifier,
              products: products,
            );
            if (draft['success'] == true) {
              final batchId = draft['batchId']?.toString() ?? '';
              final msg = _buildProductBatchMessage(batchId, products);
              await bot.sendMessage(
                chatId,
                msg,
                parseMode: 'Markdown',
                replyMarkup: tg.InlineKeyboardMarkup(
                  inlineKeyboard: [
                    [
                      tg.InlineKeyboardButton(text: '❌ REJECT', callbackData: 'p_reject_$batchId'),
                      tg.InlineKeyboardButton(text: '✅ APPROVE', callbackData: 'p_approve_$batchId'),
                    ]
                  ],
                ),
              );
              pendingImageImports.remove(chatId);
              return;
            }
          }
        }

        await bot.sendMessage(
          chatId,
          'I received the image. Do you want me to create an inventory draft from this image? Reply *YES* or *NO*.',
          parseMode: 'Markdown',
        );
      } catch (e) {
        stderr.writeln('Error handling image import: $e');
        await bot.sendMessage(chatId, 'Could not process the image right now. Please try again.');
      }
      return;
    }

    if (text == null || text.isEmpty) return;

    // ── Confirm image import flow ───────────────────────────────────────
    if (pendingImageImports.containsKey(chatId)) {
      if (_isNoReply(text)) {
        pendingImageImports.remove(chatId);
        await bot.sendMessage(chatId, 'Image import cancelled.');
        return;
      }

      if (_isYesReply(text)) {
        try {
          final imageUrl = pendingImageImports.remove(chatId)!;
          final products = await _extractProductsFromImageUrl(imageUrl);
          if (products.isEmpty) {
            await bot.sendMessage(
              chatId,
              'I could not extract products confidently from the image. Please send list text as:\nName | Price | Category | Stock',
            );
            return;
          }

          final draft = await createProductBatchRequest(
            userIdentifier: userIdentifier,
            products: products,
          );

          if (draft['success'] == true) {
            final batchId = draft['batchId']?.toString() ?? '';
            final msg = _buildProductBatchMessage(batchId, products);
            await bot.sendMessage(
              chatId,
              msg,
              parseMode: 'Markdown',
              replyMarkup: tg.InlineKeyboardMarkup(
                inlineKeyboard: [
                  [
                    tg.InlineKeyboardButton(text: '❌ REJECT', callbackData: 'p_reject_$batchId'),
                    tg.InlineKeyboardButton(text: '✅ APPROVE', callbackData: 'p_approve_$batchId'),
                  ]
                ],
              ),
            );
          } else {
            await bot.sendMessage(chatId, draft['message']?.toString() ?? 'Could not create product draft.');
          }
        } catch (e) {
          stderr.writeln('Error confirming image import: $e');
          await bot.sendMessage(chatId, 'Could not generate draft from the image. Please try again.');
        }
        return;
      }

      await bot.sendMessage(chatId, 'Please reply with *YES* to import the image, or *NO* to cancel.', parseMode: 'Markdown');
      return;
    }

    // ── /start command ──────────────────────────────────────────────
    if (text == '/start' || text.toLowerCase() == 'join') {
      try {
        final result = await startOnboarding(chatId, userIdentifier);
        await bot.sendMessage(chatId, result.text,
            parseMode: 'Markdown', replyMarkup: result.keyboard);
      } catch (e) {
        stderr.writeln('[onboarding-start] chat=$chatId error: $e');
        await bot.sendMessage(chatId, 'Could not start. Please try /start again.');
      }
      return;
    }

    // ── Active onboarding text steps ────────────────────────────────
    final inOnboarding = isInOnboarding(chatId);
    print('[bot] chat=$chatId isInOnboarding=$inOnboarding text="$text"');
    if (inOnboarding) {
      try {
        final result = await processOnboardingText(chatId, text);
        if (result.text.isNotEmpty) {
          await bot.sendMessage(chatId, result.text,
              parseMode: 'Markdown', replyMarkup: result.keyboard);
        }
      } catch (e) {
        stderr.writeln('[onboarding-text] chat=$chatId error: $e');
        await bot.sendMessage(chatId, 'Something went wrong. Send /start to restart.');
      }
      return;
    }

    // ── Auto-start onboarding for new users ─────────────────────────
    final isOnboarded = await _isUserOnboarded(userIdentifier);
    if (!isOnboarded) {
      try {
        final result = await startOnboarding(chatId, userIdentifier);
        await bot.sendMessage(chatId, result.text,
            parseMode: 'Markdown', replyMarkup: result.keyboard);
      } catch (e) {
        stderr.writeln('[onboarding-autostart] chat=$chatId error: $e');
        await bot.sendMessage(chatId, 'Could not start onboarding. Please send /start.');
      }
      return;
    }

    // ── Handle pending rejection reason ─────────────────────────────────
    if (pendingRejections.containsKey(chatId)) {
      final approvalId = pendingRejections.remove(chatId) ?? '';
      if (approvalId.isEmpty) return;
      try {
        if (approvalId.startsWith('delete:')) {
          final requestId = approvalId.replaceFirst('delete:', '');
          final result = await rejectProductDeletion(
            requestId: requestId,
            reviewedBy: chatId.toString(),
            rejectionReason: text,
          );
          if (result['success'] == true) {
            await bot.sendMessage(chatId, result['message'] as String, parseMode: 'Markdown');
          } else {
            await bot.sendMessage(chatId, 'Failed to reject. Try again.');
          }
        } else {
          final result = await rejectDraftInvoice(
            approvalId: approvalId,
            reviewedBy: chatId.toString(),
            rejectionReason: text,
          );
          if (result['success'] == true) {
            await bot.sendMessage(chatId, result['message'] as String, parseMode: 'Markdown');
          } else {
            await bot.sendMessage(chatId, 'Failed to reject. Try again.');
          }
        }
      } catch (e) {
        stderr.writeln('Error rejecting draft: $e');
        await bot.sendMessage(chatId, 'Error processing rejection.');
      }
      return;
    }

    // ── Direct delete draft creation ────────────────────────────────────
    if (_looksLikeDeleteRequest(text)) {
      try {
        final draft = await createProductDeletionRequest(
          userIdentifier: userIdentifier,
          rawQuery: text,
        );
        if (draft['success'] == true) {
          final requestId = draft['requestId']?.toString() ?? '';
          final msg = _buildProductDeletionMessage(draft);
          await bot.sendMessage(
            chatId,
            msg,
            parseMode: 'Markdown',
            replyMarkup: tg.InlineKeyboardMarkup(
              inlineKeyboard: [
                [
                  tg.InlineKeyboardButton(text: '🗑 DELETE', callbackData: 'd_approve_$requestId'),
                  tg.InlineKeyboardButton(text: '❌ CANCEL', callbackData: 'd_reject_$requestId'),
                ]
              ],
            ),
          );
        } else {
          await bot.sendMessage(chatId, draft['message']?.toString() ?? 'Could not create delete draft.');
        }
      } catch (e) {
        stderr.writeln('Error creating direct delete draft: $e');
        await bot.sendMessage(chatId, 'Could not create delete draft right now.');
      }
      return;
    }

    // ── Direct bulk product draft creation ─────────────────────────────
    if (_looksLikeBulkAddRequest(text)) {
      try {
        final products = _parseBulkProductDraft(text);
        if (products.isEmpty) {
          await bot.sendMessage(
            chatId,
            'I could not parse any products. Use one line per product like:\n1. Name | Price | Category | Stock',
          );
          return;
        }

        final draft = await createProductBatchRequest(
          userIdentifier: userIdentifier,
          products: products,
        );

        if (draft['success'] == true) {
          final batchId = draft['batchId']?.toString() ?? '';
          final msg = _buildProductBatchMessage(batchId, products);

          await bot.sendMessage(
            chatId,
            msg,
            parseMode: 'Markdown',
            replyMarkup: tg.InlineKeyboardMarkup(
              inlineKeyboard: [
                [
                  tg.InlineKeyboardButton(text: '❌ REJECT', callbackData: 'p_reject_$batchId'),
                  tg.InlineKeyboardButton(text: '✅ APPROVE', callbackData: 'p_approve_$batchId'),
                ]
              ],
            ),
          );
        } else {
          await bot.sendMessage(chatId, draft['message']?.toString() ?? 'Could not create product draft.');
        }
      } catch (e) {
        stderr.writeln('Error creating bulk product draft: $e');
        await bot.sendMessage(chatId, 'Could not create product draft right now.');
      }
      return;
    }

    // ── Normal AI flow ───────────────────────────────────────────────────
    final session = activeSessions.putIfAbsent(
      chatId,
      () => Chat(
        model: modelId,
        tools: [
          checkInventoryTool.name,
          catalogTool.name,
          createDraftInvoiceTool.name,
          analyticsTool.name,
          proposeProductsTool.name,
          requestProductDeletionTool.name,
        ],
        systemPrompt: _systemPrompt,
        userIdentifier: userIdentifier,
      ),
    );

    try {
      final reply = await session.sendMessage(message.text);
      print('AI Reply: $reply');

      // ── Check if approval was created ─────────────────────────────
      final approvalIdMatch = RegExp(
        r'Approval ID:\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
      ).firstMatch(reply);
      final approvalId = approvalIdMatch?.group(1);

      if (approvalId != null) {
        try {
          final draftData = await getApprovalDetails(approvalId);
          if (draftData != null) {
            // Determine if shop is registered (for IGST switch button)
            final shopId = draftData['shop_id'] as String;
            final shopRows = await supabase
                .from('shops')
                .select('gst_mode')
                .eq('id', shopId)
                .single();
            final gstMode = (shopRows as Map)['gst_mode'] as String? ?? 'REGISTERED';
            final isRegistered = gstMode == 'REGISTERED';

            final currentGstType = draftData['gst_type'] as String? ?? 'CGST_SGST';
            final formattedMessage = await _buildInvoiceMessage(draftData, customerName);

            await bot.sendMessage(
              chatId,
              formattedMessage,
              parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, currentGstType, isRegistered),
            );
          } else {
            await bot.sendMessage(chatId, reply);
          }
        } catch (e) {
          stderr.writeln('Error formatting invoice: $e');
          await bot.sendMessage(chatId, reply);
        }
      } else {
        // ── Check if product batch was created ─────────────────────────
        final batchIdMatch = RegExp(
          r'Batch ID:\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
        ).firstMatch(reply);
        final batchId = batchIdMatch?.group(1);

        if (batchId != null) {
          try {
            final batchData = await getProductBatchDetails(batchId);
            print('[bot] batchId=$batchId batchData=${batchData == null ? "NULL" : "FOUND"}');
            if (batchData != null) {
              final items = (batchData['proposed_products'] as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
              
              String summary = "";
              if (items.length == 1) {
                final p = items[0];
                summary = "🏷 *${p['name']}*\n"
                          "💰 Price: ₹${p['price']}\n"
                          "📦 Stock: ${p['stock_quantity'] ?? 0}\n"
                          "📂 Category: ${p['category']}\n";
                if (p['description'] != null) {
                  summary += "📝 Info: ${p['description']}\n";
                }
              } else {
                summary = "📋 *${items.length} Items Found:*\n\n";
                for (var i = 0; i < items.length; i++) {
                  final p = items[i];
                  summary += "${i + 1}. ${p['name']} (₹${p['price']}, ${p['stock_quantity'] ?? 0} pcs)\n";
                  if (i == 4 && items.length > 5) {
                    summary += "...and ${items.length - 5} more items.\n";
                    break;
                  }
                }
              }

              final msg = "📦 *Product Draft Created*\n\n"
                  "$summary\n"
                  "Do you want to add these to your inventory?";

              await bot.sendMessage(
                chatId,
                msg,
                parseMode: 'Markdown',
                replyMarkup: tg.InlineKeyboardMarkup(
                  inlineKeyboard: [
                    [
                      tg.InlineKeyboardButton(text: '❌ REJECT', callbackData: 'p_reject_$batchId'),
                      tg.InlineKeyboardButton(text: '✅ APPROVE', callbackData: 'p_approve_$batchId'),
                    ]
                  ],
                ),
              );
            } else {
              print('[bot] batchData null — sending raw reply: $reply');
              await bot.sendMessage(chatId, reply);
            }
          } catch (e) {
            stderr.writeln('Error formatting product batch: $e');
            await bot.sendMessage(chatId, reply);
          }
        } else {
          final looksLikeDeleteDraft =
              reply.contains('deleteProduct') ||
              reply.contains('Delete Request ID') ||
              reply.contains('requestId') ||
              reply.contains('tool_calls');

          if (looksLikeDeleteDraft) {
            try {
              final requestData = await _getLatestPendingProductDeletionForShop(userIdentifier);
              if (requestData != null) {
                final requestId = requestData['id']?.toString() ?? '';
                final msg = _buildProductDeletionMessage(requestData);

                await bot.sendMessage(
                  chatId,
                  msg,
                  parseMode: 'Markdown',
                  replyMarkup: tg.InlineKeyboardMarkup(
                    inlineKeyboard: [
                      [
                        tg.InlineKeyboardButton(text: '🗑 DELETE', callbackData: 'd_approve_$requestId'),
                        tg.InlineKeyboardButton(text: '❌ CANCEL', callbackData: 'd_reject_$requestId'),
                      ]
                    ],
                  ),
                );
              } else {
                await bot.sendMessage(chatId, reply);
              }
            } catch (e) {
              stderr.writeln('Error formatting product deletion: $e');
              await bot.sendMessage(chatId, reply);
            }
          } else {
            await bot.sendMessage(chatId, reply.isEmpty ? "I didn't understand that." : reply);
          }
        }
      }

    } catch (e) {
      await bot.sendMessage(chatId, 'Sorry, something went wrong. Please try again.');
      stderr.writeln('telegram_bot error for chat $chatId: $e');
    }
  });

  print('🤖 Telegram Bot is starting...');
  final me = await bot.getMe();
  print('✅ Telegram Bot is running as @${me.username}');

  bot.start();
}
