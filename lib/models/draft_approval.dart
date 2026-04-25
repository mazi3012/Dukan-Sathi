import 'package:freezed_annotation/freezed_annotation.dart';

import 'cart_item.dart';
import 'tax_breakdown.dart';

part 'draft_approval.freezed.dart';
part 'draft_approval.g.dart';

enum ApprovalStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('MODIFIED')
  modified,
}

@freezed
abstract class DraftApproval with _$DraftApproval {
  const factory DraftApproval({
    @JsonKey(name: 'approval_id') required String approvalId,
    @JsonKey(name: 'draft_invoice_id') String? draftInvoiceId,
    @JsonKey(name: 'shop_id') required String shopId,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'proposed_items') required List<CartItem> proposedItems,
    @JsonKey(name: 'proposed_tax_breakdown')
        required TaxBreakdown proposedTaxBreakdown,
    @JsonKey(name: 'proposed_total') required double proposedTotal,
    @JsonKey(name: 'approval_status')
        @Default(ApprovalStatus.pending)
        ApprovalStatus approvalStatus,
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
    @JsonKey(name: 'payment_status') @Default('UNPAID') String paymentStatus,
    @JsonKey(name: 'amount_paid') @Default(0.0) double amountPaid,
    @JsonKey(name: 'due_amount') @Default(0.0) double dueAmount,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_state') String? customerState,
  }) = _DraftApproval;

  factory DraftApproval.fromJson(Map<String, dynamic> json) =>
      _$DraftApprovalFromJson(json);
}
