import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../../../core/session.dart';
import '../models/ai_intent.dart';
import '../../../services/intent_executor.dart';
import '../../../data/local/local_database.dart';

final chatControllerProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  return ChatController();
});

class ChatController extends StateNotifier<List<ChatMessage>> {
  final _uuid = const Uuid();
  final String _sessionId = const Uuid().v4();

  ChatController() : super([
    ChatMessage(
      id: const Uuid().v4(),
      text: "Hi! I'm Dukan Sathi Pro. How can I help you manage your shop today?",
      type: MessageType.aiText,
    ),
  ]);

  Future<void> loadHistory() async {
    final shopId = UserSession().shopId;
    if (shopId == null || shopId.isEmpty) return;

    try {
      final rows = await LocalDatabase.instance.queryAll(
        'chat_messages',
        where: 'shop_id = ?',
        whereArgs: [shopId],
        orderBy: 'timestamp ASC',
      );

      if (rows.isNotEmpty) {
        final messages = rows.map((r) {
          final payloadStr = r['payload'] as String?;
          final payload = payloadStr != null ? jsonDecode(payloadStr) : null;
          
          final typeStr = r['type'] as String;
          final type = MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == typeStr,
            orElse: () => MessageType.aiText,
          );

          return ChatMessage(
            id: r['id'] as String,
            text: r['text'] as String,
            type: type,
            payload: payload,
            isTyping: false,
          );
        }).toList();

        state = messages;
      }
    } catch (e) {
      debugPrint('[ChatController] Failed to load chat history: $e');
    }
  }

  Future<void> _saveMessageToDb(ChatMessage msg) async {
    if (msg.isTyping) return;
    
    final shopId = UserSession().shopId;
    if (shopId == null || shopId.isEmpty) return;

    try {
      await LocalDatabase.instance.insert('chat_messages', {
        'id': msg.id,
        'shop_id': shopId,
        'text': msg.text,
        'type': msg.type.toString().split('.').last,
        'payload': msg.payload != null ? jsonEncode(msg.payload) : null,
        'is_typing': 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[ChatController] Failed to save message to SQLite: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add User Message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      type: MessageType.user,
    );
    state = [...state, userMsg];
    _saveMessageToDb(userMsg);

    // 2. Add "Typing" Indicator
    final typingId = _uuid.v4();
    state = [
      ...state,
      ChatMessage(
        id: typingId,
        text: "...",
        type: MessageType.aiText,
        isTyping: true,
      ),
    ];

    try {
      // 3. Use the SMART /api/chat endpoint (same capabilities as Telegram bot)
      final response = await http.post(
        Uri.parse('/api/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'input': text,
          'sessionId': _sessionId,
          'shopId': UserSession().shopId,
          'userId': UserSession().userId,
        }),
      );

      // Remove typing indicator
      state = state.where((m) => m.id != typingId).toList();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['text'] as String? ?? '';
        final card = data['card'] as Map<String, dynamic>?;

        // Determine card type and payload
        MessageType? cardType;
        Map<String, dynamic>? cardPayload = card;

        if (data['intent'] != null) {
          final intent = AiIntent.fromJson(Map<String, dynamic>.from(data['intent']));
          final executorResult = await IntentExecutor().execute(intent);

          if (executorResult['success'] == true) {
            if (executorResult['type'] == 'ADD_PRODUCT_CONFIRMATION') {
              cardType = MessageType.aiDraftInventory;
              cardPayload = executorResult;
            } else if (executorResult['type'] == 'INVOICE_DRAFT') {
              cardType = MessageType.aiDraftInvoice;
              // draft is already the toJson() output of DraftApproval — pass directly
              cardPayload = executorResult['draft'] as Map<String, dynamic>?;
            }
          }
        } else if (card != null) {
          final type = card['type'] as String?;
          if (type == 'inventory' || type == 'batch') {
            cardType = MessageType.aiDraftInventory;
            cardPayload = card;
          } else if (type == 'invoice') {
            cardType = MessageType.aiDraftInvoice;
            // Normalize: server may wrap under 'draft', 'payload', or directly in card
            final nested = card['draft'] ?? card['payload'] ?? card['data'];
            cardPayload = (nested is Map<String, dynamic>) ? nested : card;
          } else if (type == 'analytics_summary') {
            cardType = MessageType.aiAnalyticsSummary;
            cardPayload = card['data'] as Map<String, dynamic>?;
          } else if (type == 'customer_dues_list') {
            cardType = MessageType.aiCustomerDuesList;
            cardPayload = card['data'] as Map<String, dynamic>?;
          } else if (type == 'customer_due_detail') {
            cardType = MessageType.aiCustomerDueDetail;
            cardPayload = card['data'] as Map<String, dynamic>?;
          } else if (type == 'expense_report') {
            cardType = MessageType.aiExpenseReport;
            cardPayload = card['data'] as Map<String, dynamic>?;
          } else if (type == 'invoice_lookup') {
            cardType = MessageType.aiInvoiceLookup;
            cardPayload = card['data'] as Map<String, dynamic>?;
          } else if (type == 'product_catalog') {
            cardType = MessageType.aiProductCatalog;
            cardPayload = card['data'] as Map<String, dynamic>?;
          } else if (type == 'payment_confirmation') {
            cardType = MessageType.aiPaymentConfirmation;
            cardPayload = card['data'] as Map<String, dynamic>?;
          }
        }

        final aiTextMsg = ChatMessage(
          id: _uuid.v4(),
          text: aiText,
          type: MessageType.aiText,
        );

        ChatMessage? aiCardMsg;
        if (cardType != null && cardPayload != null) {
          aiCardMsg = ChatMessage(
            id: _uuid.v4(),
            text: "",
            type: cardType,
            payload: cardPayload,
          );
        }

        state = [
          ...state,
          aiTextMsg,
          if (aiCardMsg != null) aiCardMsg,
        ];

        _saveMessageToDb(aiTextMsg);
        if (aiCardMsg != null) {
          _saveMessageToDb(aiCardMsg);
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Remove typing indicator and show error
      state = state.where((m) => m.id != typingId).toList();
      state = [
        ...state,
        ChatMessage(
          id: _uuid.v4(),
          text: "Sorry, I couldn't reach the AI server right now. Is genkit_server running?",
          type: MessageType.aiText,
        ),
      ];
    }
  }
}
