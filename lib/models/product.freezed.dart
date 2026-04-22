// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Product {

 String get id;@JsonKey(name: 'shop_id') String get shopId; String get name; double get price;@JsonKey(name: 'stock_quantity') int get stockQuantity; String get category; String? get description;@JsonKey(name: 'is_service') bool get isService;@JsonKey(name: 'gst_rate') double get gstRate;@JsonKey(name: 'hsn_sac_code') String? get hsnSacCode; Map<String, dynamic> get metadata;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.isService, isService) || other.isService == isService)&&(identical(other.gstRate, gstRate) || other.gstRate == gstRate)&&(identical(other.hsnSacCode, hsnSacCode) || other.hsnSacCode == hsnSacCode)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shopId,name,price,stockQuantity,category,description,isService,gstRate,hsnSacCode,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'Product(id: $id, shopId: $shopId, name: $name, price: $price, stockQuantity: $stockQuantity, category: $category, description: $description, isService: $isService, gstRate: $gstRate, hsnSacCode: $hsnSacCode, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'shop_id') String shopId, String name, double price,@JsonKey(name: 'stock_quantity') int stockQuantity, String category, String? description,@JsonKey(name: 'is_service') bool isService,@JsonKey(name: 'gst_rate') double gstRate,@JsonKey(name: 'hsn_sac_code') String? hsnSacCode, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shopId = null,Object? name = null,Object? price = null,Object? stockQuantity = null,Object? category = null,Object? description = freezed,Object? isService = null,Object? gstRate = null,Object? hsnSacCode = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isService: null == isService ? _self.isService : isService // ignore: cast_nullable_to_non_nullable
as bool,gstRate: null == gstRate ? _self.gstRate : gstRate // ignore: cast_nullable_to_non_nullable
as double,hsnSacCode: freezed == hsnSacCode ? _self.hsnSacCode : hsnSacCode // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'shop_id')  String shopId,  String name,  double price, @JsonKey(name: 'stock_quantity')  int stockQuantity,  String category,  String? description, @JsonKey(name: 'is_service')  bool isService, @JsonKey(name: 'gst_rate')  double gstRate, @JsonKey(name: 'hsn_sac_code')  String? hsnSacCode,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.shopId,_that.name,_that.price,_that.stockQuantity,_that.category,_that.description,_that.isService,_that.gstRate,_that.hsnSacCode,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'shop_id')  String shopId,  String name,  double price, @JsonKey(name: 'stock_quantity')  int stockQuantity,  String category,  String? description, @JsonKey(name: 'is_service')  bool isService, @JsonKey(name: 'gst_rate')  double gstRate, @JsonKey(name: 'hsn_sac_code')  String? hsnSacCode,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.shopId,_that.name,_that.price,_that.stockQuantity,_that.category,_that.description,_that.isService,_that.gstRate,_that.hsnSacCode,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'shop_id')  String shopId,  String name,  double price, @JsonKey(name: 'stock_quantity')  int stockQuantity,  String category,  String? description, @JsonKey(name: 'is_service')  bool isService, @JsonKey(name: 'gst_rate')  double gstRate, @JsonKey(name: 'hsn_sac_code')  String? hsnSacCode,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.shopId,_that.name,_that.price,_that.stockQuantity,_that.category,_that.description,_that.isService,_that.gstRate,_that.hsnSacCode,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.id, @JsonKey(name: 'shop_id') required this.shopId, required this.name, required this.price, @JsonKey(name: 'stock_quantity') required this.stockQuantity, required this.category, this.description, @JsonKey(name: 'is_service') this.isService = false, @JsonKey(name: 'gst_rate') this.gstRate = 0, @JsonKey(name: 'hsn_sac_code') this.hsnSacCode, final  Map<String, dynamic> metadata = const {}}): _metadata = metadata;
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String id;
@override@JsonKey(name: 'shop_id') final  String shopId;
@override final  String name;
@override final  double price;
@override@JsonKey(name: 'stock_quantity') final  int stockQuantity;
@override final  String category;
@override final  String? description;
@override@JsonKey(name: 'is_service') final  bool isService;
@override@JsonKey(name: 'gst_rate') final  double gstRate;
@override@JsonKey(name: 'hsn_sac_code') final  String? hsnSacCode;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.isService, isService) || other.isService == isService)&&(identical(other.gstRate, gstRate) || other.gstRate == gstRate)&&(identical(other.hsnSacCode, hsnSacCode) || other.hsnSacCode == hsnSacCode)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shopId,name,price,stockQuantity,category,description,isService,gstRate,hsnSacCode,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'Product(id: $id, shopId: $shopId, name: $name, price: $price, stockQuantity: $stockQuantity, category: $category, description: $description, isService: $isService, gstRate: $gstRate, hsnSacCode: $hsnSacCode, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'shop_id') String shopId, String name, double price,@JsonKey(name: 'stock_quantity') int stockQuantity, String category, String? description,@JsonKey(name: 'is_service') bool isService,@JsonKey(name: 'gst_rate') double gstRate,@JsonKey(name: 'hsn_sac_code') String? hsnSacCode, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shopId = null,Object? name = null,Object? price = null,Object? stockQuantity = null,Object? category = null,Object? description = freezed,Object? isService = null,Object? gstRate = null,Object? hsnSacCode = freezed,Object? metadata = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isService: null == isService ? _self.isService : isService // ignore: cast_nullable_to_non_nullable
as bool,gstRate: null == gstRate ? _self.gstRate : gstRate // ignore: cast_nullable_to_non_nullable
as double,hsnSacCode: freezed == hsnSacCode ? _self.hsnSacCode : hsnSacCode // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
