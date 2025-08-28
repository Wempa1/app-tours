import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class AppSupabase {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Env.load();
    final url = Env.supabaseUrl;
    final anon = Env.supabaseAnonKey;
    if (url.isEmpty || anon.isEmpty) {
      throw StateError('Falta SUPABASE_URL o SUPABASE_ANON_KEY');
    }
    await Supabase.initialize(url: url, anonKey: anon);
  }
}
