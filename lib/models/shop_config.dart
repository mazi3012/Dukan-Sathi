import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_config.freezed.dart';
part 'shop_config.g.dart';

enum GSTMode {
  @JsonValue('REGISTERED')
  registered,
  @JsonValue('UNREGISTERED')
  unregistered,
  @JsonValue('COMPOSITE')
  composite,
}

@freezed
abstract class ShopConfig with _$ShopConfig {
  const factory ShopConfig({
    required String shopId,
    @JsonKey(name: 'gst_registration_number') String? gstRegistrationNumber,
    required String state,
    @JsonKey(name: 'gst_mode') required GSTMode gstMode,
    @JsonKey(name: 'business_type') required String businessType,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ShopConfig;

  factory ShopConfig.fromJson(Map<String, dynamic> json) =>
      _$ShopConfigFromJson(json);
}
