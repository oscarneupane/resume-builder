import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Google Places Autocomplete for the address field.
///
/// Reads GOOGLE_PLACES_API_KEY from `.env`. If it's missing/placeholder, [enabled]
/// is false and [autocomplete] returns an empty list — the address field then
/// behaves like a normal text input (graceful fallback, mock-mode parity).
///
/// NOTE: a Places key shipped in the app should be **restricted** in Google Cloud
/// (Android app restriction: package name + SHA-1, and limited to the Places API).
class PlacesService {
  PlacesService._();
  static final instance = PlacesService._();

  static const _endpoint = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  String? get _key {
    try {
      final k = dotenv.env['GOOGLE_PLACES_API_KEY'];
      if (k == null || k.isEmpty || k.startsWith('your-') || k.startsWith('AIza-your')) return null;
      return k;
    } catch (_) {
      return null;
    }
  }

  bool get enabled => _key != null;

  /// Returns up to ~5 address suggestion strings for [input]. Empty on no key,
  /// short input, or any error (so the UI degrades to a plain text field).
  Future<List<String>> autocomplete(String input) async {
    final key = _key;
    if (key == null || input.trim().length < 3) return const [];
    try {
      final uri = Uri.parse('$_endpoint?input=${Uri.encodeQueryComponent(input)}&types=geocode&key=$key');
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 'OK') return const [];
      final preds = (body['predictions'] as List?) ?? const [];
      return preds.map((p) => (p['description'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }
}
