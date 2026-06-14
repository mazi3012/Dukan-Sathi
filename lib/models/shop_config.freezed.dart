// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ShopConfig _$ShopConfigFromJson(Map<String, dynamic> json) {
  return _ShopConfig.fromJson(json);
}

/// @nodoc
mixin _$ShopConfig {
  String get shopId => throw _privateConstructorUsedError;
  @JsonKey(name: 'gst_registration_number')
  String? get gstRegistrationNumber => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'gst_mode')
  GSTMode get gstMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'business_type')
  String get businessType => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ShopConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShopConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShopConfigCopyWith<ShopConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShopConfigCopyWith<$Res> {
  factory $ShopConfigCopyWith(
    ShopConfig value,
    $Res Function(ShopConfig) then,
  ) = _$ShopConfigCopyWithImpl<$Res, ShopConfig>;
  @useResult
  $Res call({
    String shopId,
    @JsonKey(name: 'gst_registration_number') String? gstRegistrationNumber,
    String state,
    @JsonKey(name: 'gst_mode') GSTMode gstMode,
    @JsonKey(name: 'business_type') String businessType,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$ShopConfigCopyWithImpl<$Res, $Val extends ShopConfig>
    implements $ShopConfigCopyWith<$Res> {
  _$ShopConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShopConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shopId = null,
    Object? gstRegistrationNumber = freezed,
    Object? state = null,
    Object? gstMode = null,
    Object? businessType = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            shopId: null == shopId
                ? _value.shopId
                : shopId // ignore: cast_nullable_to_non_nullable
                      as String,
            gstRegistrationNumber: freezed == gstRegistrationNumber
                ? _value.gstRegistrationNumber
                : gstRegistrationNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
            gstMode: null == gstMode
                ? _value.gstMode
                : gstMode // ignore: cast_nullable_to_non_nullable
                      as GSTMode,
            businessType: null == businessType
                ? _value.businessType
                : businessType // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShopConfigImplCopyWith<$Res>
    implements $ShopConfigCopyWith<$Res> {
  factory _$$ShopConfigImplCopyWith(
    _$ShopConfigImpl value,
    $Res Function(_$ShopConfigImpl) then,
  ) = __$$ShopConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String shopId,
    @JsonKey(name: 'gst_registration_number') String? gstRegistrationNumber,
    String state,
    @JsonKey(name: 'gst_mode') GSTMode gstMode,
    @JsonKey(name: 'business_type') String businessType,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$ShopConfigImplCopyWithImpl<$Res>
    extends _$ShopConfigCopyWithImpl<$Res, _$ShopConfigImpl>
    implements _$$ShopConfigImplCopyWith<$Res> {
  __$$ShopConfigImplCopyWithImpl(
    _$ShopConfigImpl _value,
    $Res Function(_$ShopConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShopConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shopId = null,
    Object? gstRegistrationNumber = freezed,
    Object? state = null,
    Object? gstMode = null,
    Object? businessType = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ShopConfigImpl(
        shopId: null == shopId
            ? _value.shopId
            : shopId // ignore: cast_nullable_to_non_nullable
                  as String,
        gstRegistrationNumber: freezed == gstRegistrationNumber
            ? _value.gstRegistrationNumber
            : gstRegistrationNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
        gstMode: null == gstMode
            ? _value.gstMode
            : gstMode // ignore: cast_nullable_to_non_nullable
                  as GSTMode,
        businessType: null == businessType
            ? _value.businessType
            : businessType // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShopConfigImpl implements _ShopConfig {
  const _$ShopConfigImpl({
    required this.shopId,
    @JsonKey(name: 'gst_registration_number') this.gstRegistrationNumber,
    required this.state,
    @JsonKey(name: 'gst_mode') required this.gstMode,
    @JsonKey(name: 'business_type') required this.businessType,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$ShopConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShopConfigImplFromJson(json);

  @override
  final String shopId;
  @override
  @JsonKey(name: 'gst_registration_number')
  final String? gstRegistrationNumber;
  @override
  final String state;
  @override
  @JsonKey(name: 'gst_mode')
  final GSTMode gstMode;
  @override
  @JsonKey(name: 'business_type')
  final String businessType;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ShopConfig(shopId: $shopId, gstRegistrationNumber: $gstRegistrationNumber, state: $state, gstMode: $gstMode, businessType: $businessType, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShopConfigImpl &&
            (identical(other.shopId, shopId) || other.shopId == shopId) &&
            (identical(other.gstRegistrationNumber, gstRegistrationNumber) ||
                other.gstRegistrationNumber == gstRegistrationNumber) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.gstMode, gstMode) || other.gstMode == gstMode) &&
            (identical(other.businessType, businessType) ||
                other.businessType == businessType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    shopId,
    gstRegistrationNumber,
    state,
    gstMode,
    businessType,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ShopConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShopConfigImplCopyWith<_$ShopConfigImpl> get copyWith =>
      __$$ShopConfigImplCopyWithImpl<_$ShopConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShopConfigImplToJson(this);
  }
}

abstract class _ShopConfig implements ShopConfig {
  const factory _ShopConfig({
    required final String shopId,
    @JsonKey(name: 'gst_registration_number')
    final String? gstRegistrationNumber,
    required final String state,
    @JsonKey(name: 'gst_mode') required final GSTMode gstMode,
    @JsonKey(name: 'business_type') required final String businessType,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$ShopConfigImpl;

  factory _ShopConfig.fromJson(Map<String, dynamic> json) =
      _$ShopConfigImpl.fromJson;

  @override
  String get shopId;
  @override
  @JsonKey(name: 'gst_registration_number')
  String? get gstRegistrationNumber;
  @override
  String get state;
  @override
  @JsonKey(name: 'gst_mode')
  GSTMode get gstMode;
  @override
  @JsonKey(name: 'business_type')
  String get businessType;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of ShopConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShopConfigImplCopyWith<_$ShopConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
