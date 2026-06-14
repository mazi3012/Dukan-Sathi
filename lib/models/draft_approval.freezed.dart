// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draft_approval.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DraftApproval _$DraftApprovalFromJson(Map<String, dynamic> json) {
  return _DraftApproval.fromJson(json);
}

/// @nodoc
mixin _$DraftApproval {
  @JsonKey(name: 'approval_id')
  String get approvalId => throw _privateConstructorUsedError;
  @JsonKey(name: 'draft_invoice_id')
  String? get draftInvoiceId => throw _privateConstructorUsedError;
  @JsonKey(name: 'shop_id')
  String get shopId => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_id')
  String? get customerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'proposed_items')
  List<CartItem> get proposedItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'proposed_tax_breakdown')
  TaxBreakdown get proposedTaxBreakdown => throw _privateConstructorUsedError;
  @JsonKey(name: 'proposed_total')
  double get proposedTotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'approval_status')
  ApprovalStatus get approvalStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'reviewed_by')
  String? get reviewedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'reviewed_at')
  DateTime? get reviewedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'approval_notes')
  String? get approvalNotes => throw _privateConstructorUsedError;
  @JsonKey(name: 'sale_id')
  String? get saleId => throw _privateConstructorUsedError;
  @JsonKey(name: 'gst_type')
  String? get gstType => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_type')
  String? get discountType => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_value')
  double? get discountValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_amount')
  double? get discountAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'subtotal_before_discount')
  double? get subtotalBeforeDiscount => throw _privateConstructorUsedError;
  @JsonKey(name: 'subtotal_after_discount')
  double? get subtotalAfterDiscount => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_status')
  String get paymentStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount_paid')
  double get amountPaid => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_amount')
  double get dueAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_name')
  String? get customerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_state')
  String? get customerState => throw _privateConstructorUsedError;

  /// Serializes this DraftApproval to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DraftApproval
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DraftApprovalCopyWith<DraftApproval> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DraftApprovalCopyWith<$Res> {
  factory $DraftApprovalCopyWith(
    DraftApproval value,
    $Res Function(DraftApproval) then,
  ) = _$DraftApprovalCopyWithImpl<$Res, DraftApproval>;
  @useResult
  $Res call({
    @JsonKey(name: 'approval_id') String approvalId,
    @JsonKey(name: 'draft_invoice_id') String? draftInvoiceId,
    @JsonKey(name: 'shop_id') String shopId,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'proposed_items') List<CartItem> proposedItems,
    @JsonKey(name: 'proposed_tax_breakdown') TaxBreakdown proposedTaxBreakdown,
    @JsonKey(name: 'proposed_total') double proposedTotal,
    @JsonKey(name: 'approval_status') ApprovalStatus approvalStatus,
    @JsonKey(name: 'reviewed_by') String? reviewedBy,
    @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
    @JsonKey(name: 'approval_notes') String? approvalNotes,
    @JsonKey(name: 'sale_id') String? saleId,
    @JsonKey(name: 'gst_type') String? gstType,
    @JsonKey(name: 'discount_type') String? discountType,
    @JsonKey(name: 'discount_value') double? discountValue,
    @JsonKey(name: 'discount_amount') double? discountAmount,
    @JsonKey(name: 'subtotal_before_discount') double? subtotalBeforeDiscount,
    @JsonKey(name: 'subtotal_after_discount') double? subtotalAfterDiscount,
    @JsonKey(name: 'payment_status') String paymentStatus,
    @JsonKey(name: 'amount_paid') double amountPaid,
    @JsonKey(name: 'due_amount') double dueAmount,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_state') String? customerState,
  });

  $TaxBreakdownCopyWith<$Res> get proposedTaxBreakdown;
}

/// @nodoc
class _$DraftApprovalCopyWithImpl<$Res, $Val extends DraftApproval>
    implements $DraftApprovalCopyWith<$Res> {
  _$DraftApprovalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DraftApproval
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? approvalId = null,
    Object? draftInvoiceId = freezed,
    Object? shopId = null,
    Object? customerId = freezed,
    Object? createdAt = null,
    Object? proposedItems = null,
    Object? proposedTaxBreakdown = null,
    Object? proposedTotal = null,
    Object? approvalStatus = null,
    Object? reviewedBy = freezed,
    Object? reviewedAt = freezed,
    Object? approvalNotes = freezed,
    Object? saleId = freezed,
    Object? gstType = freezed,
    Object? discountType = freezed,
    Object? discountValue = freezed,
    Object? discountAmount = freezed,
    Object? subtotalBeforeDiscount = freezed,
    Object? subtotalAfterDiscount = freezed,
    Object? paymentStatus = null,
    Object? amountPaid = null,
    Object? dueAmount = null,
    Object? customerName = freezed,
    Object? customerState = freezed,
  }) {
    return _then(
      _value.copyWith(
            approvalId: null == approvalId
                ? _value.approvalId
                : approvalId // ignore: cast_nullable_to_non_nullable
                      as String,
            draftInvoiceId: freezed == draftInvoiceId
                ? _value.draftInvoiceId
                : draftInvoiceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            shopId: null == shopId
                ? _value.shopId
                : shopId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: freezed == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            proposedItems: null == proposedItems
                ? _value.proposedItems
                : proposedItems // ignore: cast_nullable_to_non_nullable
                      as List<CartItem>,
            proposedTaxBreakdown: null == proposedTaxBreakdown
                ? _value.proposedTaxBreakdown
                : proposedTaxBreakdown // ignore: cast_nullable_to_non_nullable
                      as TaxBreakdown,
            proposedTotal: null == proposedTotal
                ? _value.proposedTotal
                : proposedTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            approvalStatus: null == approvalStatus
                ? _value.approvalStatus
                : approvalStatus // ignore: cast_nullable_to_non_nullable
                      as ApprovalStatus,
            reviewedBy: freezed == reviewedBy
                ? _value.reviewedBy
                : reviewedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            reviewedAt: freezed == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            approvalNotes: freezed == approvalNotes
                ? _value.approvalNotes
                : approvalNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            saleId: freezed == saleId
                ? _value.saleId
                : saleId // ignore: cast_nullable_to_non_nullable
                      as String?,
            gstType: freezed == gstType
                ? _value.gstType
                : gstType // ignore: cast_nullable_to_non_nullable
                      as String?,
            discountType: freezed == discountType
                ? _value.discountType
                : discountType // ignore: cast_nullable_to_non_nullable
                      as String?,
            discountValue: freezed == discountValue
                ? _value.discountValue
                : discountValue // ignore: cast_nullable_to_non_nullable
                      as double?,
            discountAmount: freezed == discountAmount
                ? _value.discountAmount
                : discountAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            subtotalBeforeDiscount: freezed == subtotalBeforeDiscount
                ? _value.subtotalBeforeDiscount
                : subtotalBeforeDiscount // ignore: cast_nullable_to_non_nullable
                      as double?,
            subtotalAfterDiscount: freezed == subtotalAfterDiscount
                ? _value.subtotalAfterDiscount
                : subtotalAfterDiscount // ignore: cast_nullable_to_non_nullable
                      as double?,
            paymentStatus: null == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            amountPaid: null == amountPaid
                ? _value.amountPaid
                : amountPaid // ignore: cast_nullable_to_non_nullable
                      as double,
            dueAmount: null == dueAmount
                ? _value.dueAmount
                : dueAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            customerName: freezed == customerName
                ? _value.customerName
                : customerName // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerState: freezed == customerState
                ? _value.customerState
                : customerState // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of DraftApproval
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TaxBreakdownCopyWith<$Res> get proposedTaxBreakdown {
    return $TaxBreakdownCopyWith<$Res>(_value.proposedTaxBreakdown, (value) {
      return _then(_value.copyWith(proposedTaxBreakdown: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DraftApprovalImplCopyWith<$Res>
    implements $DraftApprovalCopyWith<$Res> {
  factory _$$DraftApprovalImplCopyWith(
    _$DraftApprovalImpl value,
    $Res Function(_$DraftApprovalImpl) then,
  ) = __$$DraftApprovalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'approval_id') String approvalId,
    @JsonKey(name: 'draft_invoice_id') String? draftInvoiceId,
    @JsonKey(name: 'shop_id') String shopId,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'proposed_items') List<CartItem> proposedItems,
    @JsonKey(name: 'proposed_tax_breakdown') TaxBreakdown proposedTaxBreakdown,
    @JsonKey(name: 'proposed_total') double proposedTotal,
    @JsonKey(name: 'approval_status') ApprovalStatus approvalStatus,
    @JsonKey(name: 'reviewed_by') String? reviewedBy,
    @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
    @JsonKey(name: 'approval_notes') String? approvalNotes,
    @JsonKey(name: 'sale_id') String? saleId,
    @JsonKey(name: 'gst_type') String? gstType,
    @JsonKey(name: 'discount_type') String? discountType,
    @JsonKey(name: 'discount_value') double? discountValue,
    @JsonKey(name: 'discount_amount') double? discountAmount,
    @JsonKey(name: 'subtotal_before_discount') double? subtotalBeforeDiscount,
    @JsonKey(name: 'subtotal_after_discount') double? subtotalAfterDiscount,
    @JsonKey(name: 'payment_status') String paymentStatus,
    @JsonKey(name: 'amount_paid') double amountPaid,
    @JsonKey(name: 'due_amount') double dueAmount,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_state') String? customerState,
  });

  @override
  $TaxBreakdownCopyWith<$Res> get proposedTaxBreakdown;
}

/// @nodoc
class __$$DraftApprovalImplCopyWithImpl<$Res>
    extends _$DraftApprovalCopyWithImpl<$Res, _$DraftApprovalImpl>
    implements _$$DraftApprovalImplCopyWith<$Res> {
  __$$DraftApprovalImplCopyWithImpl(
    _$DraftApprovalImpl _value,
    $Res Function(_$DraftApprovalImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DraftApproval
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? approvalId = null,
    Object? draftInvoiceId = freezed,
    Object? shopId = null,
    Object? customerId = freezed,
    Object? createdAt = null,
    Object? proposedItems = null,
    Object? proposedTaxBreakdown = null,
    Object? proposedTotal = null,
    Object? approvalStatus = null,
    Object? reviewedBy = freezed,
    Object? reviewedAt = freezed,
    Object? approvalNotes = freezed,
    Object? saleId = freezed,
    Object? gstType = freezed,
    Object? discountType = freezed,
    Object? discountValue = freezed,
    Object? discountAmount = freezed,
    Object? subtotalBeforeDiscount = freezed,
    Object? subtotalAfterDiscount = freezed,
    Object? paymentStatus = null,
    Object? amountPaid = null,
    Object? dueAmount = null,
    Object? customerName = freezed,
    Object? customerState = freezed,
  }) {
    return _then(
      _$DraftApprovalImpl(
        approvalId: null == approvalId
            ? _value.approvalId
            : approvalId // ignore: cast_nullable_to_non_nullable
                  as String,
        draftInvoiceId: freezed == draftInvoiceId
            ? _value.draftInvoiceId
            : draftInvoiceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        shopId: null == shopId
            ? _value.shopId
            : shopId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: freezed == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        proposedItems: null == proposedItems
            ? _value._proposedItems
            : proposedItems // ignore: cast_nullable_to_non_nullable
                  as List<CartItem>,
        proposedTaxBreakdown: null == proposedTaxBreakdown
            ? _value.proposedTaxBreakdown
            : proposedTaxBreakdown // ignore: cast_nullable_to_non_nullable
                  as TaxBreakdown,
        proposedTotal: null == proposedTotal
            ? _value.proposedTotal
            : proposedTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        approvalStatus: null == approvalStatus
            ? _value.approvalStatus
            : approvalStatus // ignore: cast_nullable_to_non_nullable
                  as ApprovalStatus,
        reviewedBy: freezed == reviewedBy
            ? _value.reviewedBy
            : reviewedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        approvalNotes: freezed == approvalNotes
            ? _value.approvalNotes
            : approvalNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        saleId: freezed == saleId
            ? _value.saleId
            : saleId // ignore: cast_nullable_to_non_nullable
                  as String?,
        gstType: freezed == gstType
            ? _value.gstType
            : gstType // ignore: cast_nullable_to_non_nullable
                  as String?,
        discountType: freezed == discountType
            ? _value.discountType
            : discountType // ignore: cast_nullable_to_non_nullable
                  as String?,
        discountValue: freezed == discountValue
            ? _value.discountValue
            : discountValue // ignore: cast_nullable_to_non_nullable
                  as double?,
        discountAmount: freezed == discountAmount
            ? _value.discountAmount
            : discountAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        subtotalBeforeDiscount: freezed == subtotalBeforeDiscount
            ? _value.subtotalBeforeDiscount
            : subtotalBeforeDiscount // ignore: cast_nullable_to_non_nullable
                  as double?,
        subtotalAfterDiscount: freezed == subtotalAfterDiscount
            ? _value.subtotalAfterDiscount
            : subtotalAfterDiscount // ignore: cast_nullable_to_non_nullable
                  as double?,
        paymentStatus: null == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        amountPaid: null == amountPaid
            ? _value.amountPaid
            : amountPaid // ignore: cast_nullable_to_non_nullable
                  as double,
        dueAmount: null == dueAmount
            ? _value.dueAmount
            : dueAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        customerName: freezed == customerName
            ? _value.customerName
            : customerName // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerState: freezed == customerState
            ? _value.customerState
            : customerState // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DraftApprovalImpl implements _DraftApproval {
  const _$DraftApprovalImpl({
    @JsonKey(name: 'approval_id') required this.approvalId,
    @JsonKey(name: 'draft_invoice_id') this.draftInvoiceId,
    @JsonKey(name: 'shop_id') required this.shopId,
    @JsonKey(name: 'customer_id') this.customerId,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'proposed_items')
    required final List<CartItem> proposedItems,
    @JsonKey(name: 'proposed_tax_breakdown') required this.proposedTaxBreakdown,
    @JsonKey(name: 'proposed_total') required this.proposedTotal,
    @JsonKey(name: 'approval_status')
    this.approvalStatus = ApprovalStatus.pending,
    @JsonKey(name: 'reviewed_by') this.reviewedBy,
    @JsonKey(name: 'reviewed_at') this.reviewedAt,
    @JsonKey(name: 'approval_notes') this.approvalNotes,
    @JsonKey(name: 'sale_id') this.saleId,
    @JsonKey(name: 'gst_type') this.gstType,
    @JsonKey(name: 'discount_type') this.discountType,
    @JsonKey(name: 'discount_value') this.discountValue,
    @JsonKey(name: 'discount_amount') this.discountAmount,
    @JsonKey(name: 'subtotal_before_discount') this.subtotalBeforeDiscount,
    @JsonKey(name: 'subtotal_after_discount') this.subtotalAfterDiscount,
    @JsonKey(name: 'payment_status') this.paymentStatus = 'UNPAID',
    @JsonKey(name: 'amount_paid') this.amountPaid = 0.0,
    @JsonKey(name: 'due_amount') this.dueAmount = 0.0,
    @JsonKey(name: 'customer_name') this.customerName,
    @JsonKey(name: 'customer_state') this.customerState,
  }) : _proposedItems = proposedItems;

  factory _$DraftApprovalImpl.fromJson(Map<String, dynamic> json) =>
      _$$DraftApprovalImplFromJson(json);

  @override
  @JsonKey(name: 'approval_id')
  final String approvalId;
  @override
  @JsonKey(name: 'draft_invoice_id')
  final String? draftInvoiceId;
  @override
  @JsonKey(name: 'shop_id')
  final String shopId;
  @override
  @JsonKey(name: 'customer_id')
  final String? customerId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<CartItem> _proposedItems;
  @override
  @JsonKey(name: 'proposed_items')
  List<CartItem> get proposedItems {
    if (_proposedItems is EqualUnmodifiableListView) return _proposedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_proposedItems);
  }

  @override
  @JsonKey(name: 'proposed_tax_breakdown')
  final TaxBreakdown proposedTaxBreakdown;
  @override
  @JsonKey(name: 'proposed_total')
  final double proposedTotal;
  @override
  @JsonKey(name: 'approval_status')
  final ApprovalStatus approvalStatus;
  @override
  @JsonKey(name: 'reviewed_by')
  final String? reviewedBy;
  @override
  @JsonKey(name: 'reviewed_at')
  final DateTime? reviewedAt;
  @override
  @JsonKey(name: 'approval_notes')
  final String? approvalNotes;
  @override
  @JsonKey(name: 'sale_id')
  final String? saleId;
  @override
  @JsonKey(name: 'gst_type')
  final String? gstType;
  @override
  @JsonKey(name: 'discount_type')
  final String? discountType;
  @override
  @JsonKey(name: 'discount_value')
  final double? discountValue;
  @override
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @override
  @JsonKey(name: 'subtotal_before_discount')
  final double? subtotalBeforeDiscount;
  @override
  @JsonKey(name: 'subtotal_after_discount')
  final double? subtotalAfterDiscount;
  @override
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @override
  @JsonKey(name: 'amount_paid')
  final double amountPaid;
  @override
  @JsonKey(name: 'due_amount')
  final double dueAmount;
  @override
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @override
  @JsonKey(name: 'customer_state')
  final String? customerState;

  @override
  String toString() {
    return 'DraftApproval(approvalId: $approvalId, draftInvoiceId: $draftInvoiceId, shopId: $shopId, customerId: $customerId, createdAt: $createdAt, proposedItems: $proposedItems, proposedTaxBreakdown: $proposedTaxBreakdown, proposedTotal: $proposedTotal, approvalStatus: $approvalStatus, reviewedBy: $reviewedBy, reviewedAt: $reviewedAt, approvalNotes: $approvalNotes, saleId: $saleId, gstType: $gstType, discountType: $discountType, discountValue: $discountValue, discountAmount: $discountAmount, subtotalBeforeDiscount: $subtotalBeforeDiscount, subtotalAfterDiscount: $subtotalAfterDiscount, paymentStatus: $paymentStatus, amountPaid: $amountPaid, dueAmount: $dueAmount, customerName: $customerName, customerState: $customerState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DraftApprovalImpl &&
            (identical(other.approvalId, approvalId) ||
                other.approvalId == approvalId) &&
            (identical(other.draftInvoiceId, draftInvoiceId) ||
                other.draftInvoiceId == draftInvoiceId) &&
            (identical(other.shopId, shopId) || other.shopId == shopId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
              other._proposedItems,
              _proposedItems,
            ) &&
            (identical(other.proposedTaxBreakdown, proposedTaxBreakdown) ||
                other.proposedTaxBreakdown == proposedTaxBreakdown) &&
            (identical(other.proposedTotal, proposedTotal) ||
                other.proposedTotal == proposedTotal) &&
            (identical(other.approvalStatus, approvalStatus) ||
                other.approvalStatus == approvalStatus) &&
            (identical(other.reviewedBy, reviewedBy) ||
                other.reviewedBy == reviewedBy) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.approvalNotes, approvalNotes) ||
                other.approvalNotes == approvalNotes) &&
            (identical(other.saleId, saleId) || other.saleId == saleId) &&
            (identical(other.gstType, gstType) || other.gstType == gstType) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.discountValue, discountValue) ||
                other.discountValue == discountValue) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.subtotalBeforeDiscount, subtotalBeforeDiscount) ||
                other.subtotalBeforeDiscount == subtotalBeforeDiscount) &&
            (identical(other.subtotalAfterDiscount, subtotalAfterDiscount) ||
                other.subtotalAfterDiscount == subtotalAfterDiscount) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.amountPaid, amountPaid) ||
                other.amountPaid == amountPaid) &&
            (identical(other.dueAmount, dueAmount) ||
                other.dueAmount == dueAmount) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerState, customerState) ||
                other.customerState == customerState));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    approvalId,
    draftInvoiceId,
    shopId,
    customerId,
    createdAt,
    const DeepCollectionEquality().hash(_proposedItems),
    proposedTaxBreakdown,
    proposedTotal,
    approvalStatus,
    reviewedBy,
    reviewedAt,
    approvalNotes,
    saleId,
    gstType,
    discountType,
    discountValue,
    discountAmount,
    subtotalBeforeDiscount,
    subtotalAfterDiscount,
    paymentStatus,
    amountPaid,
    dueAmount,
    customerName,
    customerState,
  ]);

  /// Create a copy of DraftApproval
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DraftApprovalImplCopyWith<_$DraftApprovalImpl> get copyWith =>
      __$$DraftApprovalImplCopyWithImpl<_$DraftApprovalImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DraftApprovalImplToJson(this);
  }
}

abstract class _DraftApproval implements DraftApproval {
  const factory _DraftApproval({
    @JsonKey(name: 'approval_id') required final String approvalId,
    @JsonKey(name: 'draft_invoice_id') final String? draftInvoiceId,
    @JsonKey(name: 'shop_id') required final String shopId,
    @JsonKey(name: 'customer_id') final String? customerId,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'proposed_items')
    required final List<CartItem> proposedItems,
    @JsonKey(name: 'proposed_tax_breakdown')
    required final TaxBreakdown proposedTaxBreakdown,
    @JsonKey(name: 'proposed_total') required final double proposedTotal,
    @JsonKey(name: 'approval_status') final ApprovalStatus approvalStatus,
    @JsonKey(name: 'reviewed_by') final String? reviewedBy,
    @JsonKey(name: 'reviewed_at') final DateTime? reviewedAt,
    @JsonKey(name: 'approval_notes') final String? approvalNotes,
    @JsonKey(name: 'sale_id') final String? saleId,
    @JsonKey(name: 'gst_type') final String? gstType,
    @JsonKey(name: 'discount_type') final String? discountType,
    @JsonKey(name: 'discount_value') final double? discountValue,
    @JsonKey(name: 'discount_amount') final double? discountAmount,
    @JsonKey(name: 'subtotal_before_discount')
    final double? subtotalBeforeDiscount,
    @JsonKey(name: 'subtotal_after_discount')
    final double? subtotalAfterDiscount,
    @JsonKey(name: 'payment_status') final String paymentStatus,
    @JsonKey(name: 'amount_paid') final double amountPaid,
    @JsonKey(name: 'due_amount') final double dueAmount,
    @JsonKey(name: 'customer_name') final String? customerName,
    @JsonKey(name: 'customer_state') final String? customerState,
  }) = _$DraftApprovalImpl;

  factory _DraftApproval.fromJson(Map<String, dynamic> json) =
      _$DraftApprovalImpl.fromJson;

  @override
  @JsonKey(name: 'approval_id')
  String get approvalId;
  @override
  @JsonKey(name: 'draft_invoice_id')
  String? get draftInvoiceId;
  @override
  @JsonKey(name: 'shop_id')
  String get shopId;
  @override
  @JsonKey(name: 'customer_id')
  String? get customerId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'proposed_items')
  List<CartItem> get proposedItems;
  @override
  @JsonKey(name: 'proposed_tax_breakdown')
  TaxBreakdown get proposedTaxBreakdown;
  @override
  @JsonKey(name: 'proposed_total')
  double get proposedTotal;
  @override
  @JsonKey(name: 'approval_status')
  ApprovalStatus get approvalStatus;
  @override
  @JsonKey(name: 'reviewed_by')
  String? get reviewedBy;
  @override
  @JsonKey(name: 'reviewed_at')
  DateTime? get reviewedAt;
  @override
  @JsonKey(name: 'approval_notes')
  String? get approvalNotes;
  @override
  @JsonKey(name: 'sale_id')
  String? get saleId;
  @override
  @JsonKey(name: 'gst_type')
  String? get gstType;
  @override
  @JsonKey(name: 'discount_type')
  String? get discountType;
  @override
  @JsonKey(name: 'discount_value')
  double? get discountValue;
  @override
  @JsonKey(name: 'discount_amount')
  double? get discountAmount;
  @override
  @JsonKey(name: 'subtotal_before_discount')
  double? get subtotalBeforeDiscount;
  @override
  @JsonKey(name: 'subtotal_after_discount')
  double? get subtotalAfterDiscount;
  @override
  @JsonKey(name: 'payment_status')
  String get paymentStatus;
  @override
  @JsonKey(name: 'amount_paid')
  double get amountPaid;
  @override
  @JsonKey(name: 'due_amount')
  double get dueAmount;
  @override
  @JsonKey(name: 'customer_name')
  String? get customerName;
  @override
  @JsonKey(name: 'customer_state')
  String? get customerState;

  /// Create a copy of DraftApproval
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DraftApprovalImplCopyWith<_$DraftApprovalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
