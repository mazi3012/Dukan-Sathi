import 'package:postgres/postgres.dart';
import 'package:supabase/supabase.dart';
import 'env_stub.dart' if (dart.library.io) 'env_io.dart';

SupabaseClient? _manualInstance;
Pool? _dbPoolInstance;

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

dynamic getDatabasePool() {
  if (_dbPoolInstance != null) return _dbPoolInstance!;

  final loader = getLoader()..load();

  // 1. Try explicit DATABASE_URL (supplied in production Docker/Render/env)
  var dbUrl = const String.fromEnvironment('DATABASE_URL', defaultValue: '')
      .isNotEmpty ? const String.fromEnvironment('DATABASE_URL') : (loader.get('DATABASE_URL') ?? '');

  // 2. Fallback: construct from individual parameters
  if (dbUrl.isEmpty) {
    final host = const String.fromEnvironment('DB_HOST', defaultValue: '')
        .isNotEmpty ? const String.fromEnvironment('DB_HOST') : (loader.get('DB_HOST') ?? '');
    final portStr = const String.fromEnvironment('DB_PORT', defaultValue: '')
        .isNotEmpty ? const String.fromEnvironment('DB_PORT') : (loader.get('DB_PORT') ?? '6543');
    final dbName = const String.fromEnvironment('DB_NAME', defaultValue: '')
        .isNotEmpty ? const String.fromEnvironment('DB_NAME') : (loader.get('DB_NAME') ?? 'postgres');
    final user = const String.fromEnvironment('DB_USER', defaultValue: '')
        .isNotEmpty ? const String.fromEnvironment('DB_USER') : (loader.get('DB_USER') ?? '');
    final password = const String.fromEnvironment('DB_PASSWORD', defaultValue: '')
        .isNotEmpty ? const String.fromEnvironment('DB_PASSWORD') : (loader.get('DB_PASSWORD') ?? '');

    if (host.isNotEmpty && user.isNotEmpty && password.isNotEmpty) {
      dbUrl = 'postgresql://$user:$password@$host:$portStr/$dbName?sslmode=require';
    } else {
      // Auto fallback using SUPABASE_URL project ref
      final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '')
          .isNotEmpty ? const String.fromEnvironment('SUPABASE_URL') : (loader.get('SUPABASE_URL') ?? '');
      
      if (supabaseUrl.isNotEmpty) {
        final uri = Uri.tryParse(supabaseUrl);
        if (uri != null) {
          final projectRef = uri.host.split('.').first;
          final resolvedHost = 'aws-0-us-east-1.pooler.supabase.com'; // Standard pooler domain
          final resolvedUser = 'postgres.$projectRef';
          final dbPassword = const String.fromEnvironment('DB_PASSWORD', defaultValue: '')
              .isNotEmpty ? const String.fromEnvironment('DB_PASSWORD') : (loader.get('DB_PASSWORD') ?? '');
          
          if (dbPassword.isNotEmpty) {
            dbUrl = 'postgresql://$resolvedUser:$dbPassword@$resolvedHost:6543/postgres?sslmode=require';
          }
        }
      }
    }
  }

  if (dbUrl.isEmpty) {
    throw StateError(
      'Database connection URL/credentials not found. Please set DATABASE_URL (or DB_HOST, DB_USER, DB_PASSWORD).'
    );
  }

  // Force port 6543 to use Supavisor connection pooling for high scale if standard direct URL (5432) was specified
  if (dbUrl.contains('.supabase.co') || dbUrl.contains('.supabase.com')) {
    if (dbUrl.contains(':5432') && !dbUrl.contains(':6543')) {
      dbUrl = dbUrl.replaceFirst(':5432', ':6543');
    }
  }

  // Set default pool parameters if not explicitly defined in the URL
  if (!dbUrl.contains('max_connection_count')) {
    final separator = dbUrl.contains('?') ? '&' : '?';
    dbUrl = '$dbUrl${separator}max_connection_count=15';
  }

  _dbPoolInstance = Pool.withUrl(dbUrl);
  return _dbPoolInstance!;
}
