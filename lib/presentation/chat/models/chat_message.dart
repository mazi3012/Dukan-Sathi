enum MessageType { user, aiText, aiDraftInvoice, aiDraftExpense, aiDraftInventory }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final bool isTyping;
  final dynamic payload;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    this.isTyping = false,
    this.payload,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageType? type,
    bool? isTyping,
    dynamic payload,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      isTyping: isTyping ?? this.isTyping,
      payload: payload ?? this.payload,
    );
  }
}
