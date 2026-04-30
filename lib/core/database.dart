import 'package:supabase/supabase.dart';
import 'env_stub.dart'
    if (dart.library.io) 'env_io.dart'
    if (dart.library.html) 'env_web.dart';

final _loader = getLoader()..load();

final String _supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
final String _supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
final String _supabaseServiceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');

String _getEnv(String key, String dartDefineValue) {
  if (dartDefineValue.isNotEmpty) return dartDefineValue;
  return _loader.get(key) ?? '';
}

final String resolvedSupabaseUrl = _getEnv('SUPABASE_URL', _supabaseUrl);
final String resolvedSupabaseAnonKey = _getEnv('SUPABASE_ANON_KEY', _supabaseAnonKey);
final String resolvedSupabaseServiceRoleKey = _getEnv('SUPABASE_SERVICE_ROLE_KEY', _supabaseServiceRoleKey);

void _validateSupabaseEnv() {
  if (resolvedSupabaseUrl.isEmpty || resolvedSupabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL and SUPABASE_ANON_KEY must be set in environment variables.',
    );
  }
}

final SupabaseClient supabase = (() {
  _validateSupabaseEnv();
  final key = resolvedSupabaseServiceRoleKey.isNotEmpty ? resolvedSupabaseServiceRoleKey : resolvedSupabaseAnonKey;
  return SupabaseClient(resolvedSupabaseUrl, key);
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
