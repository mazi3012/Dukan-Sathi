import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_session.freezed.dart';
part 'admin_session.g.dart';

@freezed
abstract class AdminSession with _$AdminSession {
  const factory AdminSession({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'token_hash') required String tokenHash,
    @JsonKey(name: 'ip_address') required String? ipAddress,
    @JsonKey(name: 'user_agent') required String? userAgent,
    @JsonKey(name: 'expires_at') required String expiresAt,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _AdminSession;

  factory AdminSession.fromJson(Map<String, dynamic> json) => _$AdminSessionFromJson(json);
}
