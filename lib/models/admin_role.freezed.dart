// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_role.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AdminRole _$AdminRoleFromJson(Map<String, dynamic> json) {
  return _AdminRole.fromJson(json);
}

/// @nodoc
mixin _$AdminRole {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'role_name')
  String get roleName => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this AdminRole to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminRole
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminRoleCopyWith<AdminRole> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminRoleCopyWith<$Res> {
  factory $AdminRoleCopyWith(AdminRole value, $Res Function(AdminRole) then) =
      _$AdminRoleCopyWithImpl<$Res, AdminRole>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'role_name') String roleName,
    String? description,
    @JsonKey(name: 'created_at') String createdAt,
    @JsonKey(name: 'updated_at') String updatedAt,
  });
}

/// @nodoc
class _$AdminRoleCopyWithImpl<$Res, $Val extends AdminRole>
    implements $AdminRoleCopyWith<$Res> {
  _$AdminRoleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminRole
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? roleName = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            roleName: null == roleName
                ? _value.roleName
                : roleName // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AdminRoleImplCopyWith<$Res>
    implements $AdminRoleCopyWith<$Res> {
  factory _$$AdminRoleImplCopyWith(
    _$AdminRoleImpl value,
    $Res Function(_$AdminRoleImpl) then,
  ) = __$$AdminRoleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'role_name') String roleName,
    String? description,
    @JsonKey(name: 'created_at') String createdAt,
    @JsonKey(name: 'updated_at') String updatedAt,
  });
}

/// @nodoc
class __$$AdminRoleImplCopyWithImpl<$Res>
    extends _$AdminRoleCopyWithImpl<$Res, _$AdminRoleImpl>
    implements _$$AdminRoleImplCopyWith<$Res> {
  __$$AdminRoleImplCopyWithImpl(
    _$AdminRoleImpl _value,
    $Res Function(_$AdminRoleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AdminRole
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? roleName = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$AdminRoleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        roleName: null == roleName
            ? _value.roleName
            : roleName // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminRoleImpl implements _AdminRole {
  const _$AdminRoleImpl({
    required this.id,
    @JsonKey(name: 'role_name') required this.roleName,
    required this.description,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
  });

  factory _$AdminRoleImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminRoleImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'role_name')
  final String roleName;
  @override
  final String? description;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  @override
  String toString() {
    return 'AdminRole(id: $id, roleName: $roleName, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminRoleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.roleName, roleName) ||
                other.roleName == roleName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, roleName, description, createdAt, updatedAt);

  /// Create a copy of AdminRole
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminRoleImplCopyWith<_$AdminRoleImpl> get copyWith =>
      __$$AdminRoleImplCopyWithImpl<_$AdminRoleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminRoleImplToJson(this);
  }
}

abstract class _AdminRole implements AdminRole {
  const factory _AdminRole({
    required final String id,
    @JsonKey(name: 'role_name') required final String roleName,
    required final String? description,
    @JsonKey(name: 'created_at') required final String createdAt,
    @JsonKey(name: 'updated_at') required final String updatedAt,
  }) = _$AdminRoleImpl;

  factory _AdminRole.fromJson(Map<String, dynamic> json) =
      _$AdminRoleImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'role_name')
  String get roleName;
  @override
  String? get description;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;

  /// Create a copy of AdminRole
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminRoleImplCopyWith<_$AdminRoleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
