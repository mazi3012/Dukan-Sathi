// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_permission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminPermission _$AdminPermissionFromJson(Map<String, dynamic> json) =>
    _AdminPermission(
      id: json['id'] as String,
      permissionName: json['permission_name'] as String,
      description: json['description'] as String?,
      resource: json['resource'] as String,
      action: json['action'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$AdminPermissionToJson(_AdminPermission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'permission_name': instance.permissionName,
      'description': instance.description,
      'resource': instance.resource,
      'action': instance.action,
      'created_at': instance.createdAt,
    };
