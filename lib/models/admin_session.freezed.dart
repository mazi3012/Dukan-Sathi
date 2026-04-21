// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminSession {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'token_hash') String get tokenHash;@JsonKey(name: 'ip_address') String? get ipAddress;@JsonKey(name: 'user_agent') String? get userAgent;@JsonKey(name: 'expires_at') String get expiresAt;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of AdminSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminSessionCopyWith<AdminSession> get copyWith => _$AdminSessionCopyWithImpl<AdminSession>(this as AdminSession, _$identity);

  /// Serializes this AdminSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.tokenHash, tokenHash) || other.tokenHash == tokenHash)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,tokenHash,ipAddress,userAgent,expiresAt,createdAt);

@override
String toString() {
  return 'AdminSession(id: $id, userId: $userId, tokenHash: $tokenHash, ipAddress: $ipAddress, userAgent: $userAgent, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AdminSessionCopyWith<$Res>  {
  factory $AdminSessionCopyWith(AdminSession value, $Res Function(AdminSession) _then) = _$AdminSessionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'token_hash') String tokenHash,@JsonKey(name: 'ip_address') String? ipAddress,@JsonKey(name: 'user_agent') String? userAgent,@JsonKey(name: 'expires_at') String expiresAt,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$AdminSessionCopyWithImpl<$Res>
    implements $AdminSessionCopyWith<$Res> {
  _$AdminSessionCopyWithImpl(this._self, this._then);

  final AdminSession _self;
  final $Res Function(AdminSession) _then;

/// Create a copy of AdminSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? tokenHash = null,Object? ipAddress = freezed,Object? userAgent = freezed,Object? expiresAt = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,tokenHash: null == tokenHash ? _self.tokenHash : tokenHash // ignore: cast_nullable_to_non_nullable
as String,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminSession].
extension AdminSessionPatterns on AdminSession {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminSession() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminSession value)  $default,){
final _that = this;
switch (_that) {
case _AdminSession():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminSession value)?  $default,){
final _that = this;
switch (_that) {
case _AdminSession() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'token_hash')  String tokenHash, @JsonKey(name: 'ip_address')  String? ipAddress, @JsonKey(name: 'user_agent')  String? userAgent, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminSession() when $default != null:
return $default(_that.id,_that.userId,_that.tokenHash,_that.ipAddress,_that.userAgent,_that.expiresAt,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'token_hash')  String tokenHash, @JsonKey(name: 'ip_address')  String? ipAddress, @JsonKey(name: 'user_agent')  String? userAgent, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminSession():
return $default(_that.id,_that.userId,_that.tokenHash,_that.ipAddress,_that.userAgent,_that.expiresAt,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'token_hash')  String tokenHash, @JsonKey(name: 'ip_address')  String? ipAddress, @JsonKey(name: 'user_agent')  String? userAgent, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminSession() when $default != null:
return $default(_that.id,_that.userId,_that.tokenHash,_that.ipAddress,_that.userAgent,_that.expiresAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminSession implements AdminSession {
  const _AdminSession({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'token_hash') required this.tokenHash, @JsonKey(name: 'ip_address') required this.ipAddress, @JsonKey(name: 'user_agent') required this.userAgent, @JsonKey(name: 'expires_at') required this.expiresAt, @JsonKey(name: 'created_at') required this.createdAt});
  factory _AdminSession.fromJson(Map<String, dynamic> json) => _$AdminSessionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'token_hash') final  String tokenHash;
@override@JsonKey(name: 'ip_address') final  String? ipAddress;
@override@JsonKey(name: 'user_agent') final  String? userAgent;
@override@JsonKey(name: 'expires_at') final  String expiresAt;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of AdminSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminSessionCopyWith<_AdminSession> get copyWith => __$AdminSessionCopyWithImpl<_AdminSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.tokenHash, tokenHash) || other.tokenHash == tokenHash)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,tokenHash,ipAddress,userAgent,expiresAt,createdAt);

@override
String toString() {
  return 'AdminSession(id: $id, userId: $userId, tokenHash: $tokenHash, ipAddress: $ipAddress, userAgent: $userAgent, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminSessionCopyWith<$Res> implements $AdminSessionCopyWith<$Res> {
  factory _$AdminSessionCopyWith(_AdminSession value, $Res Function(_AdminSession) _then) = __$AdminSessionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'token_hash') String tokenHash,@JsonKey(name: 'ip_address') String? ipAddress,@JsonKey(name: 'user_agent') String? userAgent,@JsonKey(name: 'expires_at') String expiresAt,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$AdminSessionCopyWithImpl<$Res>
    implements _$AdminSessionCopyWith<$Res> {
  __$AdminSessionCopyWithImpl(this._self, this._then);

  final _AdminSession _self;
  final $Res Function(_AdminSession) _then;

/// Create a copy of AdminSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? tokenHash = null,Object? ipAddress = freezed,Object? userAgent = freezed,Object? expiresAt = null,Object? createdAt = null,}) {
  return _then(_AdminSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,tokenHash: null == tokenHash ? _self.tokenHash : tokenHash // ignore: cast_nullable_to_non_nullable
as String,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
