import 'package:supabase/supabase.dart';
import 'env_stub.dart'
    if (dart.library.io) 'env_io.dart'
    if (dart.library.html) 'env_web.dart';

final _loader = getLoader()..load();

String _readEnv(String key) {
  final fromDartDefine = String.fromEnvironment(key);
  if (fromDartDefine.isNotEmpty) return fromDartDefine;
  return _loader.get(key) ?? '';
}

final String _supabaseUrl = _readEnv('SUPABASE_URL');
final String _supabaseAnonKey = _readEnv('SUPABASE_ANON_KEY');
final String _supabaseServiceRoleKey = _readEnv('SUPABASE_SERVICE_ROLE_KEY');

void _validateSupabaseEnv() {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL and SUPABASE_ANON_KEY must be set in environment variables.',
    );
  }
}

final SupabaseClient supabase = (() {
  _validateSupabaseEnv();
  final key = _supabaseServiceRoleKey.isNotEmpty ? _supabaseServiceRoleKey : _supabaseAnonKey;
  return SupabaseClient(_supabaseUrl, key);
})();

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
