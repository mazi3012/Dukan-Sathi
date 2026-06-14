// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AdminRoleImpl _$$AdminRoleImplFromJson(Map<String, dynamic> json) =>
    _$AdminRoleImpl(
      id: json['id'] as String,
      roleName: json['role_name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$AdminRoleImplToJson(_$AdminRoleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role_name': instance.roleName,
      'description': instance.description,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
