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
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
