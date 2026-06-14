// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_audit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AdminAuditLog _$AdminAuditLogFromJson(Map<String, dynamic> json) {
  return _AdminAuditLog.fromJson(json);
}

/// @nodoc
mixin _$AdminAuditLog {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String get resource => throw _privateConstructorUsedError;
  @JsonKey(name: 'resource_id')
  String? get resourceId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get changes => throw _privateConstructorUsedError;
  @JsonKey(name: 'ip_address')
  String? get ipAddress => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'error_message')
  String? get errorMessage => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AdminAuditLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminAuditLogCopyWith<AdminAuditLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminAuditLogCopyWith<$Res> {
  factory $AdminAuditLogCopyWith(
    AdminAuditLog value,
    $Res Function(AdminAuditLog) then,
  ) = _$AdminAuditLogCopyWithImpl<$Res, AdminAuditLog>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String? userId,
    String action,
    String resource,
    @JsonKey(name: 'resource_id') String? resourceId,
    Map<String, dynamic>? changes,
    @JsonKey(name: 'ip_address') String? ipAddress,
    String status,
    @JsonKey(name: 'error_message') String? errorMessage,
    @JsonKey(name: 'created_at') String createdAt,
  });
}

/// @nodoc
class _$AdminAuditLogCopyWithImpl<$Res, $Val extends AdminAuditLog>
    implements $AdminAuditLogCopyWith<$Res> {
  _$AdminAuditLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? action = null,
    Object? resource = null,
    Object? resourceId = freezed,
    Object? changes = freezed,
    Object? ipAddress = freezed,
    Object? status = null,
    Object? errorMessage = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String?,
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            resource: null == resource
                ? _value.resource
                : resource // ignore: cast_nullable_to_non_nullable
                      as String,
            resourceId: freezed == resourceId
                ? _value.resourceId
                : resourceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            changes: freezed == changes
                ? _value.changes
                : changes // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            ipAddress: freezed == ipAddress
                ? _value.ipAddress
                : ipAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$AdminAuditLogImplCopyWith<$Res>
    implements $AdminAuditLogCopyWith<$Res> {
  factory _$$AdminAuditLogImplCopyWith(
    _$AdminAuditLogImpl value,
    $Res Function(_$AdminAuditLogImpl) then,
  ) = __$$AdminAuditLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String? userId,
    String action,
    String resource,
    @JsonKey(name: 'resource_id') String? resourceId,
    Map<String, dynamic>? changes,
    @JsonKey(name: 'ip_address') String? ipAddress,
    String status,
    @JsonKey(name: 'error_message') String? errorMessage,
    @JsonKey(name: 'created_at') String createdAt,
  });
}

/// @nodoc
class __$$AdminAuditLogImplCopyWithImpl<$Res>
    extends _$AdminAuditLogCopyWithImpl<$Res, _$AdminAuditLogImpl>
    implements _$$AdminAuditLogImplCopyWith<$Res> {
  __$$AdminAuditLogImplCopyWithImpl(
    _$AdminAuditLogImpl _value,
    $Res Function(_$AdminAuditLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? action = null,
    Object? resource = null,
    Object? resourceId = freezed,
    Object? changes = freezed,
    Object? ipAddress = freezed,
    Object? status = null,
    Object? errorMessage = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$AdminAuditLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        resource: null == resource
            ? _value.resource
            : resource // ignore: cast_nullable_to_non_nullable
                  as String,
        resourceId: freezed == resourceId
            ? _value.resourceId
            : resourceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        changes: freezed == changes
            ? _value._changes
            : changes // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        ipAddress: freezed == ipAddress
            ? _value.ipAddress
            : ipAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$AdminAuditLogImpl implements _AdminAuditLog {
  const _$AdminAuditLogImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    required this.action,
    required this.resource,
    @JsonKey(name: 'resource_id') required this.resourceId,
    required final Map<String, dynamic>? changes,
    @JsonKey(name: 'ip_address') required this.ipAddress,
    required this.status,
    @JsonKey(name: 'error_message') required this.errorMessage,
    @JsonKey(name: 'created_at') required this.createdAt,
  }) : _changes = changes;

  factory _$AdminAuditLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminAuditLogImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
  @override
  final String action;
  @override
  final String resource;
  @override
  @JsonKey(name: 'resource_id')
  final String? resourceId;
  final Map<String, dynamic>? _changes;
  @override
  Map<String, dynamic>? get changes {
    final value = _changes;
    if (value == null) return null;
    if (_changes is EqualUnmodifiableMapView) return _changes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'ip_address')
  final String? ipAddress;
  @override
  final String status;
  @override
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;

  @override
  String toString() {
    return 'AdminAuditLog(id: $id, userId: $userId, action: $action, resource: $resource, resourceId: $resourceId, changes: $changes, ipAddress: $ipAddress, status: $status, errorMessage: $errorMessage, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminAuditLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.resource, resource) ||
                other.resource == resource) &&
            (identical(other.resourceId, resourceId) ||
                other.resourceId == resourceId) &&
            const DeepCollectionEquality().equals(other._changes, _changes) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    action,
    resource,
    resourceId,
    const DeepCollectionEquality().hash(_changes),
    ipAddress,
    status,
    errorMessage,
    createdAt,
  );

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminAuditLogImplCopyWith<_$AdminAuditLogImpl> get copyWith =>
      __$$AdminAuditLogImplCopyWithImpl<_$AdminAuditLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminAuditLogImplToJson(this);
  }
}

abstract class _AdminAuditLog implements AdminAuditLog {
  const factory _AdminAuditLog({
    required final String id,
    @JsonKey(name: 'user_id') required final String? userId,
    required final String action,
    required final String resource,
    @JsonKey(name: 'resource_id') required final String? resourceId,
    required final Map<String, dynamic>? changes,
    @JsonKey(name: 'ip_address') required final String? ipAddress,
    required final String status,
    @JsonKey(name: 'error_message') required final String? errorMessage,
    @JsonKey(name: 'created_at') required final String createdAt,
  }) = _$AdminAuditLogImpl;

  factory _AdminAuditLog.fromJson(Map<String, dynamic> json) =
      _$AdminAuditLogImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String? get userId;
  @override
  String get action;
  @override
  String get resource;
  @override
  @JsonKey(name: 'resource_id')
  String? get resourceId;
  @override
  Map<String, dynamic>? get changes;
  @override
  @JsonKey(name: 'ip_address')
  String? get ipAddress;
  @override
  String get status;
  @override
  @JsonKey(name: 'error_message')
  String? get errorMessage;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;

  /// Create a copy of AdminAuditLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminAuditLogImplCopyWith<_$AdminAuditLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
