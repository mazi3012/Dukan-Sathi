// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShopConfig {

 String get shopId;@JsonKey(name: 'gst_registration_number') String? get gstRegistrationNumber; String get state;@JsonKey(name: 'gst_mode') GSTMode get gstMode;@JsonKey(name: 'business_type') String get businessType;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of ShopConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopConfigCopyWith<ShopConfig> get copyWith => _$ShopConfigCopyWithImpl<ShopConfig>(this as ShopConfig, _$identity);

  /// Serializes this ShopConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopConfig&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.gstRegistrationNumber, gstRegistrationNumber) || other.gstRegistrationNumber == gstRegistrationNumber)&&(identical(other.state, state) || other.state == state)&&(identical(other.gstMode, gstMode) || other.gstMode == gstMode)&&(identical(other.businessType, businessType) || other.businessType == businessType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shopId,gstRegistrationNumber,state,gstMode,businessType,createdAt,updatedAt);

@override
String toString() {
  return 'ShopConfig(shopId: $shopId, gstRegistrationNumber: $gstRegistrationNumber, state: $state, gstMode: $gstMode, businessType: $businessType, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ShopConfigCopyWith<$Res>  {
  factory $ShopConfigCopyWith(ShopConfig value, $Res Function(ShopConfig) _then) = _$ShopConfigCopyWithImpl;
@useResult
$Res call({
 String shopId,@JsonKey(name: 'gst_registration_number') String? gstRegistrationNumber, String state,@JsonKey(name: 'gst_mode') GSTMode gstMode,@JsonKey(name: 'business_type') String businessType,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$ShopConfigCopyWithImpl<$Res>
    implements $ShopConfigCopyWith<$Res> {
  _$ShopConfigCopyWithImpl(this._self, this._then);

  final ShopConfig _self;
  final $Res Function(ShopConfig) _then;

/// Create a copy of ShopConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shopId = null,Object? gstRegistrationNumber = freezed,Object? state = null,Object? gstMode = null,Object? businessType = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,gstRegistrationNumber: freezed == gstRegistrationNumber ? _self.gstRegistrationNumber : gstRegistrationNumber // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,gstMode: null == gstMode ? _self.gstMode : gstMode // ignore: cast_nullable_to_non_nullable
as GSTMode,businessType: null == businessType ? _self.businessType : businessType // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopConfig].
extension ShopConfigPatterns on ShopConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopConfig value)  $default,){
final _that = this;
switch (_that) {
case _ShopConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ShopConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String shopId, @JsonKey(name: 'gst_registration_number')  String? gstRegistrationNumber,  String state, @JsonKey(name: 'gst_mode')  GSTMode gstMode, @JsonKey(name: 'business_type')  String businessType, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopConfig() when $default != null:
return $default(_that.shopId,_that.gstRegistrationNumber,_that.state,_that.gstMode,_that.businessType,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String shopId, @JsonKey(name: 'gst_registration_number')  String? gstRegistrationNumber,  String state, @JsonKey(name: 'gst_mode')  GSTMode gstMode, @JsonKey(name: 'business_type')  String businessType, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ShopConfig():
return $default(_that.shopId,_that.gstRegistrationNumber,_that.state,_that.gstMode,_that.businessType,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String shopId, @JsonKey(name: 'gst_registration_number')  String? gstRegistrationNumber,  String state, @JsonKey(name: 'gst_mode')  GSTMode gstMode, @JsonKey(name: 'business_type')  String businessType, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ShopConfig() when $default != null:
return $default(_that.shopId,_that.gstRegistrationNumber,_that.state,_that.gstMode,_that.businessType,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShopConfig implements ShopConfig {
  const _ShopConfig({required this.shopId, @JsonKey(name: 'gst_registration_number') this.gstRegistrationNumber, required this.state, @JsonKey(name: 'gst_mode') required this.gstMode, @JsonKey(name: 'business_type') required this.businessType, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _ShopConfig.fromJson(Map<String, dynamic> json) => _$ShopConfigFromJson(json);

@override final  String shopId;
@override@JsonKey(name: 'gst_registration_number') final  String? gstRegistrationNumber;
@override final  String state;
@override@JsonKey(name: 'gst_mode') final  GSTMode gstMode;
@override@JsonKey(name: 'business_type') final  String businessType;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of ShopConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopConfigCopyWith<_ShopConfig> get copyWith => __$ShopConfigCopyWithImpl<_ShopConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopConfig&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.gstRegistrationNumber, gstRegistrationNumber) || other.gstRegistrationNumber == gstRegistrationNumber)&&(identical(other.state, state) || other.state == state)&&(identical(other.gstMode, gstMode) || other.gstMode == gstMode)&&(identical(other.businessType, businessType) || other.businessType == businessType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shopId,gstRegistrationNumber,state,gstMode,businessType,createdAt,updatedAt);

@override
String toString() {
  return 'ShopConfig(shopId: $shopId, gstRegistrationNumber: $gstRegistrationNumber, state: $state, gstMode: $gstMode, businessType: $businessType, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShopConfigCopyWith<$Res> implements $ShopConfigCopyWith<$Res> {
  factory _$ShopConfigCopyWith(_ShopConfig value, $Res Function(_ShopConfig) _then) = __$ShopConfigCopyWithImpl;
@override @useResult
$Res call({
 String shopId,@JsonKey(name: 'gst_registration_number') String? gstRegistrationNumber, String state,@JsonKey(name: 'gst_mode') GSTMode gstMode,@JsonKey(name: 'business_type') String businessType,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$ShopConfigCopyWithImpl<$Res>
    implements _$ShopConfigCopyWith<$Res> {
  __$ShopConfigCopyWithImpl(this._self, this._then);

  final _ShopConfig _self;
  final $Res Function(_ShopConfig) _then;

/// Create a copy of ShopConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shopId = null,Object? gstRegistrationNumber = freezed,Object? state = null,Object? gstMode = null,Object? businessType = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_ShopConfig(
shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,gstRegistrationNumber: freezed == gstRegistrationNumber ? _self.gstRegistrationNumber : gstRegistrationNumber // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,gstMode: null == gstMode ? _self.gstMode : gstMode // ignore: cast_nullable_to_non_nullable
as GSTMode,businessType: null == businessType ? _self.businessType : businessType // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
