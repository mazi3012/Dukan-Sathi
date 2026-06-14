// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_permission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AdminPermission _$AdminPermissionFromJson(Map<String, dynamic> json) {
  return _AdminPermission.fromJson(json);
}

/// @nodoc
mixin _$AdminPermission {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'permission_name')
  String get permissionName => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get resource => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AdminPermission to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminPermission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminPermissionCopyWith<AdminPermission> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminPermissionCopyWith<$Res> {
  factory $AdminPermissionCopyWith(
    AdminPermission value,
    $Res Function(AdminPermission) then,
  ) = _$AdminPermissionCopyWithImpl<$Res, AdminPermission>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'permission_name') String permissionName,
    String? description,
    String resource,
    String action,
    @JsonKey(name: 'created_at') String createdAt,
  });
}

/// @nodoc
class _$AdminPermissionCopyWithImpl<$Res, $Val extends AdminPermission>
    implements $AdminPermissionCopyWith<$Res> {
  _$AdminPermissionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminPermission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? permissionName = null,
    Object? description = freezed,
    Object? resource = null,
    Object? action = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            permissionName: null == permissionName
                ? _value.permissionName
                : permissionName // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            resource: null == resource
                ? _value.resource
                : resource // ignore: cast_nullable_to_non_nullable
                      as String,
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AdminPermissionImplCopyWith<$Res>
    implements $AdminPermissionCopyWith<$Res> {
  factory _$$AdminPermissionImplCopyWith(
    _$AdminPermissionImpl value,
    $Res Function(_$AdminPermissionImpl) then,
  ) = __$$AdminPermissionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'permission_name') String permissionName,
    String? description,
    String resource,
    String action,
    @JsonKey(name: 'created_at') String createdAt,
  });
}

/// @nodoc
class __$$AdminPermissionImplCopyWithImpl<$Res>
    extends _$AdminPermissionCopyWithImpl<$Res, _$AdminPermissionImpl>
    implements _$$AdminPermissionImplCopyWith<$Res> {
  __$$AdminPermissionImplCopyWithImpl(
    _$AdminPermissionImpl _value,
    $Res Function(_$AdminPermissionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AdminPermission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? permissionName = null,
    Object? description = freezed,
    Object? resource = null,
    Object? action = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$AdminPermissionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        permissionName: null == permissionName
            ? _value.permissionName
            : permissionName // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        resource: null == resource
            ? _value.resource
            : resource // ignore: cast_nullable_to_non_nullable
                  as String,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminPermissionImpl implements _AdminPermission {
  const _$AdminPermissionImpl({
    required this.id,
    @JsonKey(name: 'permission_name') required this.permissionName,
    required this.description,
    required this.resource,
    required this.action,
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$AdminPermissionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminPermissionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'permission_name')
  final String permissionName;
  @override
  final String? description;
  @override
  final String resource;
  @override
  final String action;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;

  @override
  String toString() {
    return 'AdminPermission(id: $id, permissionName: $permissionName, description: $description, resource: $resource, action: $action, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminPermissionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.permissionName, permissionName) ||
                other.permissionName == permissionName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.resource, resource) ||
                other.resource == resource) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    permissionName,
    description,
    resource,
    action,
    createdAt,
  );

  /// Create a copy of AdminPermission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminPermissionImplCopyWith<_$AdminPermissionImpl> get copyWith =>
      __$$AdminPermissionImplCopyWithImpl<_$AdminPermissionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminPermissionImplToJson(this);
  }
}

abstract class _AdminPermission implements AdminPermission {
  const factory _AdminPermission({
    required final String id,
    @JsonKey(name: 'permission_name') required final String permissionName,
    required final String? description,
    required final String resource,
    required final String action,
    @JsonKey(name: 'created_at') required final String createdAt,
  }) = _$AdminPermissionImpl;

  factory _AdminPermission.fromJson(Map<String, dynamic> json) =
      _$AdminPermissionImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'permission_name')
  String get permissionName;
  @override
  String? get description;
  @override
  String get resource;
  @override
  String get action;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;

  /// Create a copy of AdminPermission
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminPermissionImplCopyWith<_$AdminPermissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
