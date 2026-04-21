// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_permission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminPermission {

 String get id;@JsonKey(name: 'permission_name') String get permissionName; String? get description; String get resource; String get action;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of AdminPermission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminPermissionCopyWith<AdminPermission> get copyWith => _$AdminPermissionCopyWithImpl<AdminPermission>(this as AdminPermission, _$identity);

  /// Serializes this AdminPermission to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminPermission&&(identical(other.id, id) || other.id == id)&&(identical(other.permissionName, permissionName) || other.permissionName == permissionName)&&(identical(other.description, description) || other.description == description)&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.action, action) || other.action == action)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,permissionName,description,resource,action,createdAt);

@override
String toString() {
  return 'AdminPermission(id: $id, permissionName: $permissionName, description: $description, resource: $resource, action: $action, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AdminPermissionCopyWith<$Res>  {
  factory $AdminPermissionCopyWith(AdminPermission value, $Res Function(AdminPermission) _then) = _$AdminPermissionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'permission_name') String permissionName, String? description, String resource, String action,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$AdminPermissionCopyWithImpl<$Res>
    implements $AdminPermissionCopyWith<$Res> {
  _$AdminPermissionCopyWithImpl(this._self, this._then);

  final AdminPermission _self;
  final $Res Function(AdminPermission) _then;

/// Create a copy of AdminPermission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? permissionName = null,Object? description = freezed,Object? resource = null,Object? action = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,permissionName: null == permissionName ? _self.permissionName : permissionName // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminPermission].
extension AdminPermissionPatterns on AdminPermission {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminPermission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminPermission() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminPermission value)  $default,){
final _that = this;
switch (_that) {
case _AdminPermission():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminPermission value)?  $default,){
final _that = this;
switch (_that) {
case _AdminPermission() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'permission_name')  String permissionName,  String? description,  String resource,  String action, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminPermission() when $default != null:
return $default(_that.id,_that.permissionName,_that.description,_that.resource,_that.action,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'permission_name')  String permissionName,  String? description,  String resource,  String action, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminPermission():
return $default(_that.id,_that.permissionName,_that.description,_that.resource,_that.action,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'permission_name')  String permissionName,  String? description,  String resource,  String action, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminPermission() when $default != null:
return $default(_that.id,_that.permissionName,_that.description,_that.resource,_that.action,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminPermission implements AdminPermission {
  const _AdminPermission({required this.id, @JsonKey(name: 'permission_name') required this.permissionName, required this.description, required this.resource, required this.action, @JsonKey(name: 'created_at') required this.createdAt});
  factory _AdminPermission.fromJson(Map<String, dynamic> json) => _$AdminPermissionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'permission_name') final  String permissionName;
@override final  String? description;
@override final  String resource;
@override final  String action;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of AdminPermission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminPermissionCopyWith<_AdminPermission> get copyWith => __$AdminPermissionCopyWithImpl<_AdminPermission>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminPermissionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminPermission&&(identical(other.id, id) || other.id == id)&&(identical(other.permissionName, permissionName) || other.permissionName == permissionName)&&(identical(other.description, description) || other.description == description)&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.action, action) || other.action == action)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,permissionName,description,resource,action,createdAt);

@override
String toString() {
  return 'AdminPermission(id: $id, permissionName: $permissionName, description: $description, resource: $resource, action: $action, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminPermissionCopyWith<$Res> implements $AdminPermissionCopyWith<$Res> {
  factory _$AdminPermissionCopyWith(_AdminPermission value, $Res Function(_AdminPermission) _then) = __$AdminPermissionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'permission_name') String permissionName, String? description, String resource, String action,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$AdminPermissionCopyWithImpl<$Res>
    implements _$AdminPermissionCopyWith<$Res> {
  __$AdminPermissionCopyWithImpl(this._self, this._then);

  final _AdminPermission _self;
  final $Res Function(_AdminPermission) _then;

/// Create a copy of AdminPermission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? permissionName = null,Object? description = freezed,Object? resource = null,Object? action = null,Object? createdAt = null,}) {
  return _then(_AdminPermission(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,permissionName: null == permissionName ? _self.permissionName : permissionName // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
