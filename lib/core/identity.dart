import 'database.dart';

class IdentityManager {
  /// Finds or creates a user based on their Telegram ID.
  /// Used during onboarding and Telegram bot interactions.
  static Future<String> getOrCreateUserByTelegram(int telegramId, {String? fullName}) async {
    final existing = await supabase
        .from('users')
        .select('id')
        .eq('telegram_id', telegramId)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final inserted = await supabase
        .from('users')
        .insert({
          'telegram_id': telegramId,
          'full_name': fullName,
        })
        .select('id')
        .single();
    
    return inserted['id'] as String;
  }

  /// Links a Google account to an existing user.
  /// This is the core of the "Unified Account" logic.
  static Future<void> linkGoogleAccount(String userId, String googleId, String email) async {
    await supabase.from('users').update({
      'google_id': googleId,
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Retrieves the Shop ID associated with a login method.
  static Future<String?> getShopIdByIdentity({
    int? telegramId,
    String? googleId,
    String? phoneNumber,
    String? email,
  }) async {
    var query = supabase.from('users').select('shops!fk_shops_owner(id)');

    if (telegramId != null) {
      query = query.eq('telegram_id', telegramId);
    } else if (googleId != null) {
      query = query.eq('google_id', googleId);
    } else if (phoneNumber != null) {
      query = query.eq('phone_number', phoneNumber);
    } else if (email != null) {
      query = query.eq('email', email);
    } else {
      return null;
    }

    final res = await query.maybeSingle();
    if (res != null && res['shops'] != null) {
      final shops = res['shops'] as List;
      if (shops.isNotEmpty) return shops.first['id'] as String;
    }
    return null;
  }
}
