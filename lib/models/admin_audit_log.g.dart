// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminAuditLog _$AdminAuditLogFromJson(Map<String, dynamic> json) =>
    _AdminAuditLog(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      action: json['action'] as String,
      resource: json['resource'] as String,
      resourceId: json['resource_id'] as String?,
      changes: json['changes'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$AdminAuditLogToJson(_AdminAuditLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'action': instance.action,
      'resource': instance.resource,
      'resource_id': instance.resourceId,
      'changes': instance.changes,
      'ip_address': instance.ipAddress,
      'status': instance.status,
      'error_message': instance.errorMessage,
      'created_at': instance.createdAt,
    };
