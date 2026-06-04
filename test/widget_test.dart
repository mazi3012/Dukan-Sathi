import 'package:flutter_test/flutter_test.dart';
import 'package:dukansathi_new/services/gst_calculator.dart';
import 'package:dukansathi_new/models/cart_item.dart';
import 'package:dukansathi_new/models/shop_config.dart';

void main() {
  group('GSTCalculator Unit Tests', () {
    final shopConfigRegistered = ShopConfig(
      shopId: 'shop_123',
      state: 'AS',
      gstMode: GSTMode.registered,
      businessType: 'Retail',
      createdAt: DateTime.now(),
    );

    final shopConfigUnregistered = ShopConfig(
      shopId: 'shop_123',
      state: 'AS',
      gstMode: GSTMode.unregistered,
      businessType: 'Retail',
      createdAt: DateTime.now(),
    );

    final shopConfigComposite = ShopConfig(
      shopId: 'shop_123',
      state: 'AS',
      gstMode: GSTMode.composite,
      businessType: 'Retail',
      createdAt: DateTime.now(),
    );

    test('Registered - Intra-state CGST & SGST Calculation', () {
      final items = [
        const CartItem(productId: 'p1', quantity: 2, unitPrice: 100, gstRate: 18),
        const CartItem(productId: 'p2', quantity: 1, unitPrice: 200, gstRate: 12),
      ];

      final result = GSTCalculator.calculateTax(
        items: items,
        shopConfig: shopConfigRegistered,
        customerState: 'AS', // Same state -> Intra-state
      );

      // Total taxable = (2 * 100) + (1 * 200) = 400
      // Tax:
      // p1: 200 * 18% = 36 GST (18 CGST, 18 SGST)
      // p2: 200 * 12% = 24 GST (12 CGST, 12 SGST)
      // Total CGST = 18 + 12 = 30
      // Total SGST = 18 + 12 = 30
      // Total IGST = 0
      // Total Amount = 400 + 30 + 30 = 460
      expect(result.subtotal, equals(400.0));
      expect(result.cgstAmount, equals(30.0));
      expect(result.sgstAmount, equals(30.0));
      expect(result.igstAmount, equals(0.0));
      expect(result.totalAmount, equals(460.0));
      expect(result.gstMode, equals('REGISTERED'));
    });

    test('Registered - Inter-state IGST Calculation', () {
      final items = [
        const CartItem(productId: 'p1', quantity: 2, unitPrice: 100, gstRate: 18),
      ];

      final result = GSTCalculator.calculateTax(
        items: items,
        shopConfig: shopConfigRegistered,
        customerState: 'DL', // Different state -> Inter-state
      );

      // Total taxable = 200
      // IGST = 200 * 18% = 36
      expect(result.subtotal, equals(200.0));
      expect(result.cgstAmount, equals(0.0));
      expect(result.sgstAmount, equals(0.0));
      expect(result.igstAmount, equals(36.0));
      expect(result.totalAmount, equals(236.0));
    });

    test('Registered - Invoice Discount Allocation', () {
      final items = [
        const CartItem(productId: 'p1', quantity: 2, unitPrice: 100, gstRate: 18),
        const CartItem(productId: 'p2', quantity: 1, unitPrice: 200, gstRate: 12),
      ];

      // Total subtotal = 400
      // Apply flat discount of 100 -> Total taxable becomes 300
      final result = GSTCalculator.calculateTax(
        items: items,
        shopConfig: shopConfigRegistered,
        customerState: 'AS',
        invoiceDiscount: 100,
      );

      // Proportional discount ratio = 300 / 400 = 0.75
      // p1 discounted taxable = 200 * 0.75 = 150
      // p2 discounted taxable = 200 * 0.75 = 150
      // Taxes:
      // p1 (18%): 150 * 9% CGST = 13.5, 13.5 SGST
      // p2 (12%): 150 * 6% CGST = 9.0, 9.0 SGST
      // Total CGST = 13.5 + 9.0 = 22.5
      // Total SGST = 13.5 + 9.0 = 22.5
      // Total Amount = 300 + 22.5 + 22.5 = 345
      expect(result.subtotal, equals(300.0));
      expect(result.cgstAmount, equals(22.5));
      expect(result.sgstAmount, equals(22.5));
      expect(result.totalAmount, equals(345.0));
    });

    test('Unregistered - No GST calculation', () {
      final items = [
        const CartItem(productId: 'p1', quantity: 2, unitPrice: 100, gstRate: 18),
      ];

      final result = GSTCalculator.calculateTax(
        items: items,
        shopConfig: shopConfigUnregistered,
      );

      expect(result.subtotal, equals(200.0));
      expect(result.totalAmount, equals(200.0));
      expect(result.cgstAmount, equals(0.0));
      expect(result.sgstAmount, equals(0.0));
      expect(result.gstMode, equals('UNREGISTERED'));
    });

    test('Composite - Standard 3% Composite Rate Calculation', () {
      final items = [
        const CartItem(productId: 'p1', quantity: 2, unitPrice: 100, gstRate: 18),
      ];

      final result = GSTCalculator.calculateTax(
        items: items,
        shopConfig: shopConfigComposite,
      );

      // Subtotal = 200
      // Composite GST = 3% of 200 = 6
      expect(result.subtotal, equals(200.0));
      expect(result.totalAmount, equals(206.0));
      expect(result.gstMode, equals('COMPOSITE'));
    });
  });
}
