import 'package:dukansathi_new/models/tax_breakdown.dart';
import 'package:dukansathi_new/services/invoice_pdf_generator.dart';
import 'package:test/test.dart';

void main() {
  group('InvoicePdfGenerator.resolveTemplate', () {
    test('selects IGST for inter-state tax', () {
      final breakdown = TaxBreakdown(
        subtotal: 100.0,
        cgstAmount: 0.0,
        sgstAmount: 0.0,
        igstAmount: 18.0,
        gstMode: 'REGISTERED',
        applicableState: 'DL',
        taxSlab: '18%',
        totalAmount: 118.0,
        breakdown: const [],
      );

      expect(InvoicePdfGenerator.resolveTemplate(breakdown), InvoicePdfTemplate.igst);
    });

    test('selects CGST/SGST for intra-state tax', () {
      final breakdown = TaxBreakdown(
        subtotal: 100.0,
        cgstAmount: 9.0,
        sgstAmount: 9.0,
        igstAmount: 0.0,
        gstMode: 'REGISTERED',
        applicableState: 'MH',
        taxSlab: '18%',
        totalAmount: 118.0,
        breakdown: const [],
      );

      expect(InvoicePdfGenerator.resolveTemplate(breakdown), InvoicePdfTemplate.cgstSgst);
    });

    test('selects non-GST for unregistered sales', () {
      final breakdown = TaxBreakdown(
        subtotal: 100.0,
        cgstAmount: 0.0,
        sgstAmount: 0.0,
        igstAmount: 0.0,
        gstMode: 'UNREGISTERED',
        applicableState: 'MH',
        taxSlab: '0%',
        totalAmount: 100.0,
        breakdown: const [],
      );

      expect(InvoicePdfGenerator.resolveTemplate(breakdown), InvoicePdfTemplate.nonGst);
    });
  });
}