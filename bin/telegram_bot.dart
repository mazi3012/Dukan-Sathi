import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:dukansathi_new/models/product.dart';
import 'package:dukansathi_new/services/approval_formatter.dart';
import 'package:dukansathi_new/tools/analytics_tools.dart';
import 'package:dukansathi_new/tools/approval_tools.dart';
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

const String _systemPrompt =
  "You are the AI brain for Dukan Sathi Pro. Shop ID is '71a343a4-2e91-4e11-85b3-3a15f013d5a4'. CRITICAL RULES: 1. No narration (never say 'I am checking' or 'Using tool'). 2. Use tools silently. 3. Output final result only. 4. If you create a draft invoice, YOU MUST ALWAYS include the Approval ID in the format 'Approval ID: [ID]'. 5. customerId and customerState are OPTIONAL — do NOT ask for them; call the tool immediately with shopId and items. 6. For specific items use checkInventory. 7. For product lists use browseCatalogTool. 8. For analytics use businessInsightsTool.";

final checkInventoryTool = checkInventory;
final catalogTool = browseCatalog;
final createDraftInvoiceTool = createDraftInvoice;
final analyticsTool = businessInsightsTool;

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

// ─── CHAT SESSION ─────────────────────────────────────────────────────────────
class Chat {
  Chat({required this.model, required this.tools, required this.systemPrompt});

  final String model;
  final List<String> tools;
  final String systemPrompt;
  final List<Message> _history = [];

  bool _isBillingIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('bill') || n.contains('invoice') || n.contains('draft') || n.contains('बिल');
  }

  bool _isCatalogIntent(String input) {
    final n = input.toLowerCase();
    return n.contains('what do you sell') || n.contains('what item') || n.contains('what items') ||
        n.contains('catalog') || n.contains('list product') || n.contains('show product') ||
        n.contains('show item') || n.contains('available product') || n.contains('what do you have') ||
        n.contains('items do you have');
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
        n.contains('insight') || n.contains('how much did');
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
    if (items.isEmpty) return 'Our catalog is currently being updated.';
    return items.take(20).map((p) => '${p.name}: ₹${_formatPrice(p.price)}, ${p.stockQuantity} units').join('\n');
  }

  Future<String> sendMessage(String? text) async {
    final input = (text ?? '').trim();
    if (input.isEmpty) return '';

    if (_isCatalogIntent(input)) {
      final payload = await browseCatalogTool({'category': _extractCategory(input)});
      final reply = _formatCatalogReply(payload);
      _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
      _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
      return reply;
    }

    if (_isInventoryIntent(input) && !_isBillingIntent(input)) {
      final query = _extractInventoryQuery(input);
      final products = await findInventoryProducts(query.isEmpty ? input : query);
      final reply = _formatInventoryReply(products);
      _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
      _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
      return reply;
    }

    _history.add(Message(role: Role.user, content: [TextPart(text: input)]));

    // Select tools based on intent
    List<String> selectedTools = [];
    if (_isBillingIntent(input)) {
      selectedTools = ['createDraftInvoice'];
    } else if (_isAnalyticsIntent(input)) {
      selectedTools = ['businessInsightsTool'];
    }

    Future<dynamic> runGenerate() => ai.generate(
      model: appModel(model),
      messages: [
        Message(role: Role.system, content: [TextPart(text: systemPrompt)]),
        ..._history,
      ],
      toolNames: selectedTools,
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

    // ── APPROVE ──────────────────────────────────────────────────────────
    if (data.startsWith('approve_')) {
      final approvalId = data.replaceFirst('approve_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Processing...');
      try {
        final result = await approveDraftInvoice(approvalId: approvalId, reviewedBy: chatId.toString());
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
            final msg = await _buildInvoiceMessage(draftData, query.from?.firstName ?? 'Customer');
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
            final msg = await _buildInvoiceMessage(draftData, query.from?.firstName ?? 'Customer');
            await bot.editMessageText(msg, chatId: chatId, messageId: msgId,
              parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, 'CGST_SGST', true));
          }
        }
      } catch (e) {
        stderr.writeln('Error switching to CGST/SGST: $e');
        await bot.answerCallbackQuery(query.id, text: 'Failed to switch. Try again.', showAlert: true);
      }
    }
  });

  // ─── MESSAGE HANDLER ────────────────────────────────────────────────────
  bot.onMessage().listen((message) async {
    final text = message.text?.trim();
    if (text == null || text.isEmpty) return;

    final chatId = message.chat.id;
    final customerName = message.from?.firstName ?? 'Customer';

    // ── Handle pending rejection reason ─────────────────────────────────
    if (pendingRejections.containsKey(chatId)) {
      final approvalId = pendingRejections.remove(chatId) ?? '';
      if (approvalId.isEmpty) return;
      try {
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
      } catch (e) {
        stderr.writeln('Error rejecting draft: $e');
        await bot.sendMessage(chatId, 'Error processing rejection.');
      }
      return;
    }

    // ── Normal AI flow ───────────────────────────────────────────────────
    final session = activeSessions.putIfAbsent(
      chatId,
      () => Chat(
        model: modelId,
        tools: [checkInventoryTool.name, catalogTool.name, createDraftInvoiceTool.name, analyticsTool.name],
        systemPrompt: _systemPrompt,
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
        await bot.sendMessage(chatId, reply.isEmpty ? "I didn't understand that." : reply);
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
