import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale.freezed.dart';
part 'sale.g.dart';

@freezed
abstract class Sale with _$Sale {
  const factory Sale({
    required String id,
    @JsonKey(name: 'shop_id') required String shopId,
    @JsonKey(name: 'invoice_id') required String invoiceId,
    required DateTime timestamp,
    @JsonKey(name: 'payment_method') required String paymentMethod,
  }) = _Sale;

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
}
