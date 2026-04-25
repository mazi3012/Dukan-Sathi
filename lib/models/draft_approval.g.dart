// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_approval.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DraftApproval _$DraftApprovalFromJson(
  Map<String, dynamic> json,
) => _DraftApproval(
  approvalId: json['approval_id'] as String,
  draftInvoiceId: json['draft_invoice_id'] as String?,
  shopId: json['shop_id'] as String,
  customerId: json['customer_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  proposedItems: (json['proposed_items'] as List<dynamic>)
      .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  proposedTaxBreakdown: TaxBreakdown.fromJson(
    json['proposed_tax_breakdown'] as Map<String, dynamic>,
  ),
  proposedTotal: (json['proposed_total'] as num).toDouble(),
  approvalStatus:
      $enumDecodeNullable(_$ApprovalStatusEnumMap, json['approval_status']) ??
      ApprovalStatus.pending,
  reviewedBy: json['reviewed_by'] as String?,
  reviewedAt: json['reviewed_at'] == null
      ? null
      : DateTime.parse(json['reviewed_at'] as String),
  approvalNotes: json['approval_notes'] as String?,
  saleId: json['sale_id'] as String?,
  gstType: json['gst_type'] as String?,
  discountType: json['discount_type'] as String?,
  discountValue: (json['discount_value'] as num?)?.toDouble(),
  discountAmount: (json['discount_amount'] as num?)?.toDouble(),
  subtotalBeforeDiscount: (json['subtotal_before_discount'] as num?)
      ?.toDouble(),
  subtotalAfterDiscount: (json['subtotal_after_discount'] as num?)?.toDouble(),
  paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
  amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
  dueAmount: (json['due_amount'] as num?)?.toDouble() ?? 0.0,
  customerName: json['customer_name'] as String?,
  customerState: json['customer_state'] as String?,
);

Map<String, dynamic> _$DraftApprovalToJson(_DraftApproval instance) =>
    <String, dynamic>{
      'approval_id': instance.approvalId,
      'draft_invoice_id': instance.draftInvoiceId,
      'shop_id': instance.shopId,
      'customer_id': instance.customerId,
      'created_at': instance.createdAt.toIso8601String(),
      'proposed_items': instance.proposedItems,
      'proposed_tax_breakdown': instance.proposedTaxBreakdown,
      'proposed_total': instance.proposedTotal,
      'approval_status': _$ApprovalStatusEnumMap[instance.approvalStatus]!,
      'reviewed_by': instance.reviewedBy,
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
      'approval_notes': instance.approvalNotes,
      'sale_id': instance.saleId,
      'gst_type': instance.gstType,
      'discount_type': instance.discountType,
      'discount_value': instance.discountValue,
      'discount_amount': instance.discountAmount,
      'subtotal_before_discount': instance.subtotalBeforeDiscount,
      'subtotal_after_discount': instance.subtotalAfterDiscount,
      'payment_status': instance.paymentStatus,
      'amount_paid': instance.amountPaid,
      'due_amount': instance.dueAmount,
      'customer_name': instance.customerName,
      'customer_state': instance.customerState,
    };

const _$ApprovalStatusEnumMap = {
  ApprovalStatus.pending: 'PENDING',
  ApprovalStatus.approved: 'APPROVED',
  ApprovalStatus.rejected: 'REJECTED',
  ApprovalStatus.modified: 'MODIFIED',
};
