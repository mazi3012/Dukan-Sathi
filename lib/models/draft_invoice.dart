import 'package:freezed_annotation/freezed_annotation.dart';

import 'cart_item.dart';

part 'draft_invoice.freezed.dart';
part 'draft_invoice.g.dart';

@freezed
abstract class DraftInvoice with _$DraftInvoice {
  const factory DraftInvoice({
    required String id,
    @JsonKey(name: 'shop_id') required String shopId,
    @JsonKey(name: 'customer_id') String? customerId,
    required List<CartItem> items,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @Default('draft') String status,
  }) = _DraftInvoice;

  factory DraftInvoice.fromJson(Map<String, dynamic> json) =>
      _$DraftInvoiceFromJson(json);
}
