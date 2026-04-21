import '../models/draft_approval.dart';
import '../models/tax_breakdown.dart';

class ApprovalFormatter {
  /// Format approval message for Telegram (with tax breakdown)
  static String formatApprovalMessage({
    required DraftApproval approval,
    required String customerName,
    required List<String> itemDescriptions,
  }) {
    final taxBreakdown = approval.proposedTaxBreakdown;
    final state = taxBreakdown.applicableState;

    // Format items
    final itemsText = itemDescriptions.isNotEmpty
        ? itemDescriptions.join('\n  ')
        : 'No items';

    // Format tax breakdown based on GST mode
    String taxBreakdownText;

    if (taxBreakdown.gstMode == 'REGISTERED') {
      if (taxBreakdown.igstAmount > 0) {
        // Inter-state (IGST)
        taxBreakdownText = '''
Subtotal: ₹${approval.proposedTaxBreakdown.subtotal.toStringAsFixed(2)}
Tax ($state, Inter-State):
  IGST (18%): ₹${taxBreakdown.igstAmount.toStringAsFixed(2)}
  ✅ TOTAL: ₹${approval.proposedTotal.toStringAsFixed(2)}''';
      } else {
        // Intra-state (CGST + SGST)
        taxBreakdownText = '''
Subtotal: ₹${approval.proposedTaxBreakdown.subtotal.toStringAsFixed(2)}
Tax ($state, Registered):
  CGST (9%): ₹${taxBreakdown.cgstAmount.toStringAsFixed(2)}
  SGST (9%): ₹${taxBreakdown.sgstAmount.toStringAsFixed(2)}
  ✅ TOTAL: ₹${approval.proposedTotal.toStringAsFixed(2)}''';
      }
    } else if (taxBreakdown.gstMode == 'UNREGISTERED') {
      taxBreakdownText = '''
Subtotal: ₹${approval.proposedTaxBreakdown.subtotal.toStringAsFixed(2)}
(No GST - Unregistered)
  ✅ TOTAL: ₹${approval.proposedTotal.toStringAsFixed(2)}''';
    } else if (taxBreakdown.gstMode == 'COMPOSITE') {
      taxBreakdownText = '''
Subtotal: ₹${approval.proposedTaxBreakdown.subtotal.toStringAsFixed(2)}
Composite GST (3%): ₹${(approval.proposedTotal - approval.proposedTaxBreakdown.subtotal).toStringAsFixed(2)}
  ✅ TOTAL: ₹${approval.proposedTotal.toStringAsFixed(2)}''';
    } else {
      taxBreakdownText = '''
Subtotal: ₹${approval.proposedTaxBreakdown.subtotal.toStringAsFixed(2)}
Tax: ₹${(approval.proposedTotal - approval.proposedTaxBreakdown.subtotal).toStringAsFixed(2)}
  ✅ TOTAL: ₹${approval.proposedTotal.toStringAsFixed(2)}''';
    }

    return '''📋 **INVOICE FOR APPROVAL**

👤 Customer: $customerName
📦 Items:
  $itemsText

$taxBreakdownText

⏳ Status: Awaiting Your Approval
ID: `${{approval.approvalId}}`''';
  }

  /// Format compact approval message for quick actions
  static String formatCompactApprovalMessage({
    required String customerName,
    required double subtotal,
    required double total,
    required String taxDescription,
    required String approvalId,
  }) {
    final taxAmount = total - subtotal;

    return '''🧾 Draft Invoice Ready

👤 $customerName
💰 Subtotal: ₹${subtotal.toStringAsFixed(2)}
📊 $taxDescription
✅ **TOTAL: ₹${total.toStringAsFixed(2)}**

Awaiting approval...''';
  }

  /// Format approval confirmation message
  static String formatApprovalConfirmation({
    required String approvalId,
    required String saleId,
    required double totalAmount,
  }) {
    return '''✅ **INVOICE FINALIZED**

✓ Approval ID: `$approvalId`
✓ Sale ID: `$saleId`
✓ Amount: ₹${totalAmount.toStringAsFixed(2)}

The invoice has been saved to your records.''';
  }

  /// Format rejection message
  static String formatRejectionMessage({
    required String approvalId,
    required String rejectionReason,
  }) {
    return '''❌ **INVOICE REJECTED**

Approval ID: `$approvalId`
Reason: $rejectionReason

The draft has been discarded. A new invoice can be created.''';
  }

  /// Format error message
  static String formatErrorMessage(String error) {
    return '''⚠️ **ERROR**

$error

Please try again or contact support.''';
  }

  /// Format pending approvals list
  static String formatPendingApprovalsList(
      List<Map<String, dynamic>> approvals) {
    if (approvals.isEmpty) {
      return '✅ No pending approvals!';
    }

    final buffer = StringBuffer('📋 **PENDING APPROVALS** (${approvals.length})\n\n');

    for (int i = 0; i < approvals.length && i < 5; i++) {
      final approval = approvals[i];
      final id = approval['approval_id'] as String;
      final total = approval['proposed_total'] as num;
      final createdAt = approval['created_at'] as String;

      buffer.writeln('${i + 1}. ₹${total.toStringAsFixed(2)} - ID: `${id.substring(0, 8)}`');
      buffer.writeln('   Created: $createdAt\n');
    }

    if (approvals.length > 5) {
      buffer.writeln('... and ${approvals.length - 5} more');
    }

    return buffer.toString();
  }

  /// Extract summary for AI response
  static String extractTaxSummary(TaxBreakdown breakdown) {
    if (breakdown.gstMode == 'UNREGISTERED') {
      return '₹${breakdown.totalAmount.toStringAsFixed(2)} (No tax)';
    } else if (breakdown.igstAmount > 0) {
      return 'Subtotal: ₹${breakdown.subtotal.toStringAsFixed(2)}, IGST (18%): ₹${breakdown.igstAmount.toStringAsFixed(2)}, Total: ₹${breakdown.totalAmount.toStringAsFixed(2)}';
    } else if (breakdown.cgstAmount > 0) {
      return 'Subtotal: ₹${breakdown.subtotal.toStringAsFixed(2)}, CGST+SGST (18%): ₹${(breakdown.cgstAmount + breakdown.sgstAmount).toStringAsFixed(2)}, Total: ₹${breakdown.totalAmount.toStringAsFixed(2)}';
    } else {
      return '₹${breakdown.totalAmount.toStringAsFixed(2)}';
    }
  }
}
