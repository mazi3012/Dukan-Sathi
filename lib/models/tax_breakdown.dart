import 'package:freezed_annotation/freezed_annotation.dart';

part 'tax_breakdown.freezed.dart';
part 'tax_breakdown.g.dart';

@freezed
abstract class TaxBreakdown with _$TaxBreakdown {
  const factory TaxBreakdown({
    required double subtotal,
    @JsonKey(name: 'cgst_amount') required double cgstAmount,
    @JsonKey(name: 'sgst_amount') required double sgstAmount,
    @JsonKey(name: 'igst_amount') required double igstAmount,
    @JsonKey(name: 'gst_mode') required String gstMode,
    @JsonKey(name: 'applicable_state') required String applicableState,
    @JsonKey(name: 'tax_slab') required String taxSlab,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'breakdown') required List<Map<String, dynamic>> breakdown,
  }) = _TaxBreakdown;

  factory TaxBreakdown.fromJson(Map<String, dynamic> json) =>
      _$TaxBreakdownFromJson(json);
}
