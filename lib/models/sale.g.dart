// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sale _$SaleFromJson(Map<String, dynamic> json) => _Sale(
  id: json['id'] as String,
  shopId: json['shop_id'] as String,
  invoiceId: json['invoice_id'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  paymentMethod: json['payment_method'] as String,
);

Map<String, dynamic> _$SaleToJson(_Sale instance) => <String, dynamic>{
  'id': instance.id,
  'shop_id': instance.shopId,
  'invoice_id': instance.invoiceId,
  'timestamp': instance.timestamp.toIso8601String(),
  'payment_method': instance.paymentMethod,
};
