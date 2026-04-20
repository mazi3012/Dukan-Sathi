import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_permission.freezed.dart';
part 'admin_permission.g.dart';

@freezed
abstract class AdminPermission with _$AdminPermission {
  const factory AdminPermission({
    required String id,
    @JsonKey(name: 'permission_name') required String permissionName,
    required String? description,
    required String resource,
    required String action,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _AdminPermission;

  factory AdminPermission.fromJson(Map<String, dynamic> json) => _$AdminPermissionFromJson(json);
}
