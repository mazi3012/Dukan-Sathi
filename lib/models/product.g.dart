// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  shopId: json['shop_id'] as String,
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  stockQuantity: (json['stock_quantity'] as num).toInt(),
  category: json['category'] as String,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'shop_id': instance.shopId,
  'name': instance.name,
  'price': instance.price,
  'stock_quantity': instance.stockQuantity,
  'category': instance.category,
};
