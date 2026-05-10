import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:teledart/teledart.dart' as tg;
import 'package:teledart/model.dart' as tg;
import 'package:teledart/telegram.dart' as tg;
import 'package:dotenv/dotenv.dart';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/core/database.dart';
import 'package:dukansathi_new/models/product.dart';
import 'package:dukansathi_new/models/draft_approval.dart';
import 'package:dukansathi_new/tools/inventory_tools.dart';
import 'package:dukansathi_new/tools/approval_tools.dart';
import 'package:dukansathi_new/tools/billing_tools.dart';
import 'package:dukansathi_new/tools/analytics_tools.dart';
import 'package:dukansathi_new/tools/customer_tools.dart' as cust;
import 'package:dukansathi_new/tools/utility_tools.dart';
import 'package:dukansathi_new/tools/expense_tools.dart';
import 'package:dukansathi_new/tools/customer_tools.dart';
import 'package:dukansathi_new/tools/invoice_lookup_tools.dart';
import 'package:dukansathi_new/services/approval_formatter.dart';
import 'package:dukansathi_new/services/invoice_pdf_generator.dart';
import 'package:dukansathi_new/flows/retail_assistant.dart';
import 'package:dukansathi_new/flows/onboarding_flow.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:genkit/genkit.dart';

class TelegramService {
  late tg.TeleDart bot;
  late tg.Event _event;
  final String token;
  final String model;

  final Map<int, ChatSession> activeSessions = {};
  final Map<int, String> pendingRejections = {};
  final Map<int, String> pendingDiscountEdits = {};
  final Map<int, String> pendingPartialPaymentEdits = {};
  final Map<String, String> draftCustomerNameHints = {};
  final Map<int, String> pendingImageImports = {};
  final Map<int, Map<String, dynamic>> pendingReminderHeadsUp = {};

  static const String _systemPrompt =
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
      "9. Present analytics in clear format: 'Total Revenue: ₹X | Orders: Z | Approved: Z | Pending: W | Rejected: V'. "
      "10. For product deletion, use deleteProduct and always include 'Delete Request ID: [ID]' in the response so Telegram can show approval buttons.\n"
      "11. For weather, use getWeather. If the user hasn't provided a 6-digit PIN code, ask for it first.\n"
      "12. For reminders, use setReminder. First, ALWAYS ask the user if they want a 'heads-up' 25 mins early. AFTER they answer YES or NO, YOU MUST execute the setReminder tool to save it. Never just say it is set without calling the tool.\n"
      "13. For shop expenses (rent, electricity, repairs), use logExpense to record them, and getExpenses to retrieve or check past expenses.\n"
      "14. For customer dues, balances, or payments, use checkCustomerDue, listCustomersDue, recordPayment, and invoiceLookup.";

  TelegramService({required this.token, String? model}) : model = model ?? modelId;

  Future<void> init() async {
    _event = tg.Event('');
    bot = tg.TeleDart(token, _event);
    _setupHandlers();
    
    print('🤖 Telegram Bot Service Starting...');
    final me = await bot.getMe();
    print('✅ Bot is running as @${me.username}');
    
    _startReminderProcessor();
  }

  /// Process a raw webhook update from Telegram.
  /// Call this from the HTTP webhook endpoint.
  void processWebhookUpdate(Map<String, dynamic> updateJson) {
    try {
      final update = tg.Update.fromJson(updateJson);
      _event.emitUpdate(update);
    } catch (e) {
      print('❌ Error processing webhook update: $e');
    }
  }

  void _setupHandlers() {
    bot.onCallbackQuery().listen(_handleCallbackQuery);
    bot.onMessage().listen(_handleIncomingMessage);
    bot.onCommand('login').listen(_handleIncomingMessage);
    bot.onCommand('start').listen(_handleIncomingMessage);
    bot.onCommand('join').listen(_handleIncomingMessage);
  }

  Future<void> _handleCallbackQuery(tg.CallbackQuery query) async {
    final chatId = query.from.id;
    final data = query.data ?? '';
    final msgId = query.message!.messageId;

    if (data.startsWith('ob_')) {
      await bot.answerCallbackQuery(query.id);
      try {
        final result = await processOnboardingCallback(chatId, data);
        if (result != null) {
          await bot.sendMessage(chatId, result.text, parseMode: 'Markdown', replyMarkup: result.keyboard);
        }
      } catch (e) {
        stderr.writeln('[onboarding-callback] $e');
        await bot.sendMessage(chatId, '⚠️ Something went wrong. Please try again.');
      }
      return;
    }

    if (data.startsWith('approve_')) {
      final approvalId = data.replaceFirst('approve_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Processing...');
      try {
        final result = await approveDraftInvoice(approvalId: approvalId, reviewedBy: chatId.toString());
        if (result['success'] == true) {
          final pdf = await InvoicePdfGenerator.generateApprovedInvoicePdf(
              approvalId: approvalId,
              invoiceNumber: result['invoiceNumber'] as String,
          );
          await bot.sendDocument(chatId, pdf.file, caption: pdf.caption);
          await bot.editMessageText('${result['message'] as String}\n\n📄 PDF process complete.',
              chatId: chatId, messageId: msgId, parseMode: 'Markdown');
          
          // Post-sale notification
          try {
            final draftData = await getApprovalDetails(approvalId);
            if (draftData != null) {
               final approval = DraftApproval.fromJson(draftData);
               String notification = '✅ *Post-Sale Summary*\n\n📦 *Remaining Stock:*\n';
               for (final item in approval.proposedItems) {
                 try {
                   final pRes = await supabase.from('products').select('name, stock_quantity').eq('id', item.productId).single();
                   notification += '• ${(pRes as Map)['name'] ?? 'Product'}: ${(pRes)['stock_quantity'] ?? 0} left\n';
                 } catch (_) {}
               }
               await bot.sendMessage(chatId, notification, parseMode: 'Markdown');
            }
          } catch (_) {}
        } else {
          await bot.sendMessage(chatId, '❌ *Approval Failed*\n\n${result['error']}', parseMode: 'Markdown');
        }
      } catch (e) { stderr.writeln('Approval error: $e'); }
    } else if (data.startsWith('reject_')) {
      final approvalId = data.replaceFirst('reject_', '');
      pendingRejections[chatId] = approvalId;
      await bot.editMessageText('❌ *Rejection*\n\nPlease type the reason for rejecting this invoice:',
          chatId: chatId, messageId: msgId, parseMode: 'Markdown');
      await bot.answerCallbackQuery(query.id);
    } else if (data.startsWith('gst_igst_')) {
      final approvalId = data.replaceFirst('gst_igst_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Switching to IGST...');
      final result = await switchGstType(approvalId: approvalId, newGstType: 'IGST');
      if (result['success'] == true) {
        final draftData = await getApprovalDetails(approvalId);
        if (draftData != null) {
          final msg = await _buildInvoiceMessage(draftData);
          await bot.editMessageText(msg, chatId: chatId, messageId: msgId, parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, 'IGST', true));
        }
      }
    } else if (data.startsWith('gst_cgst_')) {
      final approvalId = data.replaceFirst('gst_cgst_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Switching to CGST/SGST...');
      final result = await switchGstType(approvalId: approvalId, newGstType: 'CGST_SGST');
      if (result['success'] == true) {
        final draftData = await getApprovalDetails(approvalId);
        if (draftData != null) {
          final msg = await _buildInvoiceMessage(draftData);
          await bot.editMessageText(msg, chatId: chatId, messageId: msgId, parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, 'CGST_SGST', true));
        }
      }
    } else if (data.startsWith('pay_paid_') || data.startsWith('pay_partial_') || data.startsWith('pay_unpaid_')) {
      final approvalId = data.replaceFirst(RegExp(r'^pay_(paid|partial|unpaid)_'), '');
      final paymentStatus = data.contains('_paid_') ? 'PAID' : data.contains('_partial_') ? 'PARTIAL' : 'UNPAID';
      if (paymentStatus == 'PARTIAL') {
        pendingPartialPaymentEdits[chatId] = approvalId;
        await bot.answerCallbackQuery(query.id);
        await bot.editMessageText('🕒 Send the *paid amount* now (example: *400* or *₹400*).',
            chatId: chatId, messageId: msgId, parseMode: 'Markdown');
        return;
      }
      await bot.answerCallbackQuery(query.id, text: '⏳ Updating payment status...');
      final result = await updateDraftPaymentStatus(approvalId: approvalId, paymentStatus: paymentStatus);
      if (result['success'] == true) {
        final draftData = await getApprovalDetails(approvalId);
        if (draftData != null) {
          final shopRows = await supabase.from('shops').select('gst_mode').eq('id', draftData['shop_id']).single();
          final isRegistered = (shopRows as Map)['gst_mode'] == 'REGISTERED';
          final formattedMessage = await _buildInvoiceMessage(draftData);
          await bot.editMessageText(formattedMessage, chatId: chatId, messageId: msgId, parseMode: 'Markdown',
              replyMarkup: _buildInvoiceKeyboard(approvalId, draftData['gst_type'] ?? 'CGST_SGST', isRegistered));
        }
      }
    } else if (data.startsWith('edit_discount_')) {
      final approvalId = data.replaceFirst('edit_discount_', '');
      pendingDiscountEdits[chatId] = approvalId;
      await bot.answerCallbackQuery(query.id);
      await bot.editMessageText('✏️ Send the new discount as *10%* or *₹50*.',
          chatId: chatId, messageId: msgId, parseMode: 'Markdown');
    } else if (data.startsWith('p_approve_')) {
      final batchId = data.replaceFirst('p_approve_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Adding to inventory...');
      final result = await approveProductBatch(batchId: batchId, reviewedBy: chatId.toString());
      await bot.editMessageText(result['message'] as String, chatId: chatId, messageId: msgId, parseMode: 'Markdown');
    } else if (data.startsWith('p_reject_')) {
      final batchId = data.replaceFirst('p_reject_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Rejecting...');
      final result = await rejectProductBatch(batchId: batchId, reviewedBy: chatId.toString());
      await bot.editMessageText(result['message'] as String, chatId: chatId, messageId: msgId, parseMode: 'Markdown');
    } else if (data.startsWith('d_approve_')) {
      final requestId = data.replaceFirst('d_approve_', '');
      await bot.answerCallbackQuery(query.id, text: '⏳ Deleting products...');
      final result = await approveProductDeletion(requestId: requestId, reviewedBy: chatId.toString());
      await bot.editMessageText(result['message'] as String, chatId: chatId, messageId: msgId, parseMode: 'Markdown');
    } else if (data.startsWith('d_reject_')) {
      final requestId = data.replaceFirst('d_reject_', '');
      pendingRejections[chatId] = 'delete:$requestId';
      await bot.editMessageText('❌ *Deletion Rejection*\n\nPlease type the reason for rejecting this product deletion request:',
          chatId: chatId, messageId: msgId, parseMode: 'Markdown');
      await bot.answerCallbackQuery(query.id);
    }
  }

  Future<void> _handleIncomingMessage(tg.TeleDartMessage message) async {
    final text = message.text?.trim() ?? '';
    if (text.isEmpty && message.photo == null) return;
    
    final chatId = message.chat.id;
    final userIdentifier = chatId.toString();

    // Onboarding check
    final onboarded = await _isUserOnboarded(chatId);
    final inOnboarding = isInOnboarding(chatId);

    if (inOnboarding) {
      final result = await processOnboardingText(chatId, text);
      if (result.text.isNotEmpty) {
        await bot.sendMessage(chatId, result.text, parseMode: 'Markdown', replyMarkup: result.keyboard);
      }
      return;
    }

    if (!onboarded && !text.startsWith('/start') && !text.startsWith('/login') && !text.startsWith('ob_')) {
      final result = await startOnboarding(chatId, message.from?.firstName ?? 'User');
      await bot.sendMessage(chatId, result.text, parseMode: 'Markdown', replyMarkup: result.keyboard);
      return;
    }

    // Handle Login Command
    if (text.startsWith('/login')) {
      await _handleLoginCode(chatId, userIdentifier);
      return;
    }

    // Handle rejections, edits, etc.
    if (pendingRejections.containsKey(chatId)) {
      final target = pendingRejections.remove(chatId)!;
      if (target.startsWith('delete:')) {
        final reqId = target.replaceFirst('delete:', '');
        final res = await rejectProductDeletion(requestId: reqId, rejectionReason: text, reviewedBy: userIdentifier);
        await bot.sendMessage(chatId, res['message'] as String);
      } else {
        final res = await rejectDraftInvoice(approvalId: target, rejectionReason: text, reviewedBy: userIdentifier);
        await bot.sendMessage(chatId, res['message'] as String);
      }
      return;
    }

    if (pendingDiscountEdits.containsKey(chatId)) {
      final approvalId = pendingDiscountEdits.remove(chatId)!;
      final discount = _parseDiscountText(text);
      if (discount != null) {
        final result = await updateDraftDiscount(approvalId: approvalId, discountType: discount['discountType'], discountValue: discount['discountValue']);
        if (result['success'] == true) {
          final draftData = await getApprovalDetails(approvalId);
          if (draftData != null) {
            final shopRows = await supabase.from('shops').select('gst_mode').eq('id', draftData['shop_id']).single();
            final isRegistered = (shopRows as Map)['gst_mode'] == 'REGISTERED';
            final msg = await _buildInvoiceMessage(draftData);
            await bot.sendMessage(chatId, '✅ Discount updated!\n\n$msg', parseMode: 'Markdown',
                replyMarkup: _buildInvoiceKeyboard(approvalId, draftData['gst_type'] ?? 'CGST_SGST', isRegistered));
          }
        } else { await bot.sendMessage(chatId, '❌ ${result['error']}'); }
      } else { await bot.sendMessage(chatId, '❌ Invalid format. Use *10%* or *₹50*.'); }
      return;
    }

    if (pendingPartialPaymentEdits.containsKey(chatId)) {
      final approvalId = pendingPartialPaymentEdits.remove(chatId)!;
      final amount = _parsePaidAmountText(text);
      if (amount != null) {
        final result = await updateDraftPaymentStatus(approvalId: approvalId, paymentStatus: 'PARTIAL', amountPaid: amount);
        if (result['success'] == true) {
           final draftData = await getApprovalDetails(approvalId);
           if (draftData != null) {
             final msg = await _buildInvoiceMessage(draftData);
             await bot.sendMessage(chatId, '✅ Partial payment recorded!\n\n$msg', parseMode: 'Markdown',
                 replyMarkup: _buildInvoiceKeyboard(approvalId, draftData['gst_type'] ?? 'CGST_SGST', true));
           }
        } else { await bot.sendMessage(chatId, '❌ ${result['error']}'); }
      } else { await bot.sendMessage(chatId, '❌ Invalid amount. Example: *₹400*.'); }
      return;
    }

    // AI Processing
    activeSessions.putIfAbsent(chatId, () => ChatSession(userIdentifier: userIdentifier));
    final session = activeSessions[chatId]!;
    final reply = await session.sendMessage(text);
    
    // Check for special cards (Approval ID, Batch ID, etc.)
    if (reply.contains('Approval ID:')) {
      final match = RegExp(r'Approval ID: ([\w-]+)').firstMatch(reply);
      if (match != null) {
        final approvalId = match.group(1)!;
        final draftData = await getApprovalDetails(approvalId);
        if (draftData != null) {
          final shopRows = await supabase.from('shops').select('gst_mode').eq('id', draftData['shop_id']).single();
          final isRegistered = (shopRows as Map)['gst_mode'] == 'REGISTERED';
          final msg = await _buildInvoiceMessage(draftData);
          await bot.sendMessage(chatId, msg, parseMode: 'Markdown', replyMarkup: _buildInvoiceKeyboard(approvalId, draftData['gst_type'] ?? 'CGST_SGST', isRegistered));
          return;
        }
      }
    }

    if (reply.contains('Batch ID:')) {
      final match = RegExp(r'Batch ID: ([\w-]+)').firstMatch(reply);
      if (match != null) {
        final batchId = match.group(1)!;
        final batchDetails = await getProductBatchDetails(batchId);
        if (batchDetails != null) {
          final products = batchDetails['proposed_products'] as List<dynamic>;
          final msg = _buildProductBatchMessage(batchId, products);
          await bot.sendMessage(chatId, msg, parseMode: 'Markdown', replyMarkup: tg.InlineKeyboardMarkup(
            inlineKeyboard: [[
              tg.InlineKeyboardButton(text: '❌ REJECT', callbackData: 'p_reject_$batchId'),
              tg.InlineKeyboardButton(text: '✅ APPROVE', callbackData: 'p_approve_$batchId'),
            ]]
          ));
          return;
        }
      }
    }

    await bot.sendMessage(chatId, reply, parseMode: 'Markdown');
  }

  // --- Helper Methods (Migrated from telegram_bot.dart) ---

  Future<bool> _isUserOnboarded(int chatId) async {
    try {
      final user = await supabase.from('users').select('id').eq('telegram_id', chatId).maybeSingle();
      if (user == null) return false;
      final shop = await supabase.from('shops').select('id').eq('owner_id', user['id']).eq('onboarding_completed', true).maybeSingle();
      return shop != null;
    } catch (_) { return false; }
  }

  Future<void> _handleLoginCode(int chatId, String userIdentifier) async {
    try {
      // Ensure user exists
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
      await supabase.from('login_codes').delete().eq('user_id', userId);

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
  }

  tg.InlineKeyboardMarkup _buildInvoiceKeyboard(String approvalId, String currentGstType, bool isRegistered) {
    final List<tg.InlineKeyboardButton> row1 = [];
    if (isRegistered) {
      row1.add(tg.InlineKeyboardButton(text: currentGstType == 'IGST' ? '🔄 Switch to CGST/SGST' : '🔄 Switch to IGST',
          callbackData: currentGstType == 'IGST' ? 'gst_cgst_$approvalId' : 'gst_igst_$approvalId'));
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
    return tg.InlineKeyboardMarkup(inlineKeyboard: isRegistered ? [row1, row2, row3] : [row2, row3]);
  }

  Future<String> _buildInvoiceMessage(Map<String, dynamic> draftData) async {
    final approval = DraftApproval.fromJson(draftData);
    final customerName = await _resolveDraftCustomerName(draftData);
    final itemDescriptions = <String>[];
    for (final item in approval.proposedItems) {
      try {
        final pRes = await supabase.from('products').select('name').eq('id', item.productId).single();
        itemDescriptions.add('${item.quantity}x ${(pRes as Map)['name'] ?? item.productId} @ ₹${item.unitPrice.toStringAsFixed(2)}');
      } catch (_) { itemDescriptions.add('${item.quantity}x ${item.productId}'); }
    }
    return ApprovalFormatter.formatApprovalMessage(
      approval: approval,
      customerName: customerName,
      itemDescriptions: itemDescriptions,
      paymentStatus: draftData['payment_status']?.toString(),
      amountPaid: (draftData['amount_paid'] as num?)?.toDouble(),
      dueAmount: (draftData['due_amount'] as num?)?.toDouble(),
      discountType: draftData['discount_type']?.toString(),
      discountValue: (draftData['discount_value'] as num?)?.toDouble(),
      discountAmount: (draftData['discount_amount'] as num?)?.toDouble(),
      subtotalBeforeDiscount: (draftData['subtotal_before_discount'] as num?)?.toDouble(),
      subtotalAfterDiscount: (draftData['subtotal_after_discount'] as num?)?.toDouble(),
    );
  }

  Future<String> _resolveDraftCustomerName(Map<String, dynamic> draftData) async {
    final explicitName = draftData['customer_name']?.toString().trim();
    if (explicitName != null && explicitName.isNotEmpty) return explicitName;
    final customerId = draftData['customer_id']?.toString();
    if (customerId == null || customerId.isEmpty) return 'Walk-in Customer';
    try {
      final customerRows = await supabase.from('customers').select('name').eq('id', customerId).single();
      return (customerRows as Map)['name'] ?? 'Walk-in Customer';
    } catch (_) { return 'Walk-in Customer'; }
  }

  String _buildProductBatchMessage(String batchId, List<dynamic> products) {
    final itemLines = products.take(10).map((p) => '• ${p['name']} | ₹${p['price']} | Stock: ${p['stock_quantity']}').join('\n');
    return '📦 *Product Draft Created*\n\n$itemLines\n\nBatch ID: $batchId\n\nApprove these to add to inventory.';
  }

  Map<String, dynamic>? _parseDiscountText(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.endsWith('%')) return {'discountType': 'PERCENT', 'discountValue': double.tryParse(normalized.replaceAll('%', ''))};
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
    if (amountMatch != null) return {'discountType': 'AMOUNT', 'discountValue': double.parse(amountMatch.group(1)!)};
    return null;
  }

  double? _parsePaidAmountText(String input) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(input);
    return match != null ? double.parse(match.group(1)!) : null;
  }

  void _startReminderProcessor() {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        final now = DateTime.now().toUtc().toIso8601String();
        final dueReminders = await supabase.from('reminders').select().eq('status', 'PENDING').lte('scheduled_at', now);
        for (final row in dueReminders as List) {
          final data = Map<String, dynamic>.from(row as Map);
          await bot.sendMessage(data['chat_id'] as int, '⏰ *REMINDER*\n\n${data['reminder_text']}', parseMode: 'Markdown');
          await supabase.from('reminders').update({'status': 'SENT'}).eq('id', data['id']);
        }
      } catch (e) { stderr.writeln('[reminders-error] $e'); }
    });
  }
}

class ChatSession {
  final String userIdentifier;
  final List<Message> _history = [];
  final String model;

  ChatSession({required this.userIdentifier, String? model}) : model = model ?? modelId;

  Future<String> sendMessage(String text) async {
    _history.add(Message(role: Role.user, content: [TextPart(text: text)]));
    
    // Simple intent routing
    List<String> selectedTools = [];
    final n = text.toLowerCase();
    if (n.contains('bill') || n.contains('invoice')) selectedTools = ['createDraftInvoice'];
    else if (n.contains('revenue') || n.contains('analytics')) selectedTools = ['businessInsightsTool'];
    else if (n.contains('add product')) selectedTools = ['proposeProducts'];
    else if (n.contains('delete')) selectedTools = ['deleteProduct'];
    else if (n.contains('due') || n.contains('balance')) selectedTools = ['checkCustomerDue', 'listCustomersDue'];

    final response = await ai.generate(
      model: appModel(model),
      messages: [
        Message(role: Role.system, content: [TextPart(text: TelegramService._systemPrompt)]),
        ..._history,
      ],
      toolNames: selectedTools.isNotEmpty ? selectedTools : null,
      context: {'userIdentifier': userIdentifier},
    );
    final reply = response.text.trim();
    _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
    return reply;
  }
}
