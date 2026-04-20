import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_audit_log.freezed.dart';
part 'admin_audit_log.g.dart';

@freezed
abstract class AdminAuditLog with _$AdminAuditLog {
  const factory AdminAuditLog({
    required String id,
    @JsonKey(name: 'user_id') required String? userId,
    required String action,
    required String resource,
    @JsonKey(name: 'resource_id') required String? resourceId,
    required Map<String, dynamic>? changes,
    @JsonKey(name: 'ip_address') required String? ipAddress,
    required String status,
    @JsonKey(name: 'error_message') required String? errorMessage,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _AdminAuditLog;

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) => _$AdminAuditLogFromJson(json);
}
