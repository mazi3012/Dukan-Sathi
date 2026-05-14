import 'package:supabase/supabase.dart';
import 'supabase_provider_stub.dart'
    if (dart.library.ui) 'supabase_provider_flutter.dart'
    if (dart.library.io) 'supabase_provider_dart.dart'
    if (dart.library.html) 'supabase_provider_flutter.dart';

SupabaseClient get supabase => getSupabaseInstance();

/// Helper to get the shop ID for a given user identifier.
Future<String> getShopIdForUser(String? userIdentifier) async {
  if (userIdentifier == null || userIdentifier.isEmpty) {
    throw StateError('Missing userIdentifier');
  }

  // Normalize: Strip "user-" prefix if present
  final id = userIdentifier.startsWith('user-') 
      ? userIdentifier.replaceFirst('user-', '') 
      : userIdentifier;

  // 1. Direct Shop ID check (if userIdentifier is actually a shopId)
  try {
    final shopCheck = await supabase.from('shops').select('id').eq('id', id).maybeSingle();
    if (shopCheck != null) return shopCheck['id'] as String;
  } catch (_) {}

  // 2. Try unified lookup (by UUID, Google ID, or Email)
  try {
    final unifiedRes = await supabase
        .from('users')
        .select('shops!fk_shops_owner(id)')
        .or('id.eq.$id,google_id.eq.$id,email.eq.$id')
        .maybeSingle();

    if (unifiedRes != null && unifiedRes['shops'] != null) {
      final shops = unifiedRes['shops'] as List;
      if (shops.isNotEmpty) return shops.first['id'] as String;
    }
  } catch (e) {
    // Fall through
  }

  // 3. Fallback to legacy created_by lookup (backwards compatibility for Telegram)
  final legacyResponse = await supabase
      .from('shops')
      .select('id')
      .eq('created_by', id)
      .eq('onboarding_completed', true)
      .maybeSingle();

  if (legacyResponse == null) {
    throw StateError('No active shop found for user $id. Please complete /start onboarding first.');
  }

  return legacyResponse['id'] as String;
}
