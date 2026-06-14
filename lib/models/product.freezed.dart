// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'shop_id')
  String get shopId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  @JsonKey(name: 'stock_quantity')
  int get stockQuantity => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_service')
  bool get isService => throw _privateConstructorUsedError;
  @JsonKey(name: 'gst_rate')
  double get gstRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'hsn_sac_code')
  String? get hsnSacCode => throw _privateConstructorUsedError;
  String? get barcode => throw _privateConstructorUsedError;
  @JsonKey(name: 'cost_price')
  double get costPrice => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Selling unit: e.g. 'pcs', 'box', 'dozen', 'crt', 'kg', 'ltr'
  String get unit => throw _privateConstructorUsedError;

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'shop_id') String shopId,
    String name,
    double price,
    @JsonKey(name: 'stock_quantity') int stockQuantity,
    String category,
    String? description,
    @JsonKey(name: 'is_service') bool isService,
    @JsonKey(name: 'gst_rate') double gstRate,
    @JsonKey(name: 'hsn_sac_code') String? hsnSacCode,
    String? barcode,
    @JsonKey(name: 'cost_price') double costPrice,
    Map<String, dynamic> metadata,
    String unit,
  });
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shopId = null,
    Object? name = null,
    Object? price = null,
    Object? stockQuantity = null,
    Object? category = null,
    Object? description = freezed,
    Object? isService = null,
    Object? gstRate = null,
    Object? hsnSacCode = freezed,
    Object? barcode = freezed,
    Object? costPrice = null,
    Object? metadata = null,
    Object? unit = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            shopId: null == shopId
                ? _value.shopId
                : shopId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            stockQuantity: null == stockQuantity
                ? _value.stockQuantity
                : stockQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            isService: null == isService
                ? _value.isService
                : isService // ignore: cast_nullable_to_non_nullable
                      as bool,
            gstRate: null == gstRate
                ? _value.gstRate
                : gstRate // ignore: cast_nullable_to_non_nullable
                      as double,
            hsnSacCode: freezed == hsnSacCode
                ? _value.hsnSacCode
                : hsnSacCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            barcode: freezed == barcode
                ? _value.barcode
                : barcode // ignore: cast_nullable_to_non_nullable
                      as String?,
            costPrice: null == costPrice
                ? _value.costPrice
                : costPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            unit: null == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
    _$ProductImpl value,
    $Res Function(_$ProductImpl) then,
  ) = __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'shop_id') String shopId,
    String name,
    double price,
    @JsonKey(name: 'stock_quantity') int stockQuantity,
    String category,
    String? description,
    @JsonKey(name: 'is_service') bool isService,
    @JsonKey(name: 'gst_rate') double gstRate,
    @JsonKey(name: 'hsn_sac_code') String? hsnSacCode,
    String? barcode,
    @JsonKey(name: 'cost_price') double costPrice,
    Map<String, dynamic> metadata,
    String unit,
  });
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
    _$ProductImpl _value,
    $Res Function(_$ProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shopId = null,
    Object? name = null,
    Object? price = null,
    Object? stockQuantity = null,
    Object? category = null,
    Object? description = freezed,
    Object? isService = null,
    Object? gstRate = null,
    Object? hsnSacCode = freezed,
    Object? barcode = freezed,
    Object? costPrice = null,
    Object? metadata = null,
    Object? unit = null,
  }) {
    return _then(
      _$ProductImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        shopId: null == shopId
            ? _value.shopId
            : shopId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        stockQuantity: null == stockQuantity
            ? _value.stockQuantity
            : stockQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        isService: null == isService
            ? _value.isService
            : isService // ignore: cast_nullable_to_non_nullable
                  as bool,
        gstRate: null == gstRate
            ? _value.gstRate
            : gstRate // ignore: cast_nullable_to_non_nullable
                  as double,
        hsnSacCode: freezed == hsnSacCode
            ? _value.hsnSacCode
            : hsnSacCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        barcode: freezed == barcode
            ? _value.barcode
            : barcode // ignore: cast_nullable_to_non_nullable
                  as String?,
        costPrice: null == costPrice
            ? _value.costPrice
            : costPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        unit: null == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductImpl implements _Product {
  const _$ProductImpl({
    required this.id,
    @JsonKey(name: 'shop_id') required this.shopId,
    required this.name,
    required this.price,
    @JsonKey(name: 'stock_quantity') required this.stockQuantity,
    required this.category,
    this.description,
    @JsonKey(name: 'is_service') this.isService = false,
    @JsonKey(name: 'gst_rate') this.gstRate = 0,
    @JsonKey(name: 'hsn_sac_code') this.hsnSacCode,
    this.barcode,
    @JsonKey(name: 'cost_price') this.costPrice = 0,
    final Map<String, dynamic> metadata = const {},
    this.unit = 'pcs',
  }) : _metadata = metadata;

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'shop_id')
  final String shopId;
  @override
  final String name;
  @override
  final double price;
  @override
  @JsonKey(name: 'stock_quantity')
  final int stockQuantity;
  @override
  final String category;
  @override
  final String? description;
  @override
  @JsonKey(name: 'is_service')
  final bool isService;
  @override
  @JsonKey(name: 'gst_rate')
  final double gstRate;
  @override
  @JsonKey(name: 'hsn_sac_code')
  final String? hsnSacCode;
  @override
  final String? barcode;
  @override
  @JsonKey(name: 'cost_price')
  final double costPrice;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Selling unit: e.g. 'pcs', 'box', 'dozen', 'crt', 'kg', 'ltr'
  @override
  @JsonKey()
  final String unit;

  @override
  String toString() {
    return 'Product(id: $id, shopId: $shopId, name: $name, price: $price, stockQuantity: $stockQuantity, category: $category, description: $description, isService: $isService, gstRate: $gstRate, hsnSacCode: $hsnSacCode, barcode: $barcode, costPrice: $costPrice, metadata: $metadata, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.shopId, shopId) || other.shopId == shopId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.stockQuantity, stockQuantity) ||
                other.stockQuantity == stockQuantity) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isService, isService) ||
                other.isService == isService) &&
            (identical(other.gstRate, gstRate) || other.gstRate == gstRate) &&
            (identical(other.hsnSacCode, hsnSacCode) ||
                other.hsnSacCode == hsnSacCode) &&
            (identical(other.barcode, barcode) || other.barcode == barcode) &&
            (identical(other.costPrice, costPrice) ||
                other.costPrice == costPrice) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.unit, unit) || other.unit == unit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    shopId,
    name,
    price,
    stockQuantity,
    category,
    description,
    isService,
    gstRate,
    hsnSacCode,
    barcode,
    costPrice,
    const DeepCollectionEquality().hash(_metadata),
    unit,
  );

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(this);
  }
}

abstract class _Product implements Product {
  const factory _Product({
    required final String id,
    @JsonKey(name: 'shop_id') required final String shopId,
    required final String name,
    required final double price,
    @JsonKey(name: 'stock_quantity') required final int stockQuantity,
    required final String category,
    final String? description,
    @JsonKey(name: 'is_service') final bool isService,
    @JsonKey(name: 'gst_rate') final double gstRate,
    @JsonKey(name: 'hsn_sac_code') final String? hsnSacCode,
    final String? barcode,
    @JsonKey(name: 'cost_price') final double costPrice,
    final Map<String, dynamic> metadata,
    final String unit,
  }) = _$ProductImpl;

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'shop_id')
  String get shopId;
  @override
  String get name;
  @override
  double get price;
  @override
  @JsonKey(name: 'stock_quantity')
  int get stockQuantity;
  @override
  String get category;
  @override
  String? get description;
  @override
  @JsonKey(name: 'is_service')
  bool get isService;
  @override
  @JsonKey(name: 'gst_rate')
  double get gstRate;
  @override
  @JsonKey(name: 'hsn_sac_code')
  String? get hsnSacCode;
  @override
  String? get barcode;
  @override
  @JsonKey(name: 'cost_price')
  double get costPrice;
  @override
  Map<String, dynamic> get metadata;

  /// Selling unit: e.g. 'pcs', 'box', 'dozen', 'crt', 'kg', 'ltr'
  @override
  String get unit;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
