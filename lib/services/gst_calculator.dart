import 'package:uuid/uuid.dart';
import '../data/state_tax_slabs.dart';
import '../models/cart_item.dart';
import '../models/shop_config.dart';
import '../models/tax_breakdown.dart';

class GSTCalculator {
  /// Generate a unique UUID for approval
  static String generateApprovalId() {
    return const Uuid().v4();
  }

  /// Calculate complete tax breakdown for items based on shop config
  static TaxBreakdown calculateTax({
    required List<CartItem> items,
    required ShopConfig shopConfig,
    String? customerState,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('Items list cannot be empty');
    }
    // Determine if inter-state transaction
    final isInterState =
        customerState != null && customerState != shopConfig.state;

    switch (shopConfig.gstMode) {
      case GSTMode.registered:
        return _calculateRegisteredTax(
          items: items,
          shopState: shopConfig.state,
          customerState: customerState,
          isInterState: isInterState,
        );

      case GSTMode.unregistered:
        return _calculateUnregisteredTax(
          items: items,
          shopState: shopConfig.state,
        );

      case GSTMode.composite:
        return _calculateCompositeTax(
          items: items,
          shopState: shopConfig.state,
        );
    }
  }

  /// Registered businesses: CGST/SGST (intra-state) or IGST (inter-state)
  static TaxBreakdown _calculateRegisteredTax({
    required List<CartItem> items,
    required String shopState,
    String? customerState,
    required bool isInterState,
  }) {
    double subtotal = 0;
    double totalCGST = 0;
    double totalSGST = 0;
    double totalIGST = 0;
    final breakdown = <Map<String, dynamic>>[];

    for (final item in items) {
      final lineTotal = item.quantity * item.unitPrice;
      subtotal += lineTotal;

      // Get tax slab (18% default for most retail)
      const slab = 18;

      if (isInterState) {
        // Inter-state: IGST only
        final igst = (lineTotal * 18) / 100;
        totalIGST += igst;

        breakdown.add({
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'lineTotal': lineTotal,
          'slab': slab,
          'cgst': 0,
          'sgst': 0,
          'igst': igst,
          'totalWithTax': lineTotal + igst,
        });
      } else {
        // Intra-state: CGST + SGST
        final cgst = (lineTotal * 9) / 100;
        final sgst = (lineTotal * 9) / 100;
        totalCGST += cgst;
        totalSGST += sgst;

        breakdown.add({
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'lineTotal': lineTotal,
          'slab': slab,
          'cgst': cgst,
          'sgst': sgst,
          'igst': 0,
          'totalWithTax': lineTotal + cgst + sgst,
        });
      }
    }

    final totalAmount = subtotal + totalCGST + totalSGST + totalIGST;
    final taxSlabDescription =
        isInterState ? 'IGST 18% (Inter-State)' : 'CGST 9% + SGST 9%';

    return TaxBreakdown(
      subtotal: _roundToTwoDecimals(subtotal),
      cgstAmount: _roundToTwoDecimals(totalCGST),
      sgstAmount: _roundToTwoDecimals(totalSGST),
      igstAmount: _roundToTwoDecimals(totalIGST),
      gstMode: 'REGISTERED',
      applicableState: shopState,
      taxSlab: taxSlabDescription,
      totalAmount: _roundToTwoDecimals(totalAmount),
      breakdown: breakdown,
    );
  }

  /// Unregistered businesses: No GST (passthrough)
  static TaxBreakdown _calculateUnregisteredTax({
    required List<CartItem> items,
    required String shopState,
  }) {
    double subtotal = 0;

    for (final item in items) {
      subtotal += item.quantity * item.unitPrice;
    }

    return TaxBreakdown(
      subtotal: _roundToTwoDecimals(subtotal),
      cgstAmount: 0,
      sgstAmount: 0,
      igstAmount: 0,
      gstMode: 'UNREGISTERED',
      applicableState: shopState,
      taxSlab: 'No GST (Unregistered)',
      totalAmount: _roundToTwoDecimals(subtotal),
      breakdown: [],
    );
  }

  /// Composite businesses: Simplified 3% slab
  static TaxBreakdown _calculateCompositeTax({
    required List<CartItem> items,
    required String shopState,
  }) {
    double subtotal = 0;

    for (final item in items) {
      subtotal += item.quantity * item.unitPrice;
    }

    // Composite GST: 3% standard for retail
    const compositeRate = 3.0;
    final compositeTax = (subtotal * compositeRate) / 100;

    return TaxBreakdown(
      subtotal: _roundToTwoDecimals(subtotal),
      cgstAmount: 0,
      sgstAmount: 0,
      igstAmount: 0,
      gstMode: 'COMPOSITE',
      applicableState: shopState,
      taxSlab: 'Composite GST 3%',
      totalAmount: _roundToTwoDecimals(subtotal + compositeTax),
      breakdown: [],
    );
  }

  /// Round to 2 decimal places (Indian rupee standard)
  static double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// Validate state code exists
  static void validateState(String state) {
    const validStates = [
      'AP', 'AR', 'AS', 'BR', 'CG', 'GA', 'GJ', 'HR', 'HP', 'JK', 'JH',
      'KA', 'KL', 'MP', 'MH', 'MN', 'ML', 'MZ', 'OD', 'PB', 'RJ', 'SK',
      'TN', 'TS', 'TR', 'UP', 'UK', 'WB',
      'AN', 'CH', 'DL', 'DD', 'JL', 'LA', 'LD', 'PY'
    ];

    if (!validStates.contains(state)) {
      throw ArgumentError('Invalid state code: $state');
    }
  }
}
