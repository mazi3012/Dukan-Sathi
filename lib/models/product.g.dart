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
  description: json['description'] as String?,
  isService: json['is_service'] as bool? ?? false,
  gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 0,
  hsnSacCode: json['hsn_sac_code'] as String?,
  costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'shop_id': instance.shopId,
  'name': instance.name,
  'price': instance.price,
  'stock_quantity': instance.stockQuantity,
  'category': instance.category,
  'description': instance.description,
  'is_service': instance.isService,
  'gst_rate': instance.gstRate,
  'hsn_sac_code': instance.hsnSacCode,
  'cost_price': instance.costPrice,
  'metadata': instance.metadata,
};
