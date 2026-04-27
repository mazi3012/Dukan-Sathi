import 'dart:io';
import 'dart:convert';
import 'dart:async';

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
import 'package:dukansathi_new/tools/utility_tools.dart';
import 'package:dukansathi_new/tools/expense_tools.dart';
import 'package:genkit/genkit.dart';
import 'package:teledart/teledart.dart' as tg;
import 'package:teledart/model.dart' as tg;

final Map<int, Chat> activeSessions = {};

// Track pending rejection flows: chatId -> approvalId
final Map<int, String> pendingRejections = {};
// Track pending discount edits: chatId -> approvalId
final Map<int, String> pendingDiscountEdits = {};
// Track pending partial payment amount input: chatId -> approvalId
final Map<int, String> pendingPartialPaymentEdits = {};
// Track customer-name hints by approval id when DB schema is behind latest columns.
final Map<String, String> draftCustomerNameHints = {};
// Track pending image import confirmation: chatId -> telegram file URL
final Map<int, String> pendingImageImports = {};
// Track pending reminder heads-up question: chatId -> {text, scheduledAt}
final Map<int, Map<String, dynamic>> pendingReminderHeadsUp = {};

const String _systemPrompt =
  "You are the AI brain for Dukan Sathi Pro, a retail shop assistant. CRITICAL RULES: "
  "1. NEVER make up, guess, or hallucinate product names, prices, stock, or any data. ONLY use real data from tool responses. "
  "2. If inventory/catalog is empty, say so plainly — never invent sample products. "
  "3. No narration (never say 'I am checking' or 'Let me look up'). Use tools silently, output final result only. "
  "4. If you create a draft invoice, ALWAYS include the Approval ID in the format 'Approval ID: [ID]'. "
  "5. If you propose adding products, ALWAYS include the Batch ID in the format 'Batch ID: [ID]'. "
  "6. customerId, customerName, and customerState are OPTIONAL — do NOT ask for them; call the tool immediately. "
  "If a customer name is mentioned, pass customerName. If no customer is mentioned, use walk-in customer. "
  "7. For specific product lookups, use checkInventory. For full product lists, use browseCatalogTool. "
  "8. For business analytics (revenue, orders, approval status), use businessInsightsTool. Available metrics: total_revenue, total_orders, approved_count, pending_count, rejected_count, average_order_value, approval_rate. "
  "9. Present analytics in clear format: 'Total Revenue: ₹X | Orders: Y | Approved: Z | Pending: W | Rejected: V'. "
  "10. For product deletion, use deleteProduct and always include 'Delete Request ID: [ID]' in the response so Telegram can show approval buttons.\n"
  "11. For weather, use getWeather. If the user hasn't provided a 6-digit PIN code, ask for it first.\n"
  "12. For reminders, use setReminder. First, ALWAYS ask the user if they want a 'heads-up' 25 mins early. AFTER they answer YES or NO, YOU MUST execute the setReminder tool to save it. Never just say it is set without calling the tool.\n"
  "13. For shop expenses (rent, electricity, repairs), use logExpense to record them, and getExpenses to retrieve or check past expenses.";

DateTime _nowIst() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatIstTime(DateTime instant) {
  var hour = instant.hour;
  final minute = _twoDigits(instant.minute);
  final period = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '${_twoDigits(hour)}:$minute $period';
}

String _formatIstDate(DateTime instant) {
  return '${instant.year}-${_twoDigits(instant.month)}-${_twoDigits(instant.day)}';
}

final checkInventoryTool = checkInventory;
final catalogTool = browseCatalog;
final createDraftInvoiceTool = createDraftInvoice;
final analyticsTool = businessInsightsTool;
final proposeProductsTool = proposeProducts;
final requestProductDeletionTool = requestProductDeletion;
final weatherTool = getWeather;
final reminderTool = setReminder;
final expenseTool = logExpense;
final getExpensesTool = getExpenses;

// ─── HELPER: check if user has already completed onboarding ────────────────
Future<bool> _isUserOnboarded(int chatId) async {
  try {
    // Check if there's a user with this telegram_id who owns a shop
    final user = await supabase
        .from('users')
        .select('id')
        .eq('telegram_id', chatId)
        .maybeSingle();
    
    if (user == null) return false;

    final shop = await supabase
        .from('shops')
        .select('id')
        .eq('owner_id', user['id'])
        .eq('onboarding_completed', true)
        .maybeSingle();
        
    return shop != null;
  } catch (e) {
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
    tg.InlineKeyboardButton(text: '💰 PAID', callbackData: 'pay_paid_$approvalId'),
    tg.InlineKeyboardButton(text: '🕒 PARTIAL', callbackData: 'pay_partial_$approvalId'),
    tg.InlineKeyboardButton(text: '⭕ UNPAID', callbackData: 'pay_unpaid_$approvalId'),
  ];

  final List<tg.InlineKeyboardButton> row3 = [
    tg.InlineKeyboardButton(text: '✏️ DISCOUNT', callbackData: 'edit_discount_$approvalId'),
    tg.InlineKeyboardButton(text: '❌ REJECT', callbackData: 'reject_$approvalId'),
    tg.InlineKeyboardButton(text: '✅ APPROVE', callbackData: 'approve_$approvalId'),
  ];

  return tg.InlineKeyboardMarkup(
    inlineKeyboard: isRegistered ? [row1, row2, row3] : [row2, row3],
  );
}

// ─── HELPER: build formatted invoice message from DB ─────────────────────────
Future<String> _resolveDraftCustomerName(Map<String, dynamic> draftData) async {
  final explicitName = draftData['customer_name']?.toString().trim();
  if (explicitName != null && explicitName.isNotEmpty) {
    return explicitName;
  }

  final approvalId = draftData['approval_id']?.toString();
  if (approvalId != null) {
    final hintedName = draftCustomerNameHints[approvalId]?.trim();
    if (hintedName != null && hintedName.isNotEmpty) {
      return hintedName;
    }
  }

  final customerId = draftData['customer_id']?.toString();
  if (customerId == null || customerId.isEmpty) {
    return 'Walk-in Customer';
  }

  try {
    final customerRows = await supabase
        .from('customers')
        .select('name')
        .eq('id', customerId)
        .single();
    final customer = Map<String, dynamic>.from(customerRows as Map);
    return customer['name']?.toString().trim().isNotEmpty == true
        ? customer['name'].toString().trim()
        : 'Walk-in Customer';
  } catch (_) {
    return 'Walk-in Customer';
  }
}

String? _extractBillingCustomerName(String input) {
  var text = input.toLowerCase().trim();
  text = text
      .replaceAll(RegExp(r'^(please\s+)?(make|create|generate)\s+(a\s+)?(bill|invoice)\s*(for|with|to)?\s*'), '')
      .replaceAll(RegExp(r'\.$'), '')
      .trim();

  if (text.isEmpty) {
    return null;
  }

  final stopWords = {
    'he', 'she', 'they', 'customer', 'buyer', 'bought', 'took', 'takes', 'take',
    'brought', 'want', 'needs', 'need', 'please', 'for', 'to', 'the', 'a', 'an',
    'of', 'item', 'items', 'product', 'products', 'with', 'and', 'plus', 'has', 'have', 'got'
  };

  final tokens = text.split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
  final nameTokens = <String>[];
  for (final token in tokens) {
    if (RegExp(r'^\d+$').hasMatch(token)) {
      break;
    }
    if (stopWords.contains(token)) {
      break;
    }
    nameTokens.add(token);
  }

  if (nameTokens.isEmpty) {
    return null;
  }

  return nameTokens.map((token) => token[0].toUpperCase() + token.substring(1)).join(' ');
}

double? _parsePaidAmountText(String input) {
  final normalized = input.trim().replaceAll(',', '').toLowerCase();
  final amountMatch = RegExp(r'^(?:₹|rs\.?\s*)?(\d+(?:\.\d+)?)\s*(?:rs|rupees)?$').firstMatch(normalized);
  if (amountMatch == null) {
    return null;
  }
  return double.tryParse(amountMatch.group(1)!);
}

Map<String, dynamic>? _parseDiscountText(String input) {
  final normalized = input.trim().replaceAll(',', '').toLowerCase();
  final percentMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*%$').firstMatch(normalized);
  if (percentMatch != null) {
    return {
      'discountType': 'PERCENT',
      'discountValue': double.parse(percentMatch.group(1)!),
    };
  }

  final amountMatch = RegExp(r'^(?:₹|rs\.?\s*)?(\d+(?:\.\d+)?)\s*(?:rs|rupees)?$').firstMatch(normalized);
  if (amountMatch != null) {
    return {
      'discountType': 'AMOUNT',
      'discountValue': double.parse(amountMatch.group(1)!),
    };
  }

  return null;
}

Future<String> _buildInvoiceMessage(
  Map<String, dynamic> draftData,
) async {
  final approval = DraftApproval.fromJson(draftData);
  final customerName = await _resolveDraftCustomerName(draftData);
  final paymentStatus = draftData['payment_status']?.toString();
  final amountPaid = (draftData['amount_paid'] as num?)?.toDouble();
  final dueAmount = (draftData['due_amount'] as num?)?.toDouble();
  final discountType = draftData['discount_type']?.toString();
  final discountValue = (draftData['discount_value'] as num?)?.toDouble();
  final discountAmount = (draftData['discount_amount'] as num?)?.toDouble();
  final subtotalBeforeDiscount = (draftData['subtotal_before_discount'] as num?)?.toDouble();
  final subtotalAfterDiscount = (draftData['subtotal_after_discount'] as num?)?.toDouble();
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
    paymentStatus: paymentStatus,
    amountPaid: amountPaid,
    dueAmount: dueAmount,
    discountType: discountType,
    discountValue: discountValue,
    discountAmount: discountAmount,
    subtotalBeforeDiscount: subtotalBeforeDiscount,
    subtotalAfterDiscount: subtotalAfterDiscount,
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

bool _isReminderIntentGlobal(String input) {
  final n = input.toLowerCase();
  return n.contains('remind') || n.contains('reminder') || n.contains('set a alert') || n.contains('set an alert');
}

/// Parse reminder text and time from user input like:
/// "Set a reminder for stock checking at 12.44 am today"
/// "Remind me to call supplier at 5:30 PM"
/// "Set a reminder to check stock at 1:5 AM today"
Map<String, dynamic>? _parseReminderFromText(String input) {
  // Try to extract time pattern like "12.44 am", "5:30 PM", "1:5 am", "12:00 am"
  final timePattern = RegExp(
    r'(?:at|for)\s+(\d{1,2})[.:](\d{1,2})\s*(am|pm|a\.m|p\.m|ap|AM|PM)',
    caseSensitive: false,
  );

  final match = timePattern.firstMatch(input);
  if (match == null) {
    // Try simpler pattern like "at 5 pm"
    final simplePattern = RegExp(
      r'(?:at|for)\s+(\d{1,2})\s*(am|pm|a\.m|p\.m|AM|PM)',
      caseSensitive: false,
    );
    final simpleMatch = simplePattern.firstMatch(input);
    if (simpleMatch == null) return null;

    var hour = int.parse(simpleMatch.group(1)!);
    final ampm = simpleMatch.group(2)!.toLowerCase().replaceAll('.', '');
    if (ampm.startsWith('p') && hour != 12) hour += 12;
    if (ampm.startsWith('a') && hour == 12) hour = 0;

    final nowIst = _nowIst();
    // Use DateTime.utc so .toUtc() is a no-op later (we handle IST->UTC manually)
    var scheduledIst = DateTime.utc(nowIst.year, nowIst.month, nowIst.day, hour, 0);
    if (scheduledIst.isBefore(nowIst)) {
      scheduledIst = scheduledIst.add(const Duration(days: 1));
    }
    // Convert IST to UTC by subtracting 5:30
    final scheduledUtc = scheduledIst.subtract(const Duration(hours: 5, minutes: 30));

    final reminderText = _extractReminderDescription(input);
    return {'text': reminderText, 'scheduledAt': scheduledUtc};
  }

  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  // "1:5" means 1:05, not 1:50 — keep the parsed value as-is
  final ampm = match.group(3)!.toLowerCase().replaceAll('.', '');

  if (ampm.startsWith('p') && hour != 12) hour += 12;
  if (ampm.startsWith('a') && hour == 12) hour = 0;

  final nowIst = _nowIst();
  // Use DateTime.utc so .toUtc() is a no-op later
  var scheduledIst = DateTime.utc(nowIst.year, nowIst.month, nowIst.day, hour, minute);
  if (scheduledIst.isBefore(nowIst)) {
    scheduledIst = scheduledIst.add(const Duration(days: 1));
  }
  // Convert IST to UTC
  final scheduledUtc = scheduledIst.subtract(const Duration(hours: 5, minutes: 30));

  final reminderText = _extractReminderDescription(input);
  return {'text': reminderText, 'scheduledAt': scheduledUtc};
}


String _extractReminderDescription(String input) {
  // Remove the "set a reminder" prefix and time suffix
  var text = input
      .replaceAll(RegExp(r'set\s+(a\s+)?reminder\s+(for\s+|to\s+)?', caseSensitive: false), '')
      .replaceAll(RegExp(r'remind\s+me\s+(to\s+|for\s+)?', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+at\s+\d{1,2}[.:]\d{1,2}\s*(am|pm|a\.m|p\.m|ap|AM|PM).*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+at\s+\d{1,2}\s*(am|pm|a\.m|p\.m|AM|PM).*', caseSensitive: false), '')
      .trim();
  if (text.isEmpty) text = 'Reminder';
  // Capitalize first letter
  return text[0].toUpperCase() + text.substring(1);
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

  bool _isWeatherIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('weather') || n.contains('temperature') || n.contains('forecast') || n.contains('outside');
  }

  bool _isExpenseIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('expense') || n.contains('spent') || n.contains('paid for') || 
        n.contains('bill paid') || n.contains('cost') || n.contains('electricity bill') ||
        n.contains('water bill') || n.contains('rent bill') || n.contains('internet bill') ||
        n.contains('phone bill');
  }

  bool _isReminderIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('remind') || n.contains('reminder') || n.contains('set a alert');
  }

  bool _isAnalyticsIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('total sales') || n.contains('revenue') || n.contains('analytics') ||
        n.contains('insight') || n.contains('how much did') || n.contains('profit') ||
        n.contains('profit margin') || n.contains('earnings') || n.contains('total earnings') ||
        n.contains('how many orders') || n.contains('order count') || n.contains('approval') ||
        n.contains('pending') || n.contains('rejected') || n.contains('approved') ||
      n.contains('average order') || n.contains('approval rate') ||
      n.contains('today') || n.contains('yesterday') || n.contains('this week') ||
      n.contains('last week') || n.contains('this month') || n.contains('last month') ||
      n.contains('date range') || n.contains('between') || n.contains('from ') || n.contains('to ');
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

  bool _isTimeIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('what time is it') ||
        n.contains('what is the time') ||
        n.contains('what is the time now') ||
        n.contains('current time') ||
        n.contains('time now') ||
        n.contains('tell me the time');
  }

  bool _isDateIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('what is the date') ||
        n.contains('what is today\'s date') ||
        n.contains('today\'s date') ||
        n.contains('current date') ||
        n.contains('date today') ||
        n.contains('what day is it');
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
        .replaceAll(RegExp(r'^(please\s+)?(make|create|generate)\s+(a\s+)?(bill|invoice)\s*(for|with|to)?\s*'), '')
        .replaceAll(RegExp(r'\.$'), '')
        .trim();

    if (text.isEmpty) {
      return {};
    }

    final requested = <String, int>{};

    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final qtyBeforeNamePattern = RegExp(
      r'(\d+)\s*x?\s+([a-z0-9][a-z0-9\s\-()\/]*?)(?=(?:\s+(?:and|with|plus|,|;|\.|$))|$)',
      caseSensitive: false,
    );
    final qtyAfterNamePattern = RegExp(
      r'([a-z0-9][a-z0-9\s\-()\/]*?)\s*x\s*(\d+)(?=(?:\s+(?:and|with|plus|,|;|\.|$))|$)',
      caseSensitive: false,
    );

    for (final match in qtyBeforeNamePattern.allMatches(normalized)) {
      final qty = int.tryParse(match.group(1) ?? '');
      var name = match.group(2)?.trim() ?? '';
      if (qty == null || qty <= 0 || name.isEmpty) {
        continue;
      }

      name = name
          .replaceAll(RegExp(r'\b(he|she|they|customer|buyer|bought|took|takes|take|brought|want|needs|need|please|for|to|the|a|an|of|item|items|product|products)\b'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (name.isEmpty) {
        continue;
      }

      requested[name] = (requested[name] ?? 0) + qty;
    }

    for (final match in qtyAfterNamePattern.allMatches(normalized)) {
      final qty = int.tryParse(match.group(2) ?? '');
      var name = match.group(1)?.trim() ?? '';
      if (qty == null || qty <= 0 || name.isEmpty) {
        continue;
      }

      name = name
          .replaceAll(RegExp(r'\b(he|she|they|customer|buyer|bought|took|takes|take|brought|want|needs|need|please|for|to|the|a|an|of|item|items|product|products)\b'), ' ')
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

    if (_isTimeIntent(input)) {
      final now = _nowIst();
      final reply = 'The current time is ${_formatIstTime(now)} IST.';
      _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
      _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
      return reply;
    }

    if (_isDateIntent(input)) {
      final now = _nowIst();
      final reply = "Today's date is ${_formatIstDate(now)} IST.";
      _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
      _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
      return reply;
    }

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

    final bool isUtilityIntent = _isReminderIntent(input) || _isExpenseIntent(input) || _isWeatherIntent(input);

    if (!isUtilityIntent && _isInventoryIntent(input) && !_isBillingIntent(input) && !_isAddProductIntent(input)) {
      final query = _extractInventoryQuery(input);
      final products = await findInventoryProducts(query.isEmpty ? input : query);
      final reply = _formatInventoryReply(products);
      _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
      _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
      return reply;
    }

    if (!isUtilityIntent && _isBillingIntent(input)) {
      final requestedItems = _parseBillingRequestedItems(input);
      if (requestedItems.isNotEmpty) {
        try {
            final customerName = _extractBillingCustomerName(input);
          final result = await createDraftInvoiceRequest(
              input: {
                'requestedItems': requestedItems,
                if (customerName != null) 'customerName': customerName,
              },
            userIdentifier: userIdentifier,
          );
          final approvalId = result['approvalId']?.toString();
          final resolvedCustomerName = result['customerName']?.toString().trim();
          if (approvalId != null &&
              approvalId.isNotEmpty &&
              resolvedCustomerName != null &&
              resolvedCustomerName.isNotEmpty) {
            draftCustomerNameHints[approvalId] = resolvedCustomerName;
          }
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
    } else if (_isWeatherIntent(input)) {
      selectedTools = ['getWeather'];
    } else if (_isReminderIntent(input)) {
      selectedTools = ['setReminder'];
    } else if (_isExpenseIntent(input)) {
      selectedTools = ['logExpense', 'getExpenses'];
    }

    Future<dynamic> runGenerate() => ai.generate(
      model: appModel(model),
      messages: [
        Message(role: Role.system, content: [TextPart(text: '$systemPrompt\nThe current date/time in IST is ${_formatIstDate(_nowIst())} ${_formatIstTime(_nowIst())}. Use this to calculate ISO 8601 timestamps for reminders.')]),
        ..._history,
      ],
      toolNames: {...tools, ...selectedTools}.toList(),
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
            Message(role: Role.system, content: [TextPart(text: '$systemPrompt\nThe current date/time in IST is ${_formatIstDate(_nowIst())} ${_formatIstTime(_nowIst())}. Use this to calculate ISO 8601 timestamps for reminders.')]),
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
      print('[bot] Handling approval for: $approvalId');
      await bot.answerCallbackQuery(query.id, text: '⏳ Processing...');
      try {
        print('[bot] Calling approveDraftInvoice...');
        final result = await approveDraftInvoice(approvalId: approvalId, reviewedBy: chatId.toString());
        print('[bot] approveDraftInvoice result: ${result['success']}');
        
        if (result['success'] == true) {
          try {
            print('[bot] Generating PDF for invoice: ${result['invoiceNumber']}');
            final pdf = await InvoicePdfGenerator.generateApprovedInvoicePdf(
              approvalId: approvalId,
              invoiceNumber: result['invoiceNumber'] as String,
            );
            print('[bot] PDF generated successfully: ${pdf.file.path}');
            
            await bot.sendDocument(
              chatId,
              pdf.file,
              caption: pdf.caption,
            );
            print('[bot] PDF sent to user');

            // --- Post-Sale Notification Logic ---
            try {
              final draftData = await getApprovalDetails(approvalId);
              if (draftData != null) {
                final approval = DraftApproval.fromJson(draftData);
                String notification = '✅ *Post-Sale Summary*\n\n';
                
                notification += '📦 *Remaining Stock:*\n';
                for (final item in approval.proposedItems) {
                  try {
                    final pRes = await supabase.from('products').select('name, stock_quantity').eq('id', item.productId).single();
                    final name = (pRes as Map)['name'] ?? 'Product';
                    final stock = (pRes)['stock_quantity'] ?? 0;
                    notification += '• $name: $stock left\n';
                  } catch (_) {
                    // Ignore if product is not found
                  }
                }
                
                if (approval.dueAmount > 0 && approval.customerId != null && approval.customerId!.isNotEmpty) {
                  try {
                    final cRes = await supabase.from('customers').select('name, current_balance').eq('id', approval.customerId!).single();
                    final cName = (cRes as Map)['name'] ?? 'Customer';
                    final balance = (cRes)['current_balance'] ?? 0.0;
                    notification += '\n💳 *Credit Update:*\n';
                    notification += '• $cName now has a total due balance of ₹${(balance as num).toStringAsFixed(2)}.\n';
                  } catch (_) {
                    // Ignore if customer not found
                  }
                }

                await bot.sendMessage(
                  chatId,
                  notification,
                  parseMode: 'Markdown',
                );
              }
            } catch (notifyError, stackTrace) {
              stderr.writeln('Error sending post-sale notification: $notifyError');
            }
            // ------------------------------------

          } catch (pdfError, stackTrace) {
            stderr.writeln('Error generating/sending invoice PDF: $pdfError');
            stderr.writeln('Stack trace: $stackTrace');
            await bot.sendMessage(
              chatId,
              '⚠️ Invoice was approved and saved, but the PDF could not be generated.\n\nError: $pdfError',
            );
          }
          await bot.editMessageText(
            '${result['message'] as String}\n\n📄 PDF process complete.',
            chatId: chatId,
            messageId: msgId,
            parseMode: 'Markdown',
          );
        } else {
          print('[bot] Approval failed: ${result['error']}');
          await bot.answerCallbackQuery(query.id, text: '❌ Approval failed');
          await bot.sendMessage(
            chatId,
            '❌ *Approval Failed*\n\n${result['error']}',
            parseMode: 'Markdown',
            replyToMessageId: msgId,
          );
        }
      } catch (e, stackTrace) {
        stderr.writeln('Critical error during approval process: $e');
        stderr.writeln('Stack trace: $stackTrace');
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
            final msg = await _buildInvoiceMessage(draftData);
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
            final msg = await _buildInvoiceMessage(draftData);
            await bot.editMessageText(msg, chatId: chatId, messageId: msgId,
              parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, 'CGST_SGST', true));
          }
        }
      } catch (e) {
        stderr.writeln('Error switching to CGST/SGST: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to switch. Try again.', showAlert: true);
      }

    // ── PAYMENT STATUS QUICK SWITCH ───────────────────────────────────
    } else if (data.startsWith('pay_paid_') || data.startsWith('pay_partial_') || data.startsWith('pay_unpaid_')) {
      final approvalId = data.replaceFirst(RegExp(r'^pay_(paid|partial|unpaid)_'), '');
      final paymentStatus = data.contains('_paid_')
          ? 'PAID'
          : data.contains('_partial_')
              ? 'PARTIAL'
              : 'UNPAID';

      if (paymentStatus == 'PARTIAL') {
        pendingPartialPaymentEdits[chatId] = approvalId;
        await bot.answerCallbackQuery(query.id);
        await bot.editMessageText(
          '🕒 Send the *paid amount* now (example: *400* or *₹400*).',
          chatId: chatId,
          messageId: msgId,
          parseMode: 'Markdown',
        );
        return;
      }

      await bot.answerCallbackQuery(query.id, text: '⏳ Updating payment status...');
      try {
        final result = await updateDraftPaymentStatus(
          approvalId: approvalId,
          paymentStatus: paymentStatus,
        );
        if (result['success'] == true) {
          final draftData = await getApprovalDetails(approvalId);
          if (draftData != null) {
            final shopId = draftData['shop_id'] as String;
            final shopRows = await supabase
                .from('shops')
                .select('gst_mode')
                .eq('id', shopId)
                .single();
            final gstMode = (shopRows as Map)['gst_mode'] as String? ?? 'REGISTERED';
            final isRegistered = gstMode == 'REGISTERED';
            final currentGstType = draftData['gst_type'] as String? ?? 'CGST_SGST';
            final formattedMessage = await _buildInvoiceMessage(draftData);
            await bot.editMessageText(
              formattedMessage,
              chatId: chatId,
              messageId: msgId,
              parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, currentGstType, isRegistered),
            );
          }
        } else {
          await bot.answerCallbackQuery(query.id, text: '❌ ${result['error']}', showAlert: true);
        }
      } catch (e) {
        stderr.writeln('Error updating payment status: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to update payment status.', showAlert: true);
      }

    // ── DISCOUNT EDIT ────────────────────────────────────────────────
    } else if (data.startsWith('edit_discount_')) {
      final approvalId = data.replaceFirst('edit_discount_', '');
      pendingDiscountEdits[chatId] = approvalId;
      await bot.answerCallbackQuery(query.id);
      await bot.editMessageText(
        '✏️ Send the new discount as *10%* or *₹50*.',
        chatId: chatId,
        messageId: msgId,
        parseMode: 'Markdown',
      );

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

  // ─── SHARED MESSAGE HANDLER ─────────────────────────────────────────────
  Future<void> handleIncomingMessage(tg.TeleDartMessage message) async {
    final text = message.text?.trim() ?? '';
    if (text.isEmpty) return;
    
    print('[bot] RAW message from ${message.chat.id}: "$text"');
    final caption = message.caption?.trim();

    final chatId = message.chat.id;
    final userIdentifier = message.from?.username ?? message.from?.firstName ?? chatId.toString();

    final cleanText = text.toLowerCase();

    // ── /login command (Magic Code for web login) ─────────────────
    if (cleanText == '/login' || cleanText.startsWith('/login@')) {
      print('[bot] Matching /login for chat=$chatId');
      try {
        // Check if user is onboarded first
        final isOnboarded = await _isUserOnboarded(chatId);
        print('[bot] /login isOnboarded=$isOnboarded for chat=$chatId');
        if (!isOnboarded) {
          await bot.sendMessage(chatId,
            '⚠️ You need to set up your shop first!\n\nSend /start to begin onboarding.',
            parseMode: 'Markdown');
          return;
        }

        // Find or create user in unified users table
        final userRow = await supabase
            .from('users')
            .upsert({
              'telegram_id': chatId,
              'full_name': userIdentifier,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'telegram_id')
            .select('id')
            .single();
        final userId = userRow['id'] as String;

        // Generate 6-digit code
        final random = DateTime.now().millisecondsSinceEpoch;
        final code = ((random % 900000) + 100000).toString();

        // Invalidate any existing codes for this user
        await supabase
            .from('login_codes')
            .delete()
            .eq('user_id', userId);

        // Insert new code (expires in 5 minutes)
        await supabase.from('login_codes').insert({
          'user_id': userId,
          'code': code,
          'expires_at': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
          'used': false,
        });

        await bot.sendMessage(chatId,
          '🔐 *Web Login Code*\n\n'
          '```\n$code\n```\n\n'
          '📱 Enter this code on the Dukan Sathi web app to sign in.\n\n'
          '⏰ This code expires in *5 minutes*.\n'
          '⚠️ Do NOT share this code with anyone!',
          parseMode: 'Markdown');
        print('[bot] /login code sent to $chatId');
      } catch (e) {
        stderr.writeln('[login-code] chat=$chatId error: $e');
        await bot.sendMessage(chatId, '❌ Could not generate login code. Please try again.');
      }
      return;
    }

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

    if (text.isEmpty) return;

    // ── Handle pending partial-payment amount input ─────────────────────
    if (pendingPartialPaymentEdits.containsKey(chatId)) {
      final approvalId = pendingPartialPaymentEdits.remove(chatId) ?? '';
      final amountPaid = _parsePaidAmountText(text);
      if (amountPaid == null || amountPaid <= 0) {
        pendingPartialPaymentEdits[chatId] = approvalId;
        await bot.sendMessage(
          chatId,
          'Please send a valid paid amount like 400 or ₹400.',
        );
        return;
      }

      try {
        final result = await updateDraftPaymentStatus(
          approvalId: approvalId,
          paymentStatus: 'PARTIAL',
          amountPaid: amountPaid,
        );
        if (result['success'] == true) {
          final draftData = await getApprovalDetails(approvalId);
          if (draftData != null) {
            final shopId = draftData['shop_id'] as String;
            final shopRows = await supabase
                .from('shops')
                .select('gst_mode')
                .eq('id', shopId)
                .single();
            final gstMode = (shopRows as Map)['gst_mode'] as String? ?? 'REGISTERED';
            final isRegistered = gstMode == 'REGISTERED';
            final currentGstType = draftData['gst_type'] as String? ?? 'CGST_SGST';
            final formattedMessage = await _buildInvoiceMessage(draftData);
            await bot.sendMessage(chatId, 'Partial payment updated.');
            await bot.sendMessage(
              chatId,
              formattedMessage,
              parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, currentGstType, isRegistered),
            );
          }
        } else {
          await bot.sendMessage(chatId, result['error']?.toString() ?? 'Failed to update partial payment.');
        }
      } catch (e) {
        stderr.writeln('Error updating partial payment: $e');
        await bot.sendMessage(chatId, 'Failed to update partial payment. Try again.');
      }
      return;
    }

    // ── Handle pending discount edit input ──────────────────────────────
    if (pendingDiscountEdits.containsKey(chatId)) {
      final approvalId = pendingDiscountEdits.remove(chatId) ?? '';
      final discount = _parseDiscountText(text);
      if (discount == null) {
        pendingDiscountEdits[chatId] = approvalId;
        await bot.sendMessage(
          chatId,
          'Send the new discount as 10% or ₹50. Reply with the amount now.',
        );
        return;
      }

      try {
        final result = await updateDraftDiscount(
          approvalId: approvalId,
          discountType: discount['discountType'] as String,
          discountValue: discount['discountValue'] as double,
        );
        if (result['success'] == true) {
          final draftData = await getApprovalDetails(approvalId);
          if (draftData != null) {
            final shopId = draftData['shop_id'] as String;
            final shopRows = await supabase
                .from('shops')
                .select('gst_mode')
                .eq('id', shopId)
                .single();
            final gstMode = (shopRows as Map)['gst_mode'] as String? ?? 'REGISTERED';
            final isRegistered = gstMode == 'REGISTERED';
            final currentGstType = draftData['gst_type'] as String? ?? 'CGST_SGST';
            final formattedMessage = await _buildInvoiceMessage(draftData);
            await bot.sendMessage(chatId, 'Discount updated successfully.');
            await bot.sendMessage(
              chatId,
              formattedMessage,
              parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, currentGstType, isRegistered),
            );
          }
        } else {
          await bot.sendMessage(chatId, result['error']?.toString() ?? 'Failed to update discount.');
        }
      } catch (e) {
        stderr.writeln('Error updating discount: $e');
        await bot.sendMessage(chatId, 'Failed to update discount. Try again.');
      }
      return;
    }

    // ── Handle pending reminder heads-up answer ───────────────────────────
    if (pendingReminderHeadsUp.containsKey(chatId)) {
      final reminderData = pendingReminderHeadsUp.remove(chatId)!;
      final reminderText = reminderData['text'] as String;
      var scheduledAt = reminderData['scheduledAt'] as DateTime;
      final bool headsUp = _isYesReply(text);

      if (headsUp) {
        scheduledAt = scheduledAt.subtract(const Duration(minutes: 25));
      }

      try {
        final shopId = await getShopIdForUser(userIdentifier);
        await supabase.from('reminders').insert({
          'chat_id': chatId,
          'shop_id': shopId,
          'reminder_text': reminderText,
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'heads_up': headsUp,
          'status': 'PENDING',
        });

        final istTime = scheduledAt.toUtc().add(const Duration(hours: 5, minutes: 30));
        var hour = istTime.hour;
        final minute = istTime.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        final timeStr = '$hour:$minute $period';

        if (headsUp) {
          await bot.sendMessage(chatId, '✅ Reminder set! I\'ll remind you about "$reminderText" at $timeStr (25 min early heads-up). 🔔');
        } else {
          await bot.sendMessage(chatId, '✅ Reminder set! I\'ll remind you about "$reminderText" at $timeStr. 🔔');
        }
      } catch (e) {
        stderr.writeln('Error saving reminder: $e');
        await bot.sendMessage(chatId, '⚠️ Could not save reminder. Please try again.');
      }
      return;
    }

    // ── Detect reminder intent and start flow ─────────────────────────────
    if (_isReminderIntentGlobal(text)) {
      final parsed = _parseReminderFromText(text);
      if (parsed != null) {
        pendingReminderHeadsUp[chatId] = parsed;
        await bot.sendMessage(chatId, '⏰ Got it — "${parsed['text']}". Should I remind you 25 minutes earlier as a heads-up? Reply *YES* or *NO*.', parseMode: 'Markdown');
      } else {
        await bot.sendMessage(chatId, 'I understood you want a reminder, but I couldn\'t parse the time. Please try like:\n"Set a reminder to check stock at 5:30 PM today"');
      }
      return;
    }

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
    final isOnboarded = await _isUserOnboarded(chatId);
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
          weatherTool.name,
          reminderTool.name,
          expenseTool.name,
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
            final formattedMessage = await _buildInvoiceMessage(draftData);

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
  }

  bot.onMessage().listen(handleIncomingMessage);
  bot.onCommand('login').listen(handleIncomingMessage);
  bot.onCommand('start').listen(handleIncomingMessage);
  bot.onCommand('join').listen(handleIncomingMessage);

  print('🤖 Telegram Bot is starting...');
  final me = await bot.getMe();
  print('✅ Telegram Bot is running as @${me.username}');

  bot.start();

  // ─── REMINDER BACKGROUND PROCESSOR ─────────────────────────────────────
  print('⏰ Starting Reminder Background Processor...');
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final dueReminders = await supabase
          .from('reminders')
          .select()
          .eq('status', 'PENDING')
          .lte('scheduled_at', now);

      for (final row in dueReminders as List) {
        final data = Map<String, dynamic>.from(row as Map);
        final id = data['id'];
        final chatId = data['chat_id'] as int;
        final text = data['reminder_text'] as String;

        print('[reminders] Delivering reminder $id to chat $chatId');
        
        await bot.sendMessage(
          chatId,
          '⏰ *REMINDER*\n\n$text',
          parseMode: 'Markdown',
        );

        await supabase
            .from('reminders')
            .update({'status': 'SENT'})
            .eq('id', id);
      }
    } catch (e) {
      stderr.writeln('[reminders-error] $e');
    }
  });
}
