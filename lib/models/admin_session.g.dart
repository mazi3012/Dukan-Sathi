// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminSession _$AdminSessionFromJson(Map<String, dynamic> json) =>
    _AdminSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tokenHash: json['token_hash'] as String,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      expiresAt: json['expires_at'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$AdminSessionToJson(_AdminSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'token_hash': instance.tokenHash,
      'ip_address': instance.ipAddress,
      'user_agent': instance.userAgent,
      'expires_at': instance.expiresAt,
      'created_at': instance.createdAt,
    };
