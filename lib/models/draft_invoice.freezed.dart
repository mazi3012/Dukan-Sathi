// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draft_invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DraftInvoice _$DraftInvoiceFromJson(Map<String, dynamic> json) {
  return _DraftInvoice.fromJson(json);
}

/// @nodoc
mixin _$DraftInvoice {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'shop_id')
  String get shopId => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_id')
  String? get customerId => throw _privateConstructorUsedError;
  List<CartItem> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount')
  double get totalAmount => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this DraftInvoice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DraftInvoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DraftInvoiceCopyWith<DraftInvoice> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DraftInvoiceCopyWith<$Res> {
  factory $DraftInvoiceCopyWith(
    DraftInvoice value,
    $Res Function(DraftInvoice) then,
  ) = _$DraftInvoiceCopyWithImpl<$Res, DraftInvoice>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'shop_id') String shopId,
    @JsonKey(name: 'customer_id') String? customerId,
    List<CartItem> items,
    @JsonKey(name: 'total_amount') double totalAmount,
    String status,
  });
}

/// @nodoc
class _$DraftInvoiceCopyWithImpl<$Res, $Val extends DraftInvoice>
    implements $DraftInvoiceCopyWith<$Res> {
  _$DraftInvoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DraftInvoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shopId = null,
    Object? customerId = freezed,
    Object? items = null,
    Object? totalAmount = null,
    Object? status = null,
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
            customerId: freezed == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<CartItem>,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DraftInvoiceImplCopyWith<$Res>
    implements $DraftInvoiceCopyWith<$Res> {
  factory _$$DraftInvoiceImplCopyWith(
    _$DraftInvoiceImpl value,
    $Res Function(_$DraftInvoiceImpl) then,
  ) = __$$DraftInvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'shop_id') String shopId,
    @JsonKey(name: 'customer_id') String? customerId,
    List<CartItem> items,
    @JsonKey(name: 'total_amount') double totalAmount,
    String status,
  });
}

/// @nodoc
class __$$DraftInvoiceImplCopyWithImpl<$Res>
    extends _$DraftInvoiceCopyWithImpl<$Res, _$DraftInvoiceImpl>
    implements _$$DraftInvoiceImplCopyWith<$Res> {
  __$$DraftInvoiceImplCopyWithImpl(
    _$DraftInvoiceImpl _value,
    $Res Function(_$DraftInvoiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DraftInvoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shopId = null,
    Object? customerId = freezed,
    Object? items = null,
    Object? totalAmount = null,
    Object? status = null,
  }) {
    return _then(
      _$DraftInvoiceImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        shopId: null == shopId
            ? _value.shopId
            : shopId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: freezed == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<CartItem>,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DraftInvoiceImpl implements _DraftInvoice {
  const _$DraftInvoiceImpl({
    required this.id,
    @JsonKey(name: 'shop_id') required this.shopId,
    @JsonKey(name: 'customer_id') this.customerId,
    required final List<CartItem> items,
    @JsonKey(name: 'total_amount') required this.totalAmount,
    this.status = 'draft',
  }) : _items = items;

  factory _$DraftInvoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$DraftInvoiceImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'shop_id')
  final String shopId;
  @override
  @JsonKey(name: 'customer_id')
  final String? customerId;
  final List<CartItem> _items;
  @override
  List<CartItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'DraftInvoice(id: $id, shopId: $shopId, customerId: $customerId, items: $items, totalAmount: $totalAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DraftInvoiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.shopId, shopId) || other.shopId == shopId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    shopId,
    customerId,
    const DeepCollectionEquality().hash(_items),
    totalAmount,
    status,
  );

  /// Create a copy of DraftInvoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DraftInvoiceImplCopyWith<_$DraftInvoiceImpl> get copyWith =>
      __$$DraftInvoiceImplCopyWithImpl<_$DraftInvoiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DraftInvoiceImplToJson(this);
  }
}

abstract class _DraftInvoice implements DraftInvoice {
  const factory _DraftInvoice({
    required final String id,
    @JsonKey(name: 'shop_id') required final String shopId,
    @JsonKey(name: 'customer_id') final String? customerId,
    required final List<CartItem> items,
    @JsonKey(name: 'total_amount') required final double totalAmount,
    final String status,
  }) = _$DraftInvoiceImpl;

  factory _DraftInvoice.fromJson(Map<String, dynamic> json) =
      _$DraftInvoiceImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'shop_id')
  String get shopId;
  @override
  @JsonKey(name: 'customer_id')
  String? get customerId;
  @override
  List<CartItem> get items;
  @override
  @JsonKey(name: 'total_amount')
  double get totalAmount;
  @override
  String get status;

  /// Create a copy of DraftInvoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DraftInvoiceImplCopyWith<_$DraftInvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
