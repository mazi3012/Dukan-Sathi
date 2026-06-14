// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AdminSession _$AdminSessionFromJson(Map<String, dynamic> json) {
  return _AdminSession.fromJson(json);
}

/// @nodoc
mixin _$AdminSession {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'token_hash')
  String get tokenHash => throw _privateConstructorUsedError;
  @JsonKey(name: 'ip_address')
  String? get ipAddress => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_agent')
  String? get userAgent => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at')
  String get expiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AdminSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminSessionCopyWith<AdminSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminSessionCopyWith<$Res> {
  factory $AdminSessionCopyWith(
    AdminSession value,
    $Res Function(AdminSession) then,
  ) = _$AdminSessionCopyWithImpl<$Res, AdminSession>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'token_hash') String tokenHash,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'user_agent') String? userAgent,
    @JsonKey(name: 'expires_at') String expiresAt,
    @JsonKey(name: 'created_at') String createdAt,
  });
}

/// @nodoc
class _$AdminSessionCopyWithImpl<$Res, $Val extends AdminSession>
    implements $AdminSessionCopyWith<$Res> {
  _$AdminSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? tokenHash = null,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? expiresAt = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            tokenHash: null == tokenHash
                ? _value.tokenHash
                : tokenHash // ignore: cast_nullable_to_non_nullable
                      as String,
            ipAddress: freezed == ipAddress
                ? _value.ipAddress
                : ipAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            userAgent: freezed == userAgent
                ? _value.userAgent
                : userAgent // ignore: cast_nullable_to_non_nullable
                      as String?,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$AdminSessionImplCopyWith<$Res>
    implements $AdminSessionCopyWith<$Res> {
  factory _$$AdminSessionImplCopyWith(
    _$AdminSessionImpl value,
    $Res Function(_$AdminSessionImpl) then,
  ) = __$$AdminSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'token_hash') String tokenHash,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'user_agent') String? userAgent,
    @JsonKey(name: 'expires_at') String expiresAt,
    @JsonKey(name: 'created_at') String createdAt,
  });
}

/// @nodoc
class __$$AdminSessionImplCopyWithImpl<$Res>
    extends _$AdminSessionCopyWithImpl<$Res, _$AdminSessionImpl>
    implements _$$AdminSessionImplCopyWith<$Res> {
  __$$AdminSessionImplCopyWithImpl(
    _$AdminSessionImpl _value,
    $Res Function(_$AdminSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AdminSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? tokenHash = null,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? expiresAt = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$AdminSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        tokenHash: null == tokenHash
            ? _value.tokenHash
            : tokenHash // ignore: cast_nullable_to_non_nullable
                  as String,
        ipAddress: freezed == ipAddress
            ? _value.ipAddress
            : ipAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        userAgent: freezed == userAgent
            ? _value.userAgent
            : userAgent // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
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
class _$AdminSessionImpl implements _AdminSession {
  const _$AdminSessionImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'token_hash') required this.tokenHash,
    @JsonKey(name: 'ip_address') required this.ipAddress,
    @JsonKey(name: 'user_agent') required this.userAgent,
    @JsonKey(name: 'expires_at') required this.expiresAt,
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$AdminSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminSessionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'token_hash')
  final String tokenHash;
  @override
  @JsonKey(name: 'ip_address')
  final String? ipAddress;
  @override
  @JsonKey(name: 'user_agent')
  final String? userAgent;
  @override
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;

  @override
  String toString() {
    return 'AdminSession(id: $id, userId: $userId, tokenHash: $tokenHash, ipAddress: $ipAddress, userAgent: $userAgent, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.tokenHash, tokenHash) ||
                other.tokenHash == tokenHash) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.userAgent, userAgent) ||
                other.userAgent == userAgent) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    tokenHash,
    ipAddress,
    userAgent,
    expiresAt,
    createdAt,
  );

  /// Create a copy of AdminSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminSessionImplCopyWith<_$AdminSessionImpl> get copyWith =>
      __$$AdminSessionImplCopyWithImpl<_$AdminSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminSessionImplToJson(this);
  }
}

abstract class _AdminSession implements AdminSession {
  const factory _AdminSession({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'token_hash') required final String tokenHash,
    @JsonKey(name: 'ip_address') required final String? ipAddress,
    @JsonKey(name: 'user_agent') required final String? userAgent,
    @JsonKey(name: 'expires_at') required final String expiresAt,
    @JsonKey(name: 'created_at') required final String createdAt,
  }) = _$AdminSessionImpl;

  factory _AdminSession.fromJson(Map<String, dynamic> json) =
      _$AdminSessionImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'token_hash')
  String get tokenHash;
  @override
  @JsonKey(name: 'ip_address')
  String? get ipAddress;
  @override
  @JsonKey(name: 'user_agent')
  String? get userAgent;
  @override
  @JsonKey(name: 'expires_at')
  String get expiresAt;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;

  /// Create a copy of AdminSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminSessionImplCopyWith<_$AdminSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
