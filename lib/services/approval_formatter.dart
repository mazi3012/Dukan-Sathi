import '../models/draft_approval.dart';
import '../models/tax_breakdown.dart';

class ApprovalFormatter {
  static String _formatPrice(double v) => v.toStringAsFixed(2);

  /// Main formatted invoice for Telegram
  static String formatApprovalMessage({
    required DraftApproval approval,
    required String customerName,
    required List<String> itemDescriptions,
    String gstType = 'CGST_SGST', // 'CGST_SGST' or 'IGST'
  }) {
    final tax = approval.proposedTaxBreakdown;
    final isUnregistered = tax.gstMode == 'UNREGISTERED';
    final isComposite = tax.gstMode == 'COMPOSITE';
    final isIGST = tax.igstAmount > 0;

    final itemsText = itemDescriptions.isNotEmpty
        ? itemDescriptions.map((i) => '  • $i').join('\n')
        : '  No items';

    final StringBuffer taxLines = StringBuffer();
    taxLines.writeln('Subtotal: ₹${_formatPrice(tax.subtotal)}');

    if (isUnregistered) {
      taxLines.writeln('GST: None (Unregistered Seller)');
    } else if (isComposite) {
      final taxAmt = approval.proposedTotal - tax.subtotal;
      taxLines.writeln('Composite GST (3%): ₹${_formatPrice(taxAmt)}');
    } else if (isIGST) {
      taxLines.writeln('IGST (18% — Inter-State): ₹${_formatPrice(tax.igstAmount)}');
    } else {
      taxLines.writeln('CGST (9%): ₹${_formatPrice(tax.cgstAmount)}');
      taxLines.writeln('SGST (9%): ₹${_formatPrice(tax.sgstAmount)}');
    }

    final stateLabel = isIGST ? 'Inter-State (IGST)' : '${tax.applicableState} — Intra-State';

    return '''🧾 *INVOICE FOR APPROVAL*

👤 Customer: $customerName
📦 Items:
$itemsText

💰 *Billing Summary*
━━━━━━━━━━━━━━━━━
${taxLines.toString().trim()}
━━━━━━━━━━━━━━━━━
*TOTAL: ₹${_formatPrice(approval.proposedTotal)}*

📍 State: $stateLabel
⏳ Status: Awaiting Approval
🆔 `${approval.approvalId}`''';
  }

  /// Format approval confirmation message
  static String formatApprovalConfirmation({
    required String saleId,
    required double totalAmount,
  }) {
    return '✅ *Invoice Approved & Finalized!*\n\n🧾 Sale ID: `$saleId`\n💰 Amount: ₹${_formatPrice(totalAmount)}\n\n_Invoice saved to records._';
  }

  /// Format rejection message
  static String formatRejectionMessage({
    required String approvalId,
    required String rejectionReason,
  }) {
    return '❌ *Invoice Rejected*\n\nReason: $rejectionReason\n\n_Draft discarded. Create a new invoice anytime._';
  }

  /// Extract summary for AI response
  static String extractTaxSummary(TaxBreakdown breakdown) {
    if (breakdown.gstMode == 'UNREGISTERED') {
      return '₹${_formatPrice(breakdown.totalAmount)} (No tax)';
    } else if (breakdown.igstAmount > 0) {
      return 'Subtotal ₹${_formatPrice(breakdown.subtotal)} + IGST ₹${_formatPrice(breakdown.igstAmount)} = ₹${_formatPrice(breakdown.totalAmount)}';
    } else if (breakdown.cgstAmount > 0) {
      return 'Subtotal ₹${_formatPrice(breakdown.subtotal)} + CGST+SGST ₹${_formatPrice(breakdown.cgstAmount + breakdown.sgstAmount)} = ₹${_formatPrice(breakdown.totalAmount)}';
    }
    return '₹${_formatPrice(breakdown.totalAmount)}';
  }
}
