enum AiIntentType {
  addProduct,
  createInvoice,
  unknown,
}

class AiIntent {
  final AiIntentType type;
  final Map<String, dynamic> payload;

  AiIntent({
    required this.type,
    required this.payload,
  });

  factory AiIntent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString().toUpperCase();
    AiIntentType type;
    switch (typeStr) {
      case 'ADD_PRODUCT':
        type = AiIntentType.addProduct;
        break;
      case 'CREATE_INVOICE':
        type = AiIntentType.createInvoice;
        break;
      default:
        type = AiIntentType.unknown;
    }

    return AiIntent(
      type: type,
      payload: Map<String, dynamic>.from(json['payload'] ?? json['entities'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == AiIntentType.addProduct
          ? 'ADD_PRODUCT'
          : type == AiIntentType.createInvoice
              ? 'CREATE_INVOICE'
              : 'UNKNOWN',
      'payload': payload,
    };
  }
}
