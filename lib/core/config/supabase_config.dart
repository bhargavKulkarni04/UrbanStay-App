import 'package:flutter/services.dart' show rootBundle;

// ==============================================================================
// SUPABASE CLIENT CONFIGURATION
// UrbanStay Master Database Connection
// Loads securely from environment / .env file — ZERO hardcoded keys in source code
// ==============================================================================

class SupabaseConfig {
  static String _url = const String.fromEnvironment('SUPABASE_URL');
  static String _anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _url;
  static String get supabaseAnonKey => _anonKey;

  /// Loads configuration securely from .env at runtime
  static Future<void> init() async {
    try {
      final raw = await rootBundle.loadString('.env');
      for (final line in raw.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final idx = trimmed.indexOf('=');
        if (idx != -1) {
          final key = trimmed.substring(0, idx).trim();
          final val = trimmed
              .substring(idx + 1)
              .trim()
              .replaceAll('"', '')
              .replaceAll("'", "");
          if (key == 'SUPABASE_URL' && _url.isEmpty) {
            _url = val;
          } else if ((key == 'SUPABASE_ANON_KEY' || key == 'SUPABASE_KEY') &&
              _anonKey.isEmpty) {
            _anonKey = val;
          }
        }
      }
    } catch (_) {
      // Falls back to --dart-define environment variables
    }
  }
}
