// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShopConfig _$ShopConfigFromJson(Map<String, dynamic> json) => _ShopConfig(
  shopId: json['shopId'] as String,
  gstRegistrationNumber: json['gst_registration_number'] as String?,
  state: json['state'] as String,
  gstMode: $enumDecode(_$GSTModeEnumMap, json['gst_mode']),
  businessType: json['business_type'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ShopConfigToJson(_ShopConfig instance) =>
    <String, dynamic>{
      'shopId': instance.shopId,
      'gst_registration_number': instance.gstRegistrationNumber,
      'state': instance.state,
      'gst_mode': _$GSTModeEnumMap[instance.gstMode]!,
      'business_type': instance.businessType,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$GSTModeEnumMap = {
  GSTMode.registered: 'REGISTERED',
  GSTMode.unregistered: 'UNREGISTERED',
  GSTMode.composite: 'COMPOSITE',
};
