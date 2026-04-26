// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tax_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaxBreakdown {

 double get subtotal;@JsonKey(name: 'cgst_amount') double get cgstAmount;@JsonKey(name: 'sgst_amount') double get sgstAmount;@JsonKey(name: 'igst_amount') double get igstAmount;@JsonKey(name: 'gst_mode') String get gstMode;@JsonKey(name: 'applicable_state') String get applicableState;@JsonKey(name: 'tax_slab') String get taxSlab;@JsonKey(name: 'total_amount') double get totalAmount;@JsonKey(name: 'breakdown') List<Map<String, dynamic>> get breakdown;/// GST summary grouped by rate — each entry: {rate, taxableAmount, cgst, sgst, igst, totalTax}
@JsonKey(name: 'rate_wise_summary') List<Map<String, dynamic>> get rateWiseSummary;
/// Create a copy of TaxBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaxBreakdownCopyWith<TaxBreakdown> get copyWith => _$TaxBreakdownCopyWithImpl<TaxBreakdown>(this as TaxBreakdown, _$identity);

  /// Serializes this TaxBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaxBreakdown&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.cgstAmount, cgstAmount) || other.cgstAmount == cgstAmount)&&(identical(other.sgstAmount, sgstAmount) || other.sgstAmount == sgstAmount)&&(identical(other.igstAmount, igstAmount) || other.igstAmount == igstAmount)&&(identical(other.gstMode, gstMode) || other.gstMode == gstMode)&&(identical(other.applicableState, applicableState) || other.applicableState == applicableState)&&(identical(other.taxSlab, taxSlab) || other.taxSlab == taxSlab)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&const DeepCollectionEquality().equals(other.breakdown, breakdown)&&const DeepCollectionEquality().equals(other.rateWiseSummary, rateWiseSummary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subtotal,cgstAmount,sgstAmount,igstAmount,gstMode,applicableState,taxSlab,totalAmount,const DeepCollectionEquality().hash(breakdown),const DeepCollectionEquality().hash(rateWiseSummary));

@override
String toString() {
  return 'TaxBreakdown(subtotal: $subtotal, cgstAmount: $cgstAmount, sgstAmount: $sgstAmount, igstAmount: $igstAmount, gstMode: $gstMode, applicableState: $applicableState, taxSlab: $taxSlab, totalAmount: $totalAmount, breakdown: $breakdown, rateWiseSummary: $rateWiseSummary)';
}


}

/// @nodoc
abstract mixin class $TaxBreakdownCopyWith<$Res>  {
  factory $TaxBreakdownCopyWith(TaxBreakdown value, $Res Function(TaxBreakdown) _then) = _$TaxBreakdownCopyWithImpl;
@useResult
$Res call({
 double subtotal,@JsonKey(name: 'cgst_amount') double cgstAmount,@JsonKey(name: 'sgst_amount') double sgstAmount,@JsonKey(name: 'igst_amount') double igstAmount,@JsonKey(name: 'gst_mode') String gstMode,@JsonKey(name: 'applicable_state') String applicableState,@JsonKey(name: 'tax_slab') String taxSlab,@JsonKey(name: 'total_amount') double totalAmount,@JsonKey(name: 'breakdown') List<Map<String, dynamic>> breakdown,@JsonKey(name: 'rate_wise_summary') List<Map<String, dynamic>> rateWiseSummary
});




}
/// @nodoc
class _$TaxBreakdownCopyWithImpl<$Res>
    implements $TaxBreakdownCopyWith<$Res> {
  _$TaxBreakdownCopyWithImpl(this._self, this._then);

  final TaxBreakdown _self;
  final $Res Function(TaxBreakdown) _then;

/// Create a copy of TaxBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subtotal = null,Object? cgstAmount = null,Object? sgstAmount = null,Object? igstAmount = null,Object? gstMode = null,Object? applicableState = null,Object? taxSlab = null,Object? totalAmount = null,Object? breakdown = null,Object? rateWiseSummary = null,}) {
  return _then(_self.copyWith(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,cgstAmount: null == cgstAmount ? _self.cgstAmount : cgstAmount // ignore: cast_nullable_to_non_nullable
as double,sgstAmount: null == sgstAmount ? _self.sgstAmount : sgstAmount // ignore: cast_nullable_to_non_nullable
as double,igstAmount: null == igstAmount ? _self.igstAmount : igstAmount // ignore: cast_nullable_to_non_nullable
as double,gstMode: null == gstMode ? _self.gstMode : gstMode // ignore: cast_nullable_to_non_nullable
as String,applicableState: null == applicableState ? _self.applicableState : applicableState // ignore: cast_nullable_to_non_nullable
as String,taxSlab: null == taxSlab ? _self.taxSlab : taxSlab // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,rateWiseSummary: null == rateWiseSummary ? _self.rateWiseSummary : rateWiseSummary // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [TaxBreakdown].
extension TaxBreakdownPatterns on TaxBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaxBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaxBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaxBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _TaxBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaxBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _TaxBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double subtotal, @JsonKey(name: 'cgst_amount')  double cgstAmount, @JsonKey(name: 'sgst_amount')  double sgstAmount, @JsonKey(name: 'igst_amount')  double igstAmount, @JsonKey(name: 'gst_mode')  String gstMode, @JsonKey(name: 'applicable_state')  String applicableState, @JsonKey(name: 'tax_slab')  String taxSlab, @JsonKey(name: 'total_amount')  double totalAmount, @JsonKey(name: 'breakdown')  List<Map<String, dynamic>> breakdown, @JsonKey(name: 'rate_wise_summary')  List<Map<String, dynamic>> rateWiseSummary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaxBreakdown() when $default != null:
return $default(_that.subtotal,_that.cgstAmount,_that.sgstAmount,_that.igstAmount,_that.gstMode,_that.applicableState,_that.taxSlab,_that.totalAmount,_that.breakdown,_that.rateWiseSummary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double subtotal, @JsonKey(name: 'cgst_amount')  double cgstAmount, @JsonKey(name: 'sgst_amount')  double sgstAmount, @JsonKey(name: 'igst_amount')  double igstAmount, @JsonKey(name: 'gst_mode')  String gstMode, @JsonKey(name: 'applicable_state')  String applicableState, @JsonKey(name: 'tax_slab')  String taxSlab, @JsonKey(name: 'total_amount')  double totalAmount, @JsonKey(name: 'breakdown')  List<Map<String, dynamic>> breakdown, @JsonKey(name: 'rate_wise_summary')  List<Map<String, dynamic>> rateWiseSummary)  $default,) {final _that = this;
switch (_that) {
case _TaxBreakdown():
return $default(_that.subtotal,_that.cgstAmount,_that.sgstAmount,_that.igstAmount,_that.gstMode,_that.applicableState,_that.taxSlab,_that.totalAmount,_that.breakdown,_that.rateWiseSummary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double subtotal, @JsonKey(name: 'cgst_amount')  double cgstAmount, @JsonKey(name: 'sgst_amount')  double sgstAmount, @JsonKey(name: 'igst_amount')  double igstAmount, @JsonKey(name: 'gst_mode')  String gstMode, @JsonKey(name: 'applicable_state')  String applicableState, @JsonKey(name: 'tax_slab')  String taxSlab, @JsonKey(name: 'total_amount')  double totalAmount, @JsonKey(name: 'breakdown')  List<Map<String, dynamic>> breakdown, @JsonKey(name: 'rate_wise_summary')  List<Map<String, dynamic>> rateWiseSummary)?  $default,) {final _that = this;
switch (_that) {
case _TaxBreakdown() when $default != null:
return $default(_that.subtotal,_that.cgstAmount,_that.sgstAmount,_that.igstAmount,_that.gstMode,_that.applicableState,_that.taxSlab,_that.totalAmount,_that.breakdown,_that.rateWiseSummary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaxBreakdown implements TaxBreakdown {
  const _TaxBreakdown({required this.subtotal, @JsonKey(name: 'cgst_amount') required this.cgstAmount, @JsonKey(name: 'sgst_amount') required this.sgstAmount, @JsonKey(name: 'igst_amount') required this.igstAmount, @JsonKey(name: 'gst_mode') required this.gstMode, @JsonKey(name: 'applicable_state') required this.applicableState, @JsonKey(name: 'tax_slab') required this.taxSlab, @JsonKey(name: 'total_amount') required this.totalAmount, @JsonKey(name: 'breakdown') required final  List<Map<String, dynamic>> breakdown, @JsonKey(name: 'rate_wise_summary') final  List<Map<String, dynamic>> rateWiseSummary = const []}): _breakdown = breakdown,_rateWiseSummary = rateWiseSummary;
  factory _TaxBreakdown.fromJson(Map<String, dynamic> json) => _$TaxBreakdownFromJson(json);

@override final  double subtotal;
@override@JsonKey(name: 'cgst_amount') final  double cgstAmount;
@override@JsonKey(name: 'sgst_amount') final  double sgstAmount;
@override@JsonKey(name: 'igst_amount') final  double igstAmount;
@override@JsonKey(name: 'gst_mode') final  String gstMode;
@override@JsonKey(name: 'applicable_state') final  String applicableState;
@override@JsonKey(name: 'tax_slab') final  String taxSlab;
@override@JsonKey(name: 'total_amount') final  double totalAmount;
 final  List<Map<String, dynamic>> _breakdown;
@override@JsonKey(name: 'breakdown') List<Map<String, dynamic>> get breakdown {
  if (_breakdown is EqualUnmodifiableListView) return _breakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breakdown);
}

/// GST summary grouped by rate — each entry: {rate, taxableAmount, cgst, sgst, igst, totalTax}
 final  List<Map<String, dynamic>> _rateWiseSummary;
/// GST summary grouped by rate — each entry: {rate, taxableAmount, cgst, sgst, igst, totalTax}
@override@JsonKey(name: 'rate_wise_summary') List<Map<String, dynamic>> get rateWiseSummary {
  if (_rateWiseSummary is EqualUnmodifiableListView) return _rateWiseSummary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rateWiseSummary);
}


/// Create a copy of TaxBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaxBreakdownCopyWith<_TaxBreakdown> get copyWith => __$TaxBreakdownCopyWithImpl<_TaxBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaxBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaxBreakdown&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.cgstAmount, cgstAmount) || other.cgstAmount == cgstAmount)&&(identical(other.sgstAmount, sgstAmount) || other.sgstAmount == sgstAmount)&&(identical(other.igstAmount, igstAmount) || other.igstAmount == igstAmount)&&(identical(other.gstMode, gstMode) || other.gstMode == gstMode)&&(identical(other.applicableState, applicableState) || other.applicableState == applicableState)&&(identical(other.taxSlab, taxSlab) || other.taxSlab == taxSlab)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&const DeepCollectionEquality().equals(other._breakdown, _breakdown)&&const DeepCollectionEquality().equals(other._rateWiseSummary, _rateWiseSummary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subtotal,cgstAmount,sgstAmount,igstAmount,gstMode,applicableState,taxSlab,totalAmount,const DeepCollectionEquality().hash(_breakdown),const DeepCollectionEquality().hash(_rateWiseSummary));

@override
String toString() {
  return 'TaxBreakdown(subtotal: $subtotal, cgstAmount: $cgstAmount, sgstAmount: $sgstAmount, igstAmount: $igstAmount, gstMode: $gstMode, applicableState: $applicableState, taxSlab: $taxSlab, totalAmount: $totalAmount, breakdown: $breakdown, rateWiseSummary: $rateWiseSummary)';
}


}

/// @nodoc
abstract mixin class _$TaxBreakdownCopyWith<$Res> implements $TaxBreakdownCopyWith<$Res> {
  factory _$TaxBreakdownCopyWith(_TaxBreakdown value, $Res Function(_TaxBreakdown) _then) = __$TaxBreakdownCopyWithImpl;
@override @useResult
$Res call({
 double subtotal,@JsonKey(name: 'cgst_amount') double cgstAmount,@JsonKey(name: 'sgst_amount') double sgstAmount,@JsonKey(name: 'igst_amount') double igstAmount,@JsonKey(name: 'gst_mode') String gstMode,@JsonKey(name: 'applicable_state') String applicableState,@JsonKey(name: 'tax_slab') String taxSlab,@JsonKey(name: 'total_amount') double totalAmount,@JsonKey(name: 'breakdown') List<Map<String, dynamic>> breakdown,@JsonKey(name: 'rate_wise_summary') List<Map<String, dynamic>> rateWiseSummary
});




}
/// @nodoc
class __$TaxBreakdownCopyWithImpl<$Res>
    implements _$TaxBreakdownCopyWith<$Res> {
  __$TaxBreakdownCopyWithImpl(this._self, this._then);

  final _TaxBreakdown _self;
  final $Res Function(_TaxBreakdown) _then;

/// Create a copy of TaxBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subtotal = null,Object? cgstAmount = null,Object? sgstAmount = null,Object? igstAmount = null,Object? gstMode = null,Object? applicableState = null,Object? taxSlab = null,Object? totalAmount = null,Object? breakdown = null,Object? rateWiseSummary = null,}) {
  return _then(_TaxBreakdown(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,cgstAmount: null == cgstAmount ? _self.cgstAmount : cgstAmount // ignore: cast_nullable_to_non_nullable
as double,sgstAmount: null == sgstAmount ? _self.sgstAmount : sgstAmount // ignore: cast_nullable_to_non_nullable
as double,igstAmount: null == igstAmount ? _self.igstAmount : igstAmount // ignore: cast_nullable_to_non_nullable
as double,gstMode: null == gstMode ? _self.gstMode : gstMode // ignore: cast_nullable_to_non_nullable
as String,applicableState: null == applicableState ? _self.applicableState : applicableState // ignore: cast_nullable_to_non_nullable
as String,taxSlab: null == taxSlab ? _self.taxSlab : taxSlab // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,breakdown: null == breakdown ? _self._breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,rateWiseSummary: null == rateWiseSummary ? _self._rateWiseSummary : rateWiseSummary // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

// dart format on
