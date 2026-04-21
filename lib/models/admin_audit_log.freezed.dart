// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_audit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminAuditLog {

 String get id;@JsonKey(name: 'user_id') String? get userId; String get action; String get resource;@JsonKey(name: 'resource_id') String? get resourceId; Map<String, dynamic>? get changes;@JsonKey(name: 'ip_address') String? get ipAddress; String get status;@JsonKey(name: 'error_message') String? get errorMessage;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of AdminAuditLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminAuditLogCopyWith<AdminAuditLog> get copyWith => _$AdminAuditLogCopyWithImpl<AdminAuditLog>(this as AdminAuditLog, _$identity);

  /// Serializes this AdminAuditLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminAuditLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.action, action) || other.action == action)&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&const DeepCollectionEquality().equals(other.changes, changes)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,action,resource,resourceId,const DeepCollectionEquality().hash(changes),ipAddress,status,errorMessage,createdAt);

@override
String toString() {
  return 'AdminAuditLog(id: $id, userId: $userId, action: $action, resource: $resource, resourceId: $resourceId, changes: $changes, ipAddress: $ipAddress, status: $status, errorMessage: $errorMessage, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AdminAuditLogCopyWith<$Res>  {
  factory $AdminAuditLogCopyWith(AdminAuditLog value, $Res Function(AdminAuditLog) _then) = _$AdminAuditLogCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String? userId, String action, String resource,@JsonKey(name: 'resource_id') String? resourceId, Map<String, dynamic>? changes,@JsonKey(name: 'ip_address') String? ipAddress, String status,@JsonKey(name: 'error_message') String? errorMessage,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$AdminAuditLogCopyWithImpl<$Res>
    implements $AdminAuditLogCopyWith<$Res> {
  _$AdminAuditLogCopyWithImpl(this._self, this._then);

  final AdminAuditLog _self;
  final $Res Function(AdminAuditLog) _then;

/// Create a copy of AdminAuditLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = freezed,Object? action = null,Object? resource = null,Object? resourceId = freezed,Object? changes = freezed,Object? ipAddress = freezed,Object? status = null,Object? errorMessage = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,resourceId: freezed == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String?,changes: freezed == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminAuditLog].
extension AdminAuditLogPatterns on AdminAuditLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminAuditLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminAuditLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminAuditLog value)  $default,){
final _that = this;
switch (_that) {
case _AdminAuditLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminAuditLog value)?  $default,){
final _that = this;
switch (_that) {
case _AdminAuditLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String? userId,  String action,  String resource, @JsonKey(name: 'resource_id')  String? resourceId,  Map<String, dynamic>? changes, @JsonKey(name: 'ip_address')  String? ipAddress,  String status, @JsonKey(name: 'error_message')  String? errorMessage, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminAuditLog() when $default != null:
return $default(_that.id,_that.userId,_that.action,_that.resource,_that.resourceId,_that.changes,_that.ipAddress,_that.status,_that.errorMessage,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String? userId,  String action,  String resource, @JsonKey(name: 'resource_id')  String? resourceId,  Map<String, dynamic>? changes, @JsonKey(name: 'ip_address')  String? ipAddress,  String status, @JsonKey(name: 'error_message')  String? errorMessage, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminAuditLog():
return $default(_that.id,_that.userId,_that.action,_that.resource,_that.resourceId,_that.changes,_that.ipAddress,_that.status,_that.errorMessage,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String? userId,  String action,  String resource, @JsonKey(name: 'resource_id')  String? resourceId,  Map<String, dynamic>? changes, @JsonKey(name: 'ip_address')  String? ipAddress,  String status, @JsonKey(name: 'error_message')  String? errorMessage, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminAuditLog() when $default != null:
return $default(_that.id,_that.userId,_that.action,_that.resource,_that.resourceId,_that.changes,_that.ipAddress,_that.status,_that.errorMessage,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminAuditLog implements AdminAuditLog {
  const _AdminAuditLog({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.action, required this.resource, @JsonKey(name: 'resource_id') required this.resourceId, required final  Map<String, dynamic>? changes, @JsonKey(name: 'ip_address') required this.ipAddress, required this.status, @JsonKey(name: 'error_message') required this.errorMessage, @JsonKey(name: 'created_at') required this.createdAt}): _changes = changes;
  factory _AdminAuditLog.fromJson(Map<String, dynamic> json) => _$AdminAuditLogFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String? userId;
@override final  String action;
@override final  String resource;
@override@JsonKey(name: 'resource_id') final  String? resourceId;
 final  Map<String, dynamic>? _changes;
@override Map<String, dynamic>? get changes {
  final value = _changes;
  if (value == null) return null;
  if (_changes is EqualUnmodifiableMapView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'ip_address') final  String? ipAddress;
@override final  String status;
@override@JsonKey(name: 'error_message') final  String? errorMessage;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of AdminAuditLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminAuditLogCopyWith<_AdminAuditLog> get copyWith => __$AdminAuditLogCopyWithImpl<_AdminAuditLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminAuditLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminAuditLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.action, action) || other.action == action)&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&const DeepCollectionEquality().equals(other._changes, _changes)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,action,resource,resourceId,const DeepCollectionEquality().hash(_changes),ipAddress,status,errorMessage,createdAt);

@override
String toString() {
  return 'AdminAuditLog(id: $id, userId: $userId, action: $action, resource: $resource, resourceId: $resourceId, changes: $changes, ipAddress: $ipAddress, status: $status, errorMessage: $errorMessage, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminAuditLogCopyWith<$Res> implements $AdminAuditLogCopyWith<$Res> {
  factory _$AdminAuditLogCopyWith(_AdminAuditLog value, $Res Function(_AdminAuditLog) _then) = __$AdminAuditLogCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String? userId, String action, String resource,@JsonKey(name: 'resource_id') String? resourceId, Map<String, dynamic>? changes,@JsonKey(name: 'ip_address') String? ipAddress, String status,@JsonKey(name: 'error_message') String? errorMessage,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$AdminAuditLogCopyWithImpl<$Res>
    implements _$AdminAuditLogCopyWith<$Res> {
  __$AdminAuditLogCopyWithImpl(this._self, this._then);

  final _AdminAuditLog _self;
  final $Res Function(_AdminAuditLog) _then;

/// Create a copy of AdminAuditLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = freezed,Object? action = null,Object? resource = null,Object? resourceId = freezed,Object? changes = freezed,Object? ipAddress = freezed,Object? status = null,Object? errorMessage = freezed,Object? createdAt = null,}) {
  return _then(_AdminAuditLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,resourceId: freezed == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String?,changes: freezed == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
