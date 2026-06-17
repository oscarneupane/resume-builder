import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import 'supabase_service.dart';

/// Opens Stripe Checkout via the `create-checkout` Edge Function (Part H3/H5).
class StripeService {
  StripeService._();
  static final instance = StripeService._();

  /// Returns true if checkout URL was launched.
  Future<bool> startCheckout() async {
    if (!SupabaseService.isConfigured) {
      throw StateError('Supabase not configured — fill .env first.');
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw StateError('Not signed in.');

    final url = dotenv.env['SUPABASE_URL'];
    final endpoint = Uri.parse('$url/functions/v1/${AppConstants.fnCreateCheckout}');

    final res = await http.post(
      endpoint,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to start checkout (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final checkoutUrl = body['url'] as String?;
    if (checkoutUrl == null) return false;
    return launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
  }
}
