class CartItem {
  final String productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final double gstRate;

  const CartItem({
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    this.gstRate = 18.0,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      gstRate: (json['gstRate'] as num?)?.toDouble() ?? 18.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      if (productName != null) 'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'gstRate': gstRate,
    };
  }

  CartItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? gstRate,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      gstRate: gstRate ?? this.gstRate,
    );
  }
}
