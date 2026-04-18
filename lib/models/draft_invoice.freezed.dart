// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draft_invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DraftInvoice {

 String get id;@JsonKey(name: 'shop_id') String get shopId;@JsonKey(name: 'customer_id') String? get customerId; List<CartItem> get items;@JsonKey(name: 'total_amount') double get totalAmount; String get status;
/// Create a copy of DraftInvoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftInvoiceCopyWith<DraftInvoice> get copyWith => _$DraftInvoiceCopyWithImpl<DraftInvoice>(this as DraftInvoice, _$identity);

  /// Serializes this DraftInvoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftInvoice&&(identical(other.id, id) || other.id == id)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shopId,customerId,const DeepCollectionEquality().hash(items),totalAmount,status);

@override
String toString() {
  return 'DraftInvoice(id: $id, shopId: $shopId, customerId: $customerId, items: $items, totalAmount: $totalAmount, status: $status)';
}


}

/// @nodoc
abstract mixin class $DraftInvoiceCopyWith<$Res>  {
  factory $DraftInvoiceCopyWith(DraftInvoice value, $Res Function(DraftInvoice) _then) = _$DraftInvoiceCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'shop_id') String shopId,@JsonKey(name: 'customer_id') String? customerId, List<CartItem> items,@JsonKey(name: 'total_amount') double totalAmount, String status
});




}
/// @nodoc
class _$DraftInvoiceCopyWithImpl<$Res>
    implements $DraftInvoiceCopyWith<$Res> {
  _$DraftInvoiceCopyWithImpl(this._self, this._then);

  final DraftInvoice _self;
  final $Res Function(DraftInvoice) _then;

/// Create a copy of DraftInvoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shopId = null,Object? customerId = freezed,Object? items = null,Object? totalAmount = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftInvoice].
extension DraftInvoicePatterns on DraftInvoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DraftInvoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DraftInvoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DraftInvoice value)  $default,){
final _that = this;
switch (_that) {
case _DraftInvoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DraftInvoice value)?  $default,){
final _that = this;
switch (_that) {
case _DraftInvoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'shop_id')  String shopId, @JsonKey(name: 'customer_id')  String? customerId,  List<CartItem> items, @JsonKey(name: 'total_amount')  double totalAmount,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DraftInvoice() when $default != null:
return $default(_that.id,_that.shopId,_that.customerId,_that.items,_that.totalAmount,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'shop_id')  String shopId, @JsonKey(name: 'customer_id')  String? customerId,  List<CartItem> items, @JsonKey(name: 'total_amount')  double totalAmount,  String status)  $default,) {final _that = this;
switch (_that) {
case _DraftInvoice():
return $default(_that.id,_that.shopId,_that.customerId,_that.items,_that.totalAmount,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'shop_id')  String shopId, @JsonKey(name: 'customer_id')  String? customerId,  List<CartItem> items, @JsonKey(name: 'total_amount')  double totalAmount,  String status)?  $default,) {final _that = this;
switch (_that) {
case _DraftInvoice() when $default != null:
return $default(_that.id,_that.shopId,_that.customerId,_that.items,_that.totalAmount,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DraftInvoice implements DraftInvoice {
  const _DraftInvoice({required this.id, @JsonKey(name: 'shop_id') required this.shopId, @JsonKey(name: 'customer_id') this.customerId, required final  List<CartItem> items, @JsonKey(name: 'total_amount') required this.totalAmount, this.status = 'draft'}): _items = items;
  factory _DraftInvoice.fromJson(Map<String, dynamic> json) => _$DraftInvoiceFromJson(json);

@override final  String id;
@override@JsonKey(name: 'shop_id') final  String shopId;
@override@JsonKey(name: 'customer_id') final  String? customerId;
 final  List<CartItem> _items;
@override List<CartItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'total_amount') final  double totalAmount;
@override@JsonKey() final  String status;

/// Create a copy of DraftInvoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DraftInvoiceCopyWith<_DraftInvoice> get copyWith => __$DraftInvoiceCopyWithImpl<_DraftInvoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DraftInvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DraftInvoice&&(identical(other.id, id) || other.id == id)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shopId,customerId,const DeepCollectionEquality().hash(_items),totalAmount,status);

@override
String toString() {
  return 'DraftInvoice(id: $id, shopId: $shopId, customerId: $customerId, items: $items, totalAmount: $totalAmount, status: $status)';
}


}

/// @nodoc
abstract mixin class _$DraftInvoiceCopyWith<$Res> implements $DraftInvoiceCopyWith<$Res> {
  factory _$DraftInvoiceCopyWith(_DraftInvoice value, $Res Function(_DraftInvoice) _then) = __$DraftInvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'shop_id') String shopId,@JsonKey(name: 'customer_id') String? customerId, List<CartItem> items,@JsonKey(name: 'total_amount') double totalAmount, String status
});




}
/// @nodoc
class __$DraftInvoiceCopyWithImpl<$Res>
    implements _$DraftInvoiceCopyWith<$Res> {
  __$DraftInvoiceCopyWithImpl(this._self, this._then);

  final _DraftInvoice _self;
  final $Res Function(_DraftInvoice) _then;

/// Create a copy of DraftInvoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shopId = null,Object? customerId = freezed,Object? items = null,Object? totalAmount = null,Object? status = null,}) {
  return _then(_DraftInvoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
