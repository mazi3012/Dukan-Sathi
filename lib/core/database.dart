import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:supabase/supabase.dart';

final DotEnv _env = (() {
  final env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    env.load(['.env']);
  }
  return env;
})();

String _readEnv(String key) {
  final fromPlatform = Platform.environment[key];
  if (fromPlatform != null && fromPlatform.isNotEmpty) {
    return fromPlatform;
  }
  return _env[key] ?? '';
}

final String _supabaseUrl = _readEnv('SUPABASE_URL');
final String _supabaseAnonKey = _readEnv('SUPABASE_ANON_KEY');

void _validateSupabaseEnv() {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL and SUPABASE_ANON_KEY must be set in environment variables.',
    );
  }
}

final SupabaseClient supabase = (() {
  _validateSupabaseEnv();
  return SupabaseClient(_supabaseUrl, _supabaseAnonKey);
})();
