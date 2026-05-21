import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const String userIdKey = 'ds_user_id';
  static const String userNameKey = 'ds_user_name';
  static const String shopIdKey = 'ds_shop_id';
  static const String shopNameKey = 'ds_shop_name';
  static const String shopStateKey = 'ds_shop_state';
  static const String shopGstModeKey = 'ds_shop_gst_mode';
  static const String shopGstNumKey = 'ds_shop_gst_num';
  static const String shopBusinessTypeKey = 'ds_shop_business_type';

  Future<void> saveUser(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, id);
    await prefs.setString(userNameKey, name);
  }

  Future<void> saveShop({
    required String id,
    required String name,
    required String state,
    required String gstMode,
    String? gstNum,
    required String businessType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(shopIdKey, id);
    await prefs.setString(shopNameKey, name);
    await prefs.setString(shopStateKey, state);
    await prefs.setString(shopGstModeKey, gstMode);
    if (gstNum != null) {
      await prefs.setString(shopGstNumKey, gstNum);
    } else {
      await prefs.remove(shopGstNumKey);
    }
    await prefs.setString(shopBusinessTypeKey, businessType);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(shopIdKey);
    await prefs.remove(shopNameKey);
    await prefs.remove(shopStateKey);
    await prefs.remove(shopGstModeKey);
    await prefs.remove(shopGstNumKey);
    await prefs.remove(shopBusinessTypeKey);
  }
}
