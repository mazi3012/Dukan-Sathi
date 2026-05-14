import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient supabase = Supabase.instance.client;

/// Helper to get the shop ID for a given user identifier.
Future<String> getShopIdForUser(String? userIdentifier) async {
  if (userIdentifier == null || userIdentifier.isEmpty) {
    throw StateError('Missing userIdentifier');
  }

  // 1. Try unified lookup (by UUID, Google ID, or Email)
  try {
    final unifiedRes = await supabase
        .from('users')
        .select('shops!fk_shops_owner(id)')
        .or('id.eq."$userIdentifier",google_id.eq."$userIdentifier",email.eq."$userIdentifier"')
        .maybeSingle();

    if (unifiedRes != null && unifiedRes['shops'] != null) {
      final shops = unifiedRes['shops'] as List;
      if (shops.isNotEmpty) return shops.first['id'] as String;
    }
  } catch (e) {
    // Fall through to legacy if UUID format is invalid or other error
  }

  // 2. Fallback to legacy created_by lookup (backwards compatibility for Telegram)
  final legacyResponse = await supabase
      .from('shops')
      .select('id')
      .eq('created_by', userIdentifier)
      .eq('onboarding_completed', true)
      .maybeSingle();

  if (legacyResponse == null) {
    throw StateError('No active shop found for user $userIdentifier. Please complete /start onboarding first.');
  }

  return legacyResponse['id'] as String;
}
