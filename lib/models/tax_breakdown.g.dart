// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaxBreakdown _$TaxBreakdownFromJson(Map<String, dynamic> json) =>
    _TaxBreakdown(
      subtotal: (json['subtotal'] as num).toDouble(),
      cgstAmount: (json['cgst_amount'] as num).toDouble(),
      sgstAmount: (json['sgst_amount'] as num).toDouble(),
      igstAmount: (json['igst_amount'] as num).toDouble(),
      gstMode: json['gst_mode'] as String,
      applicableState: json['applicable_state'] as String,
      taxSlab: json['tax_slab'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      breakdown: (json['breakdown'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      rateWiseSummary:
          (json['rate_wise_summary'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TaxBreakdownToJson(_TaxBreakdown instance) =>
    <String, dynamic>{
      'subtotal': instance.subtotal,
      'cgst_amount': instance.cgstAmount,
      'sgst_amount': instance.sgstAmount,
      'igst_amount': instance.igstAmount,
      'gst_mode': instance.gstMode,
      'applicable_state': instance.applicableState,
      'tax_slab': instance.taxSlab,
      'total_amount': instance.totalAmount,
      'breakdown': instance.breakdown,
      'rate_wise_summary': instance.rateWiseSummary,
    };
