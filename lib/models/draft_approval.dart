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
  }) = _DraftApproval;

  factory DraftApproval.fromJson(Map<String, dynamic> json) =>
      _$DraftApprovalFromJson(json);
}
