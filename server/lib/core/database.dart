import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';

SupabaseClient? _supabaseInstance;

SupabaseClient get supabase {
  if (_supabaseInstance != null) return _supabaseInstance!;

  final env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    env.load(['.env']);
  } else if (File('../.env').existsSync()) {
    env.load(['../.env']);
  }
  final url = Platform.environment['SUPABASE_URL'] ?? env['SUPABASE_URL'] ?? '';
  // Prioritize service role key on server for RLS bypass
  final serviceKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? 
                     Platform.environment['SUPABASE_ANON_KEY'] ??
                     env['SUPABASE_SERVICE_ROLE_KEY'] ?? 
                     env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || serviceKey.isEmpty) {
    throw StateError('SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is missing!');
  }

  _supabaseInstance = SupabaseClient(url, serviceKey);
  return _supabaseInstance!;
}

bool isValidUuid(String? id) {
  if (id == null) return false;
  final regExp = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  return regExp.hasMatch(id);
}

Future<String> getShopIdForUser(String? userIdentifier) async {
  if (userIdentifier == null || userIdentifier.isEmpty) {
    throw StateError('Missing userIdentifier');
  }

  final id = userIdentifier.startsWith('user-') 
      ? userIdentifier.replaceFirst('user-', '') 
      : userIdentifier;

  try {
    final shopCheck = await supabase.from('shops').select('id').eq('id', id).maybeSingle();
    if (shopCheck != null) return shopCheck['id'] as String;
  } catch (_) {}

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

  final legacyResponse = await supabase
      .from('shops')
      .select('id')
      .eq('created_by', id)
      .eq('onboarding_completed', true)
      .maybeSingle();

  if (legacyResponse == null) {
    throw StateError('No active shop found for user $id. Please complete onboarding first.');
  }

  return legacyResponse['id'] as String;
}
