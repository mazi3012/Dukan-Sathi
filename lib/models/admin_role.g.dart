// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminRole _$AdminRoleFromJson(Map<String, dynamic> json) => _AdminRole(
  id: json['id'] as String,
  roleName: json['role_name'] as String,
  description: json['description'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$AdminRoleToJson(_AdminRole instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role_name': instance.roleName,
      'description': instance.description,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
