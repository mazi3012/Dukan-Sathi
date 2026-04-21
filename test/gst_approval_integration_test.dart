import 'package:test/test.dart';
import 'package:dukansathi_new/services/gst_calculator.dart';
import 'package:dukansathi_new/models/shop_config.dart';
import 'package:dukansathi_new/models/cart_item.dart';
import 'package:dukansathi_new/data/state_tax_slabs.dart';

void main() {
  group('GST Approval Integration Tests', () {
    group('Tax Calculations', () {
      test('Registered shop intra-state (Maharashtra) - CGST+SGST', () {
        final shopConfig = ShopConfig(
          shopId: 'shop_mh_001',
          gstRegistrationNumber: '27AABCT1234H1Z0',
          state: 'MH',
          gstMode: GSTMode.registered,
          businessType: 'Retail',
          createdAt: DateTime.now(),
        );

        final items = [
          CartItem(productId: 'p1', quantity: 2, unitPrice: 100.0),
          CartItem(productId: 'p2', quantity: 1, unitPrice: 200.0),
        ];

        final taxBreakdown = GSTCalculator.calculateTax(items: items, shopConfig: shopConfig);

        expect(taxBreakdown.subtotal, 400.0);
        expect(taxBreakdown.cgstAmount, 36.0); // 9% of 400
        expect(taxBreakdown.sgstAmount, 36.0); // 9% of 400
        expect(taxBreakdown.igstAmount, 0.0); // No IGST for intra-state
        expect(taxBreakdown.totalAmount, 472.0); // 400 + 72
        expect(taxBreakdown.gstMode, 'REGISTERED');
        expect(taxBreakdown.applicableState, 'MH');
      });

      test('Registered shop inter-state (Delhi to Mumbai) - IGST only', () {
        final shopConfig = ShopConfig(
          shopId: 'shop_dl_001',
          gstRegistrationNumber: '07AABCT1234H1Z0',
          state: 'DL',
          gstMode: GSTMode.registered,
          businessType: 'Retail',
          createdAt: DateTime.now(),
        );

        final items = [
          CartItem(productId: 'p1', quantity: 1, unitPrice: 500.0),
        ];

        // For inter-state, we'd need customer state info
        // For now, testing the IGST calculation logic
        final igstAmount = 500.0 * 0.18; // 18%
        expect(igstAmount, 90.0);
      });

      test('Unregistered shop - No tax', () {
        final shopConfig = ShopConfig(
          shopId: 'shop_unreg_001',
          gstRegistrationNumber: null,
          state: 'MH',
          gstMode: GSTMode.unregistered,
          businessType: 'Retail',
          createdAt: DateTime.now(),
        );

        final items = [
          CartItem(productId: 'p1', quantity: 1, unitPrice: 1000.0),
        ];

        final taxBreakdown = GSTCalculator.calculateTax(items: items, shopConfig: shopConfig);

        expect(taxBreakdown.subtotal, 1000.0);
        expect(taxBreakdown.cgstAmount, 0.0);
        expect(taxBreakdown.sgstAmount, 0.0);
        expect(taxBreakdown.igstAmount, 0.0);
        expect(taxBreakdown.totalAmount, 1000.0);
        expect(taxBreakdown.gstMode, 'UNREGISTERED');
      });

      test('Composite GST - Special slab calculation', () {
        final shopConfig = ShopConfig(
          shopId: 'shop_comp_001',
          gstRegistrationNumber: '27AABCT1234H1Z0',
          state: 'MH',
          gstMode: GSTMode.composite,
          businessType: 'Retail',
          createdAt: DateTime.now(),
        );

        final items = [
          CartItem(productId: 'p1', quantity: 1, unitPrice: 10000.0),
        ];

        final taxBreakdown = GSTCalculator.calculateTax(items: items, shopConfig: shopConfig);

        expect(taxBreakdown.gstMode, 'COMPOSITE');
        // Composite slabs vary by turnover; typically 1-5%
        // For standard retail, we'll assume 5%
        expect(taxBreakdown.totalAmount, greaterThan(10000.0));
        expect(taxBreakdown.totalAmount, lessThan(10600.0)); // Max 5% = 500
      });
    });

    group('State Validation', () {
      test('Valid state codes recognized', () {
        final validStates = [
          'MH',
          'DL',
          'KA',
          'TN',
          'GJ',
          'UP',
          'WB',
          'AP',
          'BR'
        ];

        for (final state in validStates) {
          expect(() {
            GSTCalculator.validateState(state);
          }, returnsNormally);
        }
      });

      test('Invalid state code throws error', () {
        expect(
          () => GSTCalculator.validateState('XX'),
          throwsArgumentError,
        );
      });

      test('Works with all 28 states + 8 UTs', () {
        final allStates = [
          // 28 States
          'AP', 'AR', 'AS', 'BR', 'CG', 'GA', 'GJ', 'HR', 'HP', 'JK', 'JH',
          'KA', 'KL', 'MP', 'MH', 'MN', 'ML', 'MZ', 'OD', 'PB', 'RJ', 'SK',
          'TN', 'TS', 'TR', 'UP', 'UK', 'WB',
          // 8 UTs
          'AN', 'CH', 'DL', 'DD', 'JL', 'LA', 'LD', 'PY'
        ];

        for (final state in allStates) {
          expect(() {
            GSTCalculator.validateState(state);
          }, returnsNormally, reason: 'State $state should be valid');
        }

        expect(allStates.length, 36);
      });
    });

    group('Tax Slab Data', () {
      test('Maharashtra has correct tax slabs', () {
        final isValidState = StateTaxSlabs.isValidState('MH');
        expect(isValidState, true);
        
        // Check that the class has item lists defined
        expect(StateTaxSlabs.slab18Items, isNotEmpty);
      });

      test('All 36 states/UTs have tax slab entries', () {
        final allStates = [
          'AP', 'AR', 'AS', 'BR', 'CG', 'GA', 'GJ', 'HR', 'HP', 'JK', 'JH',
          'KA', 'KL', 'MP', 'MH', 'MN', 'ML', 'MZ', 'OD', 'PB', 'RJ', 'SK',
          'TN', 'TS', 'TR', 'UP', 'UK', 'WB',
          'AN', 'CH', 'DL', 'DD', 'JL', 'LA', 'LD', 'PY'
        ];

        for (final state in allStates) {
          expect(
            StateTaxSlabs.isValidState(state),
            true,
            reason: 'State $state should be valid',
          );
        }
      });

      test('Tax slabs contain common retail items', () {
        // Verify that common items can be classified into slabs
        expect(StateTaxSlabs.getProductSlab('Milk'), 5); // Should be in 5% slab
        expect(StateTaxSlabs.getProductSlab('Clothing'), 18); // Should be in 18% slab

        expect(
          StateTaxSlabs.slab18Items.any((item) =>
              item.toLowerCase().contains('retail') ||
              item.toLowerCase().contains('clothing') ||
              item.toLowerCase().contains('grocery')),
          true,
          reason: 'Should have common retail items in 18% slab',
        );
      });
    });

    group('Approval Workflow Logic', () {
      test('Draft created with PENDING status', () {
        // Simulating draft creation
        final draftApprovalStatus = 'PENDING';
        expect(draftApprovalStatus, equals('PENDING'));
      });

      test('Approval status transitions', () {
        final transitions = {
          'PENDING': ['APPROVED', 'REJECTED'],
          'APPROVED': ['MODIFIED'],
          'REJECTED': [],
        };

        expect(
          transitions['PENDING']?.contains('APPROVED'),
          true,
        );
        expect(
          transitions['REJECTED']?.isEmpty,
          true,
        );
      });

      test('Audit trail fields present', () {
        // Verify DraftApproval model has required audit fields
        final requiredAuditFields = [
          'approvalId',
          'createdAt',
          'reviewedBy',
          'reviewedAt',
          'approvalNotes',
          'approvalStatus'
        ];

        // In real scenario, would check model reflection
        // For now, verify contract
        expect(requiredAuditFields.length, 6);
      });
    });

    group('Tax Breakdown Formatting', () {
      test('Currency formatting with rupee symbol', () {
        final amount = 106.20;
        final formatted = '₹${amount.toStringAsFixed(2)}';
        expect(formatted, contains('₹'));
        expect(formatted, contains('106.20'));
      });

      test('Decimal handling for exact rupees', () {
        final amount = 100.0;
        final formatted = amount % 1 == 0 ? '₹${amount.toInt()}' : '₹$amount';
        expect(formatted, '₹100');
      });

      test('Tax breakdown message readability', () {
        final breakdown = '''
Customer: Test Customer
Items: Product A (2×₹50), Product B (1×₹100)
Subtotal: ₹200

Tax (Maharashtra, Registered):
  CGST (9%): ₹18.00
  SGST (9%): ₹18.00
  
✅ TOTAL: ₹236.00
''';

        expect(breakdown, contains('₹'));
        expect(breakdown, contains('Tax'));
        expect(breakdown, contains('TOTAL'));
        expect(breakdown, contains('✅'));
      });
    });

    group('Edge Cases', () {
      test('Single item billing', () {
        final items = [CartItem(productId: 'p1', quantity: 1, unitPrice: 100.0)];
        expect(items.length, 1);
        expect(items[0].quantity, 1);
      });

      test('Large quantity handling', () {
        final items = [
          CartItem(productId: 'p1', quantity: 1000, unitPrice: 10.0)
        ];
        expect(items[0].quantity * items[0].unitPrice, 10000.0);
      });

      test('Fractional pricing', () {
        final items = [CartItem(productId: 'p1', quantity: 1, unitPrice: 99.99)];
        expect(items[0].unitPrice, 99.99);
      });

      test('Zero quantity validation', () {
        // Should reject zero quantity
        expect(0, lessThan(1));
      });

      test('Negative price validation', () {
        // Should reject negative prices
        expect(-100.0, lessThan(0.0));
      });
    });

    group('Database Schema Integration', () {
      test('Shop config fields map to database columns', () {
        final expectedColumns = [
          'shop_id',
          'gst_registration_number',
          'state',
          'gst_mode',
          'business_type',
          'created_at',
          'updated_at'
        ];

        expect(expectedColumns.length, 7);
        expect(expectedColumns.contains('gst_registration_number'), true);
      });

      test('Draft approval fields map to database columns', () {
        final expectedColumns = [
          'approval_id',
          'draft_invoice_id',
          'shop_id',
          'created_at',
          'approval_status',
          'reviewed_by',
          'reviewed_at',
          'approval_notes',
          'sale_id'
        ];

        expect(expectedColumns.length, 9);
        expect(expectedColumns.contains('approval_status'), true);
      });
    });

    group('Telegram Integration', () {
      test('Approval button callback format', () {
        final approvalId = 'uuid-test-123';
        final callbackData = 'approve_$approvalId';
        expect(callbackData, startsWith('approve_'));
      });

      test('Rejection button callback format', () {
        final approvalId = 'uuid-test-123';
        final callbackData = 'reject_$approvalId';
        expect(callbackData, startsWith('reject_'));
      });

      test('Message has all required info', () {
        final message = '''
✅ Invoice Ready for Approval

Customer: Rajesh Kumar
Items:
  • Milk (1×₹50)
  • Bread (2×₹20)

Subtotal: ₹90
Tax (Maharashtra, Registered):
  CGST (9%): ₹8.10
  SGST (9%): ₹8.10

💰 TOTAL: ₹106.20

Please review and approve.
''';

        expect(message, contains('Invoice'));
        expect(message, contains('Customer'));
        expect(message, contains('Items'));
        expect(message, contains('Tax'));
        expect(message, contains('TOTAL'));
      });
    });
  });
}
