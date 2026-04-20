import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_role.freezed.dart';
part 'admin_role.g.dart';

@freezed
abstract class AdminRole with _$AdminRole {
  const factory AdminRole({
    required String id,
    @JsonKey(name: 'role_name') required String roleName,
    required String? description,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _AdminRole;

  factory AdminRole.fromJson(Map<String, dynamic> json) => _$AdminRoleFromJson(json);
}
