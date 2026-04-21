// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draft_approval.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DraftApproval {

@JsonKey(name: 'approval_id') String get approvalId;@JsonKey(name: 'draft_invoice_id') String? get draftInvoiceId;@JsonKey(name: 'shop_id') String get shopId;@JsonKey(name: 'customer_id') String? get customerId;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'proposed_items') List<CartItem> get proposedItems;@JsonKey(name: 'proposed_tax_breakdown') TaxBreakdown get proposedTaxBreakdown;@JsonKey(name: 'proposed_total') double get proposedTotal;@JsonKey(name: 'approval_status') ApprovalStatus get approvalStatus;@JsonKey(name: 'reviewed_by') String? get reviewedBy;@JsonKey(name: 'reviewed_at') DateTime? get reviewedAt;@JsonKey(name: 'approval_notes') String? get approvalNotes;@JsonKey(name: 'sale_id') String? get saleId;
/// Create a copy of DraftApproval
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftApprovalCopyWith<DraftApproval> get copyWith => _$DraftApprovalCopyWithImpl<DraftApproval>(this as DraftApproval, _$identity);

  /// Serializes this DraftApproval to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftApproval&&(identical(other.approvalId, approvalId) || other.approvalId == approvalId)&&(identical(other.draftInvoiceId, draftInvoiceId) || other.draftInvoiceId == draftInvoiceId)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.proposedItems, proposedItems)&&(identical(other.proposedTaxBreakdown, proposedTaxBreakdown) || other.proposedTaxBreakdown == proposedTaxBreakdown)&&(identical(other.proposedTotal, proposedTotal) || other.proposedTotal == proposedTotal)&&(identical(other.approvalStatus, approvalStatus) || other.approvalStatus == approvalStatus)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.approvalNotes, approvalNotes) || other.approvalNotes == approvalNotes)&&(identical(other.saleId, saleId) || other.saleId == saleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,approvalId,draftInvoiceId,shopId,customerId,createdAt,const DeepCollectionEquality().hash(proposedItems),proposedTaxBreakdown,proposedTotal,approvalStatus,reviewedBy,reviewedAt,approvalNotes,saleId);

@override
String toString() {
  return 'DraftApproval(approvalId: $approvalId, draftInvoiceId: $draftInvoiceId, shopId: $shopId, customerId: $customerId, createdAt: $createdAt, proposedItems: $proposedItems, proposedTaxBreakdown: $proposedTaxBreakdown, proposedTotal: $proposedTotal, approvalStatus: $approvalStatus, reviewedBy: $reviewedBy, reviewedAt: $reviewedAt, approvalNotes: $approvalNotes, saleId: $saleId)';
}


}

/// @nodoc
abstract mixin class $DraftApprovalCopyWith<$Res>  {
  factory $DraftApprovalCopyWith(DraftApproval value, $Res Function(DraftApproval) _then) = _$DraftApprovalCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'approval_id') String approvalId,@JsonKey(name: 'draft_invoice_id') String? draftInvoiceId,@JsonKey(name: 'shop_id') String shopId,@JsonKey(name: 'customer_id') String? customerId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'proposed_items') List<CartItem> proposedItems,@JsonKey(name: 'proposed_tax_breakdown') TaxBreakdown proposedTaxBreakdown,@JsonKey(name: 'proposed_total') double proposedTotal,@JsonKey(name: 'approval_status') ApprovalStatus approvalStatus,@JsonKey(name: 'reviewed_by') String? reviewedBy,@JsonKey(name: 'reviewed_at') DateTime? reviewedAt,@JsonKey(name: 'approval_notes') String? approvalNotes,@JsonKey(name: 'sale_id') String? saleId
});


$TaxBreakdownCopyWith<$Res> get proposedTaxBreakdown;

}
/// @nodoc
class _$DraftApprovalCopyWithImpl<$Res>
    implements $DraftApprovalCopyWith<$Res> {
  _$DraftApprovalCopyWithImpl(this._self, this._then);

  final DraftApproval _self;
  final $Res Function(DraftApproval) _then;

/// Create a copy of DraftApproval
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? approvalId = null,Object? draftInvoiceId = freezed,Object? shopId = null,Object? customerId = freezed,Object? createdAt = null,Object? proposedItems = null,Object? proposedTaxBreakdown = null,Object? proposedTotal = null,Object? approvalStatus = null,Object? reviewedBy = freezed,Object? reviewedAt = freezed,Object? approvalNotes = freezed,Object? saleId = freezed,}) {
  return _then(_self.copyWith(
approvalId: null == approvalId ? _self.approvalId : approvalId // ignore: cast_nullable_to_non_nullable
as String,draftInvoiceId: freezed == draftInvoiceId ? _self.draftInvoiceId : draftInvoiceId // ignore: cast_nullable_to_non_nullable
as String?,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,proposedItems: null == proposedItems ? _self.proposedItems : proposedItems // ignore: cast_nullable_to_non_nullable
as List<CartItem>,proposedTaxBreakdown: null == proposedTaxBreakdown ? _self.proposedTaxBreakdown : proposedTaxBreakdown // ignore: cast_nullable_to_non_nullable
as TaxBreakdown,proposedTotal: null == proposedTotal ? _self.proposedTotal : proposedTotal // ignore: cast_nullable_to_non_nullable
as double,approvalStatus: null == approvalStatus ? _self.approvalStatus : approvalStatus // ignore: cast_nullable_to_non_nullable
as ApprovalStatus,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,approvalNotes: freezed == approvalNotes ? _self.approvalNotes : approvalNotes // ignore: cast_nullable_to_non_nullable
as String?,saleId: freezed == saleId ? _self.saleId : saleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DraftApproval
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaxBreakdownCopyWith<$Res> get proposedTaxBreakdown {
  
  return $TaxBreakdownCopyWith<$Res>(_self.proposedTaxBreakdown, (value) {
    return _then(_self.copyWith(proposedTaxBreakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [DraftApproval].
extension DraftApprovalPatterns on DraftApproval {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DraftApproval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DraftApproval() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DraftApproval value)  $default,){
final _that = this;
switch (_that) {
case _DraftApproval():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DraftApproval value)?  $default,){
final _that = this;
switch (_that) {
case _DraftApproval() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'approval_id')  String approvalId, @JsonKey(name: 'draft_invoice_id')  String? draftInvoiceId, @JsonKey(name: 'shop_id')  String shopId, @JsonKey(name: 'customer_id')  String? customerId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'proposed_items')  List<CartItem> proposedItems, @JsonKey(name: 'proposed_tax_breakdown')  TaxBreakdown proposedTaxBreakdown, @JsonKey(name: 'proposed_total')  double proposedTotal, @JsonKey(name: 'approval_status')  ApprovalStatus approvalStatus, @JsonKey(name: 'reviewed_by')  String? reviewedBy, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt, @JsonKey(name: 'approval_notes')  String? approvalNotes, @JsonKey(name: 'sale_id')  String? saleId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DraftApproval() when $default != null:
return $default(_that.approvalId,_that.draftInvoiceId,_that.shopId,_that.customerId,_that.createdAt,_that.proposedItems,_that.proposedTaxBreakdown,_that.proposedTotal,_that.approvalStatus,_that.reviewedBy,_that.reviewedAt,_that.approvalNotes,_that.saleId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'approval_id')  String approvalId, @JsonKey(name: 'draft_invoice_id')  String? draftInvoiceId, @JsonKey(name: 'shop_id')  String shopId, @JsonKey(name: 'customer_id')  String? customerId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'proposed_items')  List<CartItem> proposedItems, @JsonKey(name: 'proposed_tax_breakdown')  TaxBreakdown proposedTaxBreakdown, @JsonKey(name: 'proposed_total')  double proposedTotal, @JsonKey(name: 'approval_status')  ApprovalStatus approvalStatus, @JsonKey(name: 'reviewed_by')  String? reviewedBy, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt, @JsonKey(name: 'approval_notes')  String? approvalNotes, @JsonKey(name: 'sale_id')  String? saleId)  $default,) {final _that = this;
switch (_that) {
case _DraftApproval():
return $default(_that.approvalId,_that.draftInvoiceId,_that.shopId,_that.customerId,_that.createdAt,_that.proposedItems,_that.proposedTaxBreakdown,_that.proposedTotal,_that.approvalStatus,_that.reviewedBy,_that.reviewedAt,_that.approvalNotes,_that.saleId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'approval_id')  String approvalId, @JsonKey(name: 'draft_invoice_id')  String? draftInvoiceId, @JsonKey(name: 'shop_id')  String shopId, @JsonKey(name: 'customer_id')  String? customerId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'proposed_items')  List<CartItem> proposedItems, @JsonKey(name: 'proposed_tax_breakdown')  TaxBreakdown proposedTaxBreakdown, @JsonKey(name: 'proposed_total')  double proposedTotal, @JsonKey(name: 'approval_status')  ApprovalStatus approvalStatus, @JsonKey(name: 'reviewed_by')  String? reviewedBy, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt, @JsonKey(name: 'approval_notes')  String? approvalNotes, @JsonKey(name: 'sale_id')  String? saleId)?  $default,) {final _that = this;
switch (_that) {
case _DraftApproval() when $default != null:
return $default(_that.approvalId,_that.draftInvoiceId,_that.shopId,_that.customerId,_that.createdAt,_that.proposedItems,_that.proposedTaxBreakdown,_that.proposedTotal,_that.approvalStatus,_that.reviewedBy,_that.reviewedAt,_that.approvalNotes,_that.saleId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DraftApproval implements DraftApproval {
  const _DraftApproval({@JsonKey(name: 'approval_id') required this.approvalId, @JsonKey(name: 'draft_invoice_id') this.draftInvoiceId, @JsonKey(name: 'shop_id') required this.shopId, @JsonKey(name: 'customer_id') this.customerId, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'proposed_items') required final  List<CartItem> proposedItems, @JsonKey(name: 'proposed_tax_breakdown') required this.proposedTaxBreakdown, @JsonKey(name: 'proposed_total') required this.proposedTotal, @JsonKey(name: 'approval_status') this.approvalStatus = ApprovalStatus.pending, @JsonKey(name: 'reviewed_by') this.reviewedBy, @JsonKey(name: 'reviewed_at') this.reviewedAt, @JsonKey(name: 'approval_notes') this.approvalNotes, @JsonKey(name: 'sale_id') this.saleId}): _proposedItems = proposedItems;
  factory _DraftApproval.fromJson(Map<String, dynamic> json) => _$DraftApprovalFromJson(json);

@override@JsonKey(name: 'approval_id') final  String approvalId;
@override@JsonKey(name: 'draft_invoice_id') final  String? draftInvoiceId;
@override@JsonKey(name: 'shop_id') final  String shopId;
@override@JsonKey(name: 'customer_id') final  String? customerId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
 final  List<CartItem> _proposedItems;
@override@JsonKey(name: 'proposed_items') List<CartItem> get proposedItems {
  if (_proposedItems is EqualUnmodifiableListView) return _proposedItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_proposedItems);
}

@override@JsonKey(name: 'proposed_tax_breakdown') final  TaxBreakdown proposedTaxBreakdown;
@override@JsonKey(name: 'proposed_total') final  double proposedTotal;
@override@JsonKey(name: 'approval_status') final  ApprovalStatus approvalStatus;
@override@JsonKey(name: 'reviewed_by') final  String? reviewedBy;
@override@JsonKey(name: 'reviewed_at') final  DateTime? reviewedAt;
@override@JsonKey(name: 'approval_notes') final  String? approvalNotes;
@override@JsonKey(name: 'sale_id') final  String? saleId;

/// Create a copy of DraftApproval
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DraftApprovalCopyWith<_DraftApproval> get copyWith => __$DraftApprovalCopyWithImpl<_DraftApproval>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DraftApprovalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DraftApproval&&(identical(other.approvalId, approvalId) || other.approvalId == approvalId)&&(identical(other.draftInvoiceId, draftInvoiceId) || other.draftInvoiceId == draftInvoiceId)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._proposedItems, _proposedItems)&&(identical(other.proposedTaxBreakdown, proposedTaxBreakdown) || other.proposedTaxBreakdown == proposedTaxBreakdown)&&(identical(other.proposedTotal, proposedTotal) || other.proposedTotal == proposedTotal)&&(identical(other.approvalStatus, approvalStatus) || other.approvalStatus == approvalStatus)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.approvalNotes, approvalNotes) || other.approvalNotes == approvalNotes)&&(identical(other.saleId, saleId) || other.saleId == saleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,approvalId,draftInvoiceId,shopId,customerId,createdAt,const DeepCollectionEquality().hash(_proposedItems),proposedTaxBreakdown,proposedTotal,approvalStatus,reviewedBy,reviewedAt,approvalNotes,saleId);

@override
String toString() {
  return 'DraftApproval(approvalId: $approvalId, draftInvoiceId: $draftInvoiceId, shopId: $shopId, customerId: $customerId, createdAt: $createdAt, proposedItems: $proposedItems, proposedTaxBreakdown: $proposedTaxBreakdown, proposedTotal: $proposedTotal, approvalStatus: $approvalStatus, reviewedBy: $reviewedBy, reviewedAt: $reviewedAt, approvalNotes: $approvalNotes, saleId: $saleId)';
}


}

/// @nodoc
abstract mixin class _$DraftApprovalCopyWith<$Res> implements $DraftApprovalCopyWith<$Res> {
  factory _$DraftApprovalCopyWith(_DraftApproval value, $Res Function(_DraftApproval) _then) = __$DraftApprovalCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'approval_id') String approvalId,@JsonKey(name: 'draft_invoice_id') String? draftInvoiceId,@JsonKey(name: 'shop_id') String shopId,@JsonKey(name: 'customer_id') String? customerId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'proposed_items') List<CartItem> proposedItems,@JsonKey(name: 'proposed_tax_breakdown') TaxBreakdown proposedTaxBreakdown,@JsonKey(name: 'proposed_total') double proposedTotal,@JsonKey(name: 'approval_status') ApprovalStatus approvalStatus,@JsonKey(name: 'reviewed_by') String? reviewedBy,@JsonKey(name: 'reviewed_at') DateTime? reviewedAt,@JsonKey(name: 'approval_notes') String? approvalNotes,@JsonKey(name: 'sale_id') String? saleId
});


@override $TaxBreakdownCopyWith<$Res> get proposedTaxBreakdown;

}
/// @nodoc
class __$DraftApprovalCopyWithImpl<$Res>
    implements _$DraftApprovalCopyWith<$Res> {
  __$DraftApprovalCopyWithImpl(this._self, this._then);

  final _DraftApproval _self;
  final $Res Function(_DraftApproval) _then;

/// Create a copy of DraftApproval
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? approvalId = null,Object? draftInvoiceId = freezed,Object? shopId = null,Object? customerId = freezed,Object? createdAt = null,Object? proposedItems = null,Object? proposedTaxBreakdown = null,Object? proposedTotal = null,Object? approvalStatus = null,Object? reviewedBy = freezed,Object? reviewedAt = freezed,Object? approvalNotes = freezed,Object? saleId = freezed,}) {
  return _then(_DraftApproval(
approvalId: null == approvalId ? _self.approvalId : approvalId // ignore: cast_nullable_to_non_nullable
as String,draftInvoiceId: freezed == draftInvoiceId ? _self.draftInvoiceId : draftInvoiceId // ignore: cast_nullable_to_non_nullable
as String?,shopId: null == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,proposedItems: null == proposedItems ? _self._proposedItems : proposedItems // ignore: cast_nullable_to_non_nullable
as List<CartItem>,proposedTaxBreakdown: null == proposedTaxBreakdown ? _self.proposedTaxBreakdown : proposedTaxBreakdown // ignore: cast_nullable_to_non_nullable
as TaxBreakdown,proposedTotal: null == proposedTotal ? _self.proposedTotal : proposedTotal // ignore: cast_nullable_to_non_nullable
as double,approvalStatus: null == approvalStatus ? _self.approvalStatus : approvalStatus // ignore: cast_nullable_to_non_nullable
as ApprovalStatus,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,approvalNotes: freezed == approvalNotes ? _self.approvalNotes : approvalNotes // ignore: cast_nullable_to_non_nullable
as String?,saleId: freezed == saleId ? _self.saleId : saleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DraftApproval
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaxBreakdownCopyWith<$Res> get proposedTaxBreakdown {
  
  return $TaxBreakdownCopyWith<$Res>(_self.proposedTaxBreakdown, (value) {
    return _then(_self.copyWith(proposedTaxBreakdown: value));
  });
}
}

// dart format on
