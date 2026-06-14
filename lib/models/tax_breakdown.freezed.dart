// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tax_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaxBreakdown _$TaxBreakdownFromJson(Map<String, dynamic> json) {
  return _TaxBreakdown.fromJson(json);
}

/// @nodoc
mixin _$TaxBreakdown {
  double get subtotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'cgst_amount')
  double get cgstAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'sgst_amount')
  double get sgstAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'igst_amount')
  double get igstAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'gst_mode')
  String get gstMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'applicable_state')
  String get applicableState => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_slab')
  String get taxSlab => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount')
  double get totalAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'breakdown')
  List<Map<String, dynamic>> get breakdown =>
      throw _privateConstructorUsedError;

  /// GST summary grouped by rate — each entry: {rate, taxableAmount, cgst, sgst, igst, totalTax}
  @JsonKey(name: 'rate_wise_summary')
  List<Map<String, dynamic>> get rateWiseSummary =>
      throw _privateConstructorUsedError;

  /// Serializes this TaxBreakdown to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaxBreakdownCopyWith<TaxBreakdown> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaxBreakdownCopyWith<$Res> {
  factory $TaxBreakdownCopyWith(
    TaxBreakdown value,
    $Res Function(TaxBreakdown) then,
  ) = _$TaxBreakdownCopyWithImpl<$Res, TaxBreakdown>;
  @useResult
  $Res call({
    double subtotal,
    @JsonKey(name: 'cgst_amount') double cgstAmount,
    @JsonKey(name: 'sgst_amount') double sgstAmount,
    @JsonKey(name: 'igst_amount') double igstAmount,
    @JsonKey(name: 'gst_mode') String gstMode,
    @JsonKey(name: 'applicable_state') String applicableState,
    @JsonKey(name: 'tax_slab') String taxSlab,
    @JsonKey(name: 'total_amount') double totalAmount,
    @JsonKey(name: 'breakdown') List<Map<String, dynamic>> breakdown,
    @JsonKey(name: 'rate_wise_summary')
    List<Map<String, dynamic>> rateWiseSummary,
  });
}

/// @nodoc
class _$TaxBreakdownCopyWithImpl<$Res, $Val extends TaxBreakdown>
    implements $TaxBreakdownCopyWith<$Res> {
  _$TaxBreakdownCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subtotal = null,
    Object? cgstAmount = null,
    Object? sgstAmount = null,
    Object? igstAmount = null,
    Object? gstMode = null,
    Object? applicableState = null,
    Object? taxSlab = null,
    Object? totalAmount = null,
    Object? breakdown = null,
    Object? rateWiseSummary = null,
  }) {
    return _then(
      _value.copyWith(
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
            cgstAmount: null == cgstAmount
                ? _value.cgstAmount
                : cgstAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            sgstAmount: null == sgstAmount
                ? _value.sgstAmount
                : sgstAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            igstAmount: null == igstAmount
                ? _value.igstAmount
                : igstAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            gstMode: null == gstMode
                ? _value.gstMode
                : gstMode // ignore: cast_nullable_to_non_nullable
                      as String,
            applicableState: null == applicableState
                ? _value.applicableState
                : applicableState // ignore: cast_nullable_to_non_nullable
                      as String,
            taxSlab: null == taxSlab
                ? _value.taxSlab
                : taxSlab // ignore: cast_nullable_to_non_nullable
                      as String,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            breakdown: null == breakdown
                ? _value.breakdown
                : breakdown // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            rateWiseSummary: null == rateWiseSummary
                ? _value.rateWiseSummary
                : rateWiseSummary // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaxBreakdownImplCopyWith<$Res>
    implements $TaxBreakdownCopyWith<$Res> {
  factory _$$TaxBreakdownImplCopyWith(
    _$TaxBreakdownImpl value,
    $Res Function(_$TaxBreakdownImpl) then,
  ) = __$$TaxBreakdownImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double subtotal,
    @JsonKey(name: 'cgst_amount') double cgstAmount,
    @JsonKey(name: 'sgst_amount') double sgstAmount,
    @JsonKey(name: 'igst_amount') double igstAmount,
    @JsonKey(name: 'gst_mode') String gstMode,
    @JsonKey(name: 'applicable_state') String applicableState,
    @JsonKey(name: 'tax_slab') String taxSlab,
    @JsonKey(name: 'total_amount') double totalAmount,
    @JsonKey(name: 'breakdown') List<Map<String, dynamic>> breakdown,
    @JsonKey(name: 'rate_wise_summary')
    List<Map<String, dynamic>> rateWiseSummary,
  });
}

/// @nodoc
class __$$TaxBreakdownImplCopyWithImpl<$Res>
    extends _$TaxBreakdownCopyWithImpl<$Res, _$TaxBreakdownImpl>
    implements _$$TaxBreakdownImplCopyWith<$Res> {
  __$$TaxBreakdownImplCopyWithImpl(
    _$TaxBreakdownImpl _value,
    $Res Function(_$TaxBreakdownImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subtotal = null,
    Object? cgstAmount = null,
    Object? sgstAmount = null,
    Object? igstAmount = null,
    Object? gstMode = null,
    Object? applicableState = null,
    Object? taxSlab = null,
    Object? totalAmount = null,
    Object? breakdown = null,
    Object? rateWiseSummary = null,
  }) {
    return _then(
      _$TaxBreakdownImpl(
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
        cgstAmount: null == cgstAmount
            ? _value.cgstAmount
            : cgstAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        sgstAmount: null == sgstAmount
            ? _value.sgstAmount
            : sgstAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        igstAmount: null == igstAmount
            ? _value.igstAmount
            : igstAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        gstMode: null == gstMode
            ? _value.gstMode
            : gstMode // ignore: cast_nullable_to_non_nullable
                  as String,
        applicableState: null == applicableState
            ? _value.applicableState
            : applicableState // ignore: cast_nullable_to_non_nullable
                  as String,
        taxSlab: null == taxSlab
            ? _value.taxSlab
            : taxSlab // ignore: cast_nullable_to_non_nullable
                  as String,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        breakdown: null == breakdown
            ? _value._breakdown
            : breakdown // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        rateWiseSummary: null == rateWiseSummary
            ? _value._rateWiseSummary
            : rateWiseSummary // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaxBreakdownImpl implements _TaxBreakdown {
  const _$TaxBreakdownImpl({
    required this.subtotal,
    @JsonKey(name: 'cgst_amount') required this.cgstAmount,
    @JsonKey(name: 'sgst_amount') required this.sgstAmount,
    @JsonKey(name: 'igst_amount') required this.igstAmount,
    @JsonKey(name: 'gst_mode') required this.gstMode,
    @JsonKey(name: 'applicable_state') required this.applicableState,
    @JsonKey(name: 'tax_slab') required this.taxSlab,
    @JsonKey(name: 'total_amount') required this.totalAmount,
    @JsonKey(name: 'breakdown')
    required final List<Map<String, dynamic>> breakdown,
    @JsonKey(name: 'rate_wise_summary')
    final List<Map<String, dynamic>> rateWiseSummary = const [],
  }) : _breakdown = breakdown,
       _rateWiseSummary = rateWiseSummary;

  factory _$TaxBreakdownImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaxBreakdownImplFromJson(json);

  @override
  final double subtotal;
  @override
  @JsonKey(name: 'cgst_amount')
  final double cgstAmount;
  @override
  @JsonKey(name: 'sgst_amount')
  final double sgstAmount;
  @override
  @JsonKey(name: 'igst_amount')
  final double igstAmount;
  @override
  @JsonKey(name: 'gst_mode')
  final String gstMode;
  @override
  @JsonKey(name: 'applicable_state')
  final String applicableState;
  @override
  @JsonKey(name: 'tax_slab')
  final String taxSlab;
  @override
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  final List<Map<String, dynamic>> _breakdown;
  @override
  @JsonKey(name: 'breakdown')
  List<Map<String, dynamic>> get breakdown {
    if (_breakdown is EqualUnmodifiableListView) return _breakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_breakdown);
  }

  /// GST summary grouped by rate — each entry: {rate, taxableAmount, cgst, sgst, igst, totalTax}
  final List<Map<String, dynamic>> _rateWiseSummary;

  /// GST summary grouped by rate — each entry: {rate, taxableAmount, cgst, sgst, igst, totalTax}
  @override
  @JsonKey(name: 'rate_wise_summary')
  List<Map<String, dynamic>> get rateWiseSummary {
    if (_rateWiseSummary is EqualUnmodifiableListView) return _rateWiseSummary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rateWiseSummary);
  }

  @override
  String toString() {
    return 'TaxBreakdown(subtotal: $subtotal, cgstAmount: $cgstAmount, sgstAmount: $sgstAmount, igstAmount: $igstAmount, gstMode: $gstMode, applicableState: $applicableState, taxSlab: $taxSlab, totalAmount: $totalAmount, breakdown: $breakdown, rateWiseSummary: $rateWiseSummary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaxBreakdownImpl &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.cgstAmount, cgstAmount) ||
                other.cgstAmount == cgstAmount) &&
            (identical(other.sgstAmount, sgstAmount) ||
                other.sgstAmount == sgstAmount) &&
            (identical(other.igstAmount, igstAmount) ||
                other.igstAmount == igstAmount) &&
            (identical(other.gstMode, gstMode) || other.gstMode == gstMode) &&
            (identical(other.applicableState, applicableState) ||
                other.applicableState == applicableState) &&
            (identical(other.taxSlab, taxSlab) || other.taxSlab == taxSlab) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            const DeepCollectionEquality().equals(
              other._breakdown,
              _breakdown,
            ) &&
            const DeepCollectionEquality().equals(
              other._rateWiseSummary,
              _rateWiseSummary,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    subtotal,
    cgstAmount,
    sgstAmount,
    igstAmount,
    gstMode,
    applicableState,
    taxSlab,
    totalAmount,
    const DeepCollectionEquality().hash(_breakdown),
    const DeepCollectionEquality().hash(_rateWiseSummary),
  );

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaxBreakdownImplCopyWith<_$TaxBreakdownImpl> get copyWith =>
      __$$TaxBreakdownImplCopyWithImpl<_$TaxBreakdownImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaxBreakdownImplToJson(this);
  }
}

abstract class _TaxBreakdown implements TaxBreakdown {
  const factory _TaxBreakdown({
    required final double subtotal,
    @JsonKey(name: 'cgst_amount') required final double cgstAmount,
    @JsonKey(name: 'sgst_amount') required final double sgstAmount,
    @JsonKey(name: 'igst_amount') required final double igstAmount,
    @JsonKey(name: 'gst_mode') required final String gstMode,
    @JsonKey(name: 'applicable_state') required final String applicableState,
    @JsonKey(name: 'tax_slab') required final String taxSlab,
    @JsonKey(name: 'total_amount') required final double totalAmount,
    @JsonKey(name: 'breakdown')
    required final List<Map<String, dynamic>> breakdown,
    @JsonKey(name: 'rate_wise_summary')
    final List<Map<String, dynamic>> rateWiseSummary,
  }) = _$TaxBreakdownImpl;

  factory _TaxBreakdown.fromJson(Map<String, dynamic> json) =
      _$TaxBreakdownImpl.fromJson;

  @override
  double get subtotal;
  @override
  @JsonKey(name: 'cgst_amount')
  double get cgstAmount;
  @override
  @JsonKey(name: 'sgst_amount')
  double get sgstAmount;
  @override
  @JsonKey(name: 'igst_amount')
  double get igstAmount;
  @override
  @JsonKey(name: 'gst_mode')
  String get gstMode;
  @override
  @JsonKey(name: 'applicable_state')
  String get applicableState;
  @override
  @JsonKey(name: 'tax_slab')
  String get taxSlab;
  @override
  @JsonKey(name: 'total_amount')
  double get totalAmount;
  @override
  @JsonKey(name: 'breakdown')
  List<Map<String, dynamic>> get breakdown;

  /// GST summary grouped by rate — each entry: {rate, taxableAmount, cgst, sgst, igst, totalTax}
  @override
  @JsonKey(name: 'rate_wise_summary')
  List<Map<String, dynamic>> get rateWiseSummary;

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaxBreakdownImplCopyWith<_$TaxBreakdownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
