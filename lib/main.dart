import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/constants.dart';
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

  // Seed the onboarding flag synchronously so the router redirect is correct
  // from the first frame.
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool(AppConstants.prefHasOnboarded) ?? false;

  runApp(
    ProviderScope(
      overrides: [onboardingCompleteProvider.overrideWith((ref) => onboarded)],
      child: const ApplyMateApp(),
    ),
  );
}
