// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Customer _$CustomerFromJson(Map<String, dynamic> json) => _Customer(
  id: json['id'] as String,
  shopId: json['shop_id'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  currentBalance: (json['current_balance'] as num).toDouble(),
);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'shop_id': instance.shopId,
  'name': instance.name,
  'phone': instance.phone,
  'current_balance': instance.currentBalance,
};
