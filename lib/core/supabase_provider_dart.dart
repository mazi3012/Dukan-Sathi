import 'package:supabase/supabase.dart';
import 'env_stub.dart' if (dart.library.io) 'env_io.dart';

SupabaseClient? _manualInstance;

SupabaseClient getSupabaseInstance() {
  if (_manualInstance != null) return _manualInstance!;
  
  final loader = getLoader()..load();
  
  // Try environment variables first (Dart defines)
  final String url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final String anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  final String serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');
  
  // Fallback to .env file loader
  final String resolvedUrl = url.isNotEmpty ? url : (loader.get('SUPABASE_URL') ?? '');
  final String resolvedKey = serviceRoleKey.isNotEmpty 
      ? serviceRoleKey 
      : (anonKey.isNotEmpty ? anonKey : (loader.get('SUPABASE_SERVICE_ROLE_KEY') ?? loader.get('SUPABASE_ANON_KEY') ?? ''));

  if (resolvedUrl.isEmpty || resolvedKey.isEmpty) {
    throw StateError('Supabase credentials not found. Set SUPABASE_URL and SUPABASE_ANON_KEY/SUPABASE_SERVICE_ROLE_KEY.');
  }

  _manualInstance = SupabaseClient(resolvedUrl, resolvedKey);
  return _manualInstance!;
}
