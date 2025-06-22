import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
  static final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl ?? '',
      anonKey: supabaseAnonKey ?? '',
      debug: true, // Set to false in production
    );
  }
}
