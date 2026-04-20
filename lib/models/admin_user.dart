import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_user.freezed.dart';
part 'admin_user.g.dart';

@freezed
abstract class AdminUser with _$AdminUser {
  const factory AdminUser({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') required String? fullName,
    required String? phone,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'role_id') required String roleId,
    @JsonKey(name: 'shop_id') required String? shopId,
    @JsonKey(name: 'last_login') required String? lastLogin,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) => _$AdminUserFromJson(json);
}
