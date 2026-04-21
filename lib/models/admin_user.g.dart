// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminUser _$AdminUserFromJson(Map<String, dynamic> json) => _AdminUser(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String?,
  phone: json['phone'] as String?,
  isActive: json['is_active'] as bool,
  roleId: json['role_id'] as String,
  shopId: json['shop_id'] as String?,
  lastLogin: json['last_login'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$AdminUserToJson(_AdminUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'is_active': instance.isActive,
      'role_id': instance.roleId,
      'shop_id': instance.shopId,
      'last_login': instance.lastLogin,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
