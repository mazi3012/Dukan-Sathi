import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../../../core/session.dart';
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
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    // 1. Add User Message
    state = [
      ...state,
      ChatMessage(
        id: _uuid.v4(),
        text: text,
        type: MessageType.user,
      ),
    ];
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
        Uri.parse('http://localhost:3100/api/chat'),
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
        // Determine card type from structured backend response
        MessageType? cardType;
        if (card != null) {
          final type = card['type'] as String?;
          if (type == 'inventory' || type == 'batch') {
            cardType = MessageType.aiDraftInventory;
          } else if (type == 'invoice') {
            cardType = MessageType.aiDraftInvoice;
          }
        }
        state = [
          ...state,
          ChatMessage(
            id: _uuid.v4(),
            text: aiText,
            type: MessageType.aiText,
          ),
          if (cardType != null)
            ChatMessage(
              id: _uuid.v4(),
              text: "",
              type: cardType,
              payload: card,
            ),
        ];
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
