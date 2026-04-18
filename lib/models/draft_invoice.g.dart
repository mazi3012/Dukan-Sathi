// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DraftInvoice _$DraftInvoiceFromJson(Map<String, dynamic> json) =>
    _DraftInvoice(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      customerId: json['customer_id'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'draft',
    );

Map<String, dynamic> _$DraftInvoiceToJson(_DraftInvoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shop_id': instance.shopId,
      'customer_id': instance.customerId,
      'items': instance.items,
      'total_amount': instance.totalAmount,
      'status': instance.status,
    };
