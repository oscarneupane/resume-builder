import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase client.
///
/// When SUPABASE_URL / SUPABASE_ANON_KEY are missing (e.g. fresh checkout, no
/// project yet), [SupabaseService.isConfigured] returns false and callers
/// should fall back to mock data — see [AuthRepository] / [AiService] for the
/// pattern. This lets UI flows be validated without provisioning infra first.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  static bool _initialized = false;
  static bool _configured = false;

  static bool get isConfigured => _configured;

  static String? _readEnv(String key) {
    try {
      final v = dotenv.env[key];
      if (v == null || v.isEmpty) return null;
      // Placeholder values from .env.example trigger mock mode.
      if (v.startsWith('your-') || v.contains('your-project')) return null;
      return v;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final url = _readEnv('SUPABASE_URL');
    final key = _readEnv('SUPABASE_ANON_KEY');
    if (url == null || key == null) {
      _configured = false;
      return;
    }
    // supabase_flutter 2.x renamed `anonKey` to `publishableKey` — still
    // backed by the same value (sb_publishable_…/anon JWT). Use a try-catch to
    // remain compatible with both 2.5 (anonKey) and 2.x post-rename.
    try {
      await Supabase.initialize(url: url, anonKey: key);
    } catch (_) {
      _configured = false;
      rethrow;
    }
    _configured = true;
  }

  SupabaseClient get client {
    if (!_configured) {
      throw StateError('Supabase is not configured — fill .env first.');
    }
    return Supabase.instance.client;
  }

  String? get currentUserId => _configured ? Supabase.instance.client.auth.currentUser?.id : null;
}
