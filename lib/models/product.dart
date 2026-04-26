import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    @JsonKey(name: 'shop_id') required String shopId,
    required String name,
    required double price,
    @JsonKey(name: 'stock_quantity') required int stockQuantity,
    required String category,
    String? description,
    @JsonKey(name: 'is_service') @Default(false) bool isService,
    @JsonKey(name: 'gst_rate') @Default(0) double gstRate,
    @JsonKey(name: 'hsn_sac_code') String? hsnSacCode,
    @JsonKey(name: 'cost_price') @Default(0) double costPrice,
    @Default({}) Map<String, dynamic> metadata,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
