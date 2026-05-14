import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient getSupabaseInstance() {
  try {
    return Supabase.instance.client;
  } catch (e) {
    // If not initialized yet, this might throw. 
    // But since it's a getter, it will be called when needed.
    rethrow;
  }
}
