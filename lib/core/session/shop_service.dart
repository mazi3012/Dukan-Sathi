import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database.dart'; // Import supabase client

class ShopService {
  Future<Map<String, dynamic>?> fetchShop(String userId) async {
    try {
      final shopResult = await supabase
          .from('shops')
          .select('id, name, state, gst_mode, gst_registration_number, business_type')
          .eq('owner_id', userId)
          .maybeSingle();
      return shopResult;
    } catch (e) {
      debugPrint('[ShopService] Fetch shop error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createShop({
    required String ownerId,
    required String name,
    required String state,
    required String businessType,
    String? gstNumber,
    String gstMode = 'UNREGISTERED',
    String? upiId,
  }) async {
    try {
      final result = await supabase.from('shops').insert({
        'owner_id': ownerId,
        'name': name,
        'state': state,
        'business_type': businessType,
        'gst_registration_number': gstNumber,
        'gst_mode': gstMode,
        'upi_id': upiId,
        'onboarding_completed': true,
      }).select('id, name, state, gst_mode, gst_registration_number, business_type').single();
      return result;
    } catch (e) {
      debugPrint('[ShopService] createShop error: $e');
      rethrow;
    }
  }
}
