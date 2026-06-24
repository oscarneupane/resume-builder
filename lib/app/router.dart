import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/ats_checker/screens/ats_checker_screen.dart';
import '../features/cover_letter/screens/cover_letter_screen.dart';
import '../features/dashboard/screens/home_shell.dart';
import '../features/documents/screens/documents_screen.dart';
import '../features/interview_prep/screens/interview_screen.dart';
import '../features/job_tracker/screens/job_tracker_screen.dart';
import '../features/legal/screens/legal_screen.dart';
import '../features/linkedin_helper/screens/linkedin_screen.dart';
import '../features/materials/screens/materials_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/resume_builder/screens/resume_builder_screen.dart';
import '../features/resume_builder/screens/resume_list_screen.dart';
import '../features/resume_builder/screens/resume_preview_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/subscription/screens/payment_failed_screen.dart';
import '../features/subscription/screens/payment_success_screen.dart';
import '../features/subscription/screens/subscription_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';
  static const dashboard = '/dashboard';
  static const docs = '/docs';
  static const create = '/create';
  static const resources = '/resources';
  static const profile = '/profile';

  static const resumeList = '/resumes';
  static const resumeBuilder = '/resumes/builder';
  static const resumePreview = '/resumes/preview';

  static const ats = '/ats';
  static const coverLetter = '/cover-letter';
  static const linkedin = '/linkedin';
  static const interview = '/interview';
  static const jobTracker = '/jobs';
  static const materials = '/materials';
  static const settings = '/settings';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const subscription = '/subscription';
  static const paymentSuccess = '/payment-success';
  static const paymentFailed = '/payment-failed';
}

/// Whether onboarding has been completed. Seeded from SharedPreferences in
/// main() via an override, and flipped to true synchronously when onboarding
/// finishes — so the router redirect sees the change immediately (a cached
/// FutureProvider would not).
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      // While bootstrapping, sit on splash
      if (auth.initializing) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final hasOnboarded = ref.read(onboardingCompleteProvider);

      final atSplash = loc == AppRoutes.splash;
      final atAuth = const {AppRoutes.login, AppRoutes.signup, AppRoutes.forgot}.contains(loc);
      final atOnboarding = loc == AppRoutes.onboarding;

      // Not signed in: only auth/onboarding screens are reachable. Anything else
      // (e.g. logging out from a deep screen) redirects back to login/onboarding.
      if (!auth.isSignedIn) {
        if (!hasOnboarded) return atOnboarding ? null : AppRoutes.onboarding;
        return atAuth ? null : AppRoutes.login;
      }

      // Signed in → dashboard (don't sit on auth/splash)
      if (atSplash || atAuth || atOnboarding) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(path: AppRoutes.forgot, builder: (_, __) => const ForgotPasswordScreen()),

      // Bottom-nav shell — keeps the tab bar across tab switches
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardTab()),
          GoRoute(path: AppRoutes.docs, builder: (_, __) => const DocumentsScreen()),
          GoRoute(path: AppRoutes.create, builder: (_, __) => const QuickCreateScreen()),
          GoRoute(path: AppRoutes.resources, builder: (_, __) => const MaterialsScreen()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileTabScreen()),
        ],
      ),

      GoRoute(path: AppRoutes.resumeList, builder: (_, __) => const ResumeListScreen()),
      GoRoute(path: AppRoutes.resumeBuilder, builder: (_, __) => const ResumeBuilderScreen()),
      GoRoute(path: AppRoutes.resumePreview, builder: (_, __) => const ResumePreviewScreen()),

      GoRoute(path: AppRoutes.ats, builder: (_, __) => const AtsCheckerScreen()),
      GoRoute(path: AppRoutes.coverLetter, builder: (_, __) => const CoverLetterScreen()),
      GoRoute(path: AppRoutes.linkedin, builder: (_, __) => const LinkedInScreen()),
      GoRoute(path: AppRoutes.interview, builder: (_, __) => const InterviewScreen()),
      GoRoute(path: AppRoutes.jobTracker, builder: (_, __) => const JobTrackerScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.privacy, builder: (_, __) => const LegalScreen(doc: LegalDoc.privacy)),
      GoRoute(path: AppRoutes.terms, builder: (_, __) => const LegalScreen(doc: LegalDoc.terms)),
      GoRoute(path: AppRoutes.subscription, builder: (_, __) => const SubscriptionScreen()),
      GoRoute(path: AppRoutes.paymentSuccess, builder: (_, __) => const PaymentSuccessScreen()),
      GoRoute(path: AppRoutes.paymentFailed, builder: (_, __) => const PaymentFailedScreen()),
    ],
  );
});

/// Bridges Riverpod auth changes into GoRouter's Listenable contract.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    _sub = ref.listen<AuthState>(authStateProvider, (_, __) => notifyListeners(), fireImmediately: false);
    ref.listen(onboardingCompleteProvider, (_, __) => notifyListeners(), fireImmediately: false);
  }
  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
