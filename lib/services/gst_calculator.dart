import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../models/shop_config.dart';
import '../models/tax_breakdown.dart';

class GSTCalculator {
  /// Generate a unique UUID for approval
  static String generateApprovalId() {
    return const Uuid().v4();
  }

  /// Calculate complete tax breakdown for items based on shop config.
  /// Each CartItem now carries its own `gstRate` — calculations use that
  /// instead of a flat 18%.
  /// [invoiceDiscount] — flat discount applied at invoice level (post-subtotal,
  /// pre-tax) per Section 15(3)(a) CGST Act. When supplied the taxable value
  /// becomes (subtotal − invoiceDiscount); the discount is distributed
  /// proportionally across GST rate groups for accurate rate-wise breakdown.
  static TaxBreakdown calculateTax({
    required List<CartItem> items,
    required ShopConfig shopConfig,
    String? customerState,
    double invoiceDiscount = 0.0,
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
          invoiceDiscount: invoiceDiscount,
        );

      case GSTMode.unregistered:
        return _calculateUnregisteredTax(
          items: items,
          shopState: shopConfig.state,
          invoiceDiscount: invoiceDiscount,
        );

      case GSTMode.composite:
        return _calculateCompositeTax(
          items: items,
          shopState: shopConfig.state,
          invoiceDiscount: invoiceDiscount,
        );
    }
  }

  /// Registered businesses: CGST/SGST (intra-state) or IGST (inter-state)
  /// Now uses per-item gstRate instead of hardcoded 18%.
  static TaxBreakdown _calculateRegisteredTax({
    required List<CartItem> items,
    required String shopState,
    String? customerState,
    required bool isInterState,
    double invoiceDiscount = 0.0,
  }) {
    double subtotal = 0;
    double totalCGST = 0;
    double totalSGST = 0;
    double totalIGST = 0;
    final breakdown = <Map<String, dynamic>>[];

    // Accumulators for rate-wise summary (before discount)
    final rateAccum = <double, Map<String, double>>{};

    for (final item in items) {
      final lineTotal = item.quantity * item.unitPrice;
      subtotal += lineTotal;

      final rate = item.gstRate; // per-product GST rate

      // Ensure rate accumulator entry exists
      rateAccum.putIfAbsent(rate, () => {
        'taxableAmount': 0.0,
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': 0.0,
      });
      rateAccum[rate]!['taxableAmount'] = rateAccum[rate]!['taxableAmount']! + lineTotal;
    }

    // Round the pre-discount subtotal
    subtotal = _roundToTwoDecimals(subtotal);

    // Clamp the invoice discount
    final effectiveDiscount = invoiceDiscount.clamp(0.0, subtotal);
    final taxableValue = _roundToTwoDecimals(subtotal - effectiveDiscount);
    // Ratio for proportionally distributing the discount across rate groups
    final discountRatio = subtotal > 0 ? taxableValue / subtotal : 1.0;

    // Now compute tax per rate group on discounted taxable amounts
    final sortedRates = rateAccum.keys.toList()..sort();
    for (final rate in sortedRates) {
      final acc = rateAccum[rate]!;
      // Apply proportional discount to this rate group's taxable amount
      final originalTaxable = acc['taxableAmount']!;
      final discountedTaxable = _roundToTwoDecimals(originalTaxable * discountRatio);
      acc['taxableAmount'] = discountedTaxable;

      final halfRate = rate / 2;

      if (isInterState) {
        final igst = _roundToTwoDecimals((discountedTaxable * rate) / 100);
        totalIGST += igst;
        acc['igst'] = igst;
      } else {
        final cgst = _roundToTwoDecimals((discountedTaxable * halfRate) / 100);
        final sgst = _roundToTwoDecimals((discountedTaxable * halfRate) / 100);
        totalCGST += cgst;
        totalSGST += sgst;
        acc['cgst'] = cgst;
        acc['sgst'] = sgst;
      }
    }

    // Build per-item breakdown (using original item prices, taxes proportional)
    for (final item in items) {
      final lineTotal = item.quantity * item.unitPrice;
      final rate = item.gstRate;
      final halfRate = rate / 2;
      // Discount-adjusted line total for tax computation
      final adjustedLineTotal = _roundToTwoDecimals(lineTotal * discountRatio);

      if (isInterState) {
        final igst = _roundToTwoDecimals((adjustedLineTotal * rate) / 100);
        breakdown.add({
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'lineTotal': lineTotal,
          'slab': rate,
          'cgst': 0,
          'sgst': 0,
          'igst': igst,
          'totalWithTax': adjustedLineTotal + igst,
        });
      } else {
        final cgst = _roundToTwoDecimals((adjustedLineTotal * halfRate) / 100);
        final sgst = _roundToTwoDecimals((adjustedLineTotal * halfRate) / 100);
        breakdown.add({
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'lineTotal': lineTotal,
          'slab': rate,
          'cgst': cgst,
          'sgst': sgst,
          'igst': 0,
          'totalWithTax': adjustedLineTotal + cgst + sgst,
        });
      }
    }

    final totalAmount = taxableValue + totalCGST + totalSGST + totalIGST;

    // Build rate-wise summary
    final rateWiseSummary = sortedRates.map((rate) {
      final acc = rateAccum[rate]!;
      final taxableAmt = _roundToTwoDecimals(acc['taxableAmount']!);
      final cgst = _roundToTwoDecimals(acc['cgst']!);
      final sgst = _roundToTwoDecimals(acc['sgst']!);
      final igst = _roundToTwoDecimals(acc['igst']!);
      return <String, dynamic>{
        'rate': rate,
        'taxableAmount': taxableAmt,
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
        'totalTax': _roundToTwoDecimals(cgst + sgst + igst),
      };
    }).toList();

    // Build human-readable tax slab description
    final uniqueRates = sortedRates.where((r) => r > 0).toList();
    final taxSlabDescription = uniqueRates.isEmpty
        ? 'Exempt (0%)'
        : isInterState
            ? uniqueRates.map((r) => 'IGST ${r.toStringAsFixed(r == r.roundToDouble() ? 0 : 1)}%').join(' + ')
            : uniqueRates.map((r) {
                final half = r / 2;
                final halfStr = half == half.roundToDouble() ? half.toInt().toString() : half.toStringAsFixed(1);
                return 'CGST $halfStr% + SGST $halfStr%';
              }).join(' | ');

    return TaxBreakdown(
      subtotal: taxableValue,
      cgstAmount: _roundToTwoDecimals(totalCGST),
      sgstAmount: _roundToTwoDecimals(totalSGST),
      igstAmount: _roundToTwoDecimals(totalIGST),
      gstMode: 'REGISTERED',
      applicableState: shopState,
      taxSlab: taxSlabDescription,
      totalAmount: _roundToTwoDecimals(totalAmount),
      breakdown: breakdown,
      rateWiseSummary: rateWiseSummary,
    );
  }

  /// Unregistered businesses: No GST (passthrough)
  static TaxBreakdown _calculateUnregisteredTax({
    required List<CartItem> items,
    required String shopState,
    double invoiceDiscount = 0.0,
  }) {
    double subtotal = 0;

    for (final item in items) {
      subtotal += item.quantity * item.unitPrice;
    }

    subtotal = _roundToTwoDecimals(subtotal);
    final taxableValue = _roundToTwoDecimals(subtotal - invoiceDiscount.clamp(0.0, subtotal));

    return TaxBreakdown(
      subtotal: taxableValue,
      cgstAmount: 0,
      sgstAmount: 0,
      igstAmount: 0,
      gstMode: 'UNREGISTERED',
      applicableState: shopState,
      taxSlab: 'No GST (Unregistered)',
      totalAmount: taxableValue,
      breakdown: [],
      rateWiseSummary: [],
    );
  }

  /// Composite businesses: Simplified 3% slab
  static TaxBreakdown _calculateCompositeTax({
    required List<CartItem> items,
    required String shopState,
    double invoiceDiscount = 0.0,
  }) {
    double subtotal = 0;

    for (final item in items) {
      subtotal += item.quantity * item.unitPrice;
    }

    subtotal = _roundToTwoDecimals(subtotal);
    final taxableValue = _roundToTwoDecimals(subtotal - invoiceDiscount.clamp(0.0, subtotal));

    // Composite GST: 3% standard for retail
    const compositeRate = 3.0;
    final compositeTax = (taxableValue * compositeRate) / 100;

    return TaxBreakdown(
      subtotal: taxableValue,
      cgstAmount: 0,
      sgstAmount: 0,
      igstAmount: 0,
      gstMode: 'COMPOSITE',
      applicableState: shopState,
      taxSlab: 'Composite GST 3%',
      totalAmount: _roundToTwoDecimals(taxableValue + compositeTax),
      breakdown: [],
      rateWiseSummary: [],
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
