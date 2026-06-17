import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env quietly — missing file is fine in dev (services fall back to mock).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env yet — services will run in mock mode.
  }
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: ApplyMateApp()));
}
