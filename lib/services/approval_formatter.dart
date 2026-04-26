import '../models/draft_approval.dart';
import '../models/tax_breakdown.dart';

class ApprovalFormatter {
  static String _formatPrice(double v) => v.toStringAsFixed(2);

  static double _roundToTwoDecimals(double value) =>
      (value * 100).round() / 100;

  static String _formatDiscountLine({
    String? discountType,
    double? discountValue,
    double? discountAmount,
  }) {
    if (discountType == null && discountAmount == null && discountValue == null) {
      return '';
    }

    // Handle case where only discountAmount is provided (fixed amount)
    if (discountType == null && discountAmount != null) {
      return 'Discount:      -₹${_formatPrice(discountAmount)}';
    }

    // Handle percentage discount: show as "Discount: -₹[Amount] ([Percentage]%)"
    if (discountType == 'PERCENT') {
      final percentStr = discountValue?.toStringAsFixed(1) ?? '0.0';
      final amountStr = discountAmount != null ? _formatPrice(discountAmount) : '0.00';
      return 'Discount:      -₹$amountStr ($percentStr%)';
    }

    // Handle fixed amount discount
    if (discountType == 'AMOUNT') {
      final amountStr = discountAmount != null ? _formatPrice(discountAmount) : _formatPrice(discountValue ?? 0);
      return 'Discount:      -₹$amountStr';
    }

    return '';
  }

  /// Format a rate value for display — drop decimals if whole number
  static String _formatRate(double rate) {
    return rate == rate.roundToDouble() ? rate.toInt().toString() : rate.toStringAsFixed(1);
  }

  /// Main formatted invoice for Telegram - GST-compliant format
  /// Follows hierarchy: Items Total → Discount → Taxable Value → Taxes → Grand Total → Paid → Due
  static String formatApprovalMessage({
    required DraftApproval approval,
    required String customerName,
    required List<String> itemDescriptions,
    String gstType = 'CGST_SGST', // 'CGST_SGST' or 'IGST'
    String? paymentStatus,
    double? amountPaid,
    double? dueAmount,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    double? subtotalBeforeDiscount,
    double? subtotalAfterDiscount,
  }) {
    final tax = approval.proposedTaxBreakdown;
    final isUnregistered = tax.gstMode == 'UNREGISTERED';
    final isComposite = tax.gstMode == 'COMPOSITE';
    final isIGST = tax.igstAmount > 0;

    final itemsText = itemDescriptions.isNotEmpty
        ? itemDescriptions.map((i) => '  • $i').join('\n')
        : '  No items';

    // Calculate itemsTotal first (gross total before discount)
    final itemsTotal = subtotalBeforeDiscount ?? tax.subtotal;
    final discountAmt = discountAmount ?? 0.0;
    // Taxable value = items total - discount
    final taxableValue = subtotalAfterDiscount ?? (itemsTotal - discountAmt);

    final StringBuffer billingSummary = StringBuffer();

    // 1. ITEMS TOTAL (gross, before any discount)
    billingSummary.writeln('Items Total:   ₹${_formatPrice(itemsTotal)}');

    // 2. DISCOUNT LINE (with proper format: -₹XXX (YY%))
    if (discountAmt > 0 || discountType != null) {
      final discountLine = _formatDiscountLine(
        discountType: discountType,
        discountValue: discountValue,
        discountAmount: discountAmount,
      );
      if (discountLine.isNotEmpty) {
        billingSummary.writeln(discountLine);
      }
    }

    // 3. TAXABLE VALUE (after discount)
    billingSummary.writeln('Taxable Value: ₹${_formatPrice(taxableValue)}');
    billingSummary.writeln('');

    // 4. TAX LINES — show per-rate breakdown if available
    if (isUnregistered) {
      billingSummary.writeln('GST:           None (Unregistered)');
    } else if (isComposite) {
      final taxAmt = approval.proposedTotal - taxableValue;
      billingSummary.writeln('Composite GST (3%): ₹${_formatPrice(taxAmt)}');
    } else if (tax.rateWiseSummary.isNotEmpty) {
      // Per-rate breakdown — GST-compliant multi-rate display
      for (final entry in tax.rateWiseSummary) {
        final rate = (entry['rate'] as num).toDouble();
        if (rate <= 0) continue; // Skip exempt items in tax section
        final rateStr = _formatRate(rate);
        if (isIGST) {
          final igst = (entry['igst'] as num).toDouble();
          billingSummary.writeln('IGST ($rateStr%):   ₹${_formatPrice(igst)}');
        } else {
          final halfRate = _formatRate(rate / 2);
          final cgst = (entry['cgst'] as num).toDouble();
          final sgst = (entry['sgst'] as num).toDouble();
          billingSummary.writeln('CGST ($halfRate%):   ₹${_formatPrice(cgst)}');
          billingSummary.writeln('SGST ($halfRate%):   ₹${_formatPrice(sgst)}');
        }
      }
    } else {
      // Fallback for old data without rateWiseSummary
      if (isIGST) {
        billingSummary.writeln('IGST (18%):    ₹${_formatPrice(tax.igstAmount)}');
      } else {
        billingSummary.writeln('CGST (9%):     ₹${_formatPrice(tax.cgstAmount)}');
        billingSummary.writeln('SGST (9%):     ₹${_formatPrice(tax.sgstAmount)}');
      }
    }

    // 5. GRAND TOTAL (must appear before payment info)
    billingSummary.writeln('');
    billingSummary.writeln('TOTAL:         ₹${_formatPrice(approval.proposedTotal)}');

    // 6. PAYMENT STATUS & AMOUNT
    final grandTotal = approval.proposedTotal;
    final finalAmountPaid = amountPaid ?? 0.0;
    final finalDueAmount = dueAmount ?? _roundToTwoDecimals(grandTotal - finalAmountPaid);

    billingSummary.writeln('');
    if (finalAmountPaid > 0) {
      billingSummary.writeln('Paid:          ₹${_formatPrice(finalAmountPaid)}');
    }

    // 7. BALANCE DUE (final line in billing summary)
    billingSummary.writeln('DUE:           ₹${_formatPrice(finalDueAmount)}');

    final stateLabel = isIGST ? 'Inter-State (IGST)' : '${tax.applicableState} — Intra-State';
    final statusLabel = paymentStatus ?? 'UNPAID';

    return '''👤 Customer: $customerName

📦 Items:
$itemsText

💰 Billing Summary:
────────────────────
${billingSummary.toString().trim()}
────────────────────

📍 State: $stateLabel
💳 Status: $statusLabel
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
