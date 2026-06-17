/// Static configuration for the app.
/// Anything sourced from environment goes through dotenv (see services/supabase_service).
class AppConstants {
  static const appName = 'ApplyMate';
  static const appTagline = 'Smart Documents. Better Applications. More Confidence.';

  // Plan limits — Part A3
  static const freeWeeklyAiGenerations = 3;
  static const freeMaxResumes = 1;
  static const freeMaxDocuments = 2;

  // Edge function paths (appended to SUPABASE_URL/functions/v1/)
  static const fnAiGenerate = 'ai-generate';
  static const fnAtsCheck = 'ats-check';
  static const fnCoverLetter = 'cover-letter';
  static const fnCreateCheckout = 'create-checkout';

  // Local storage keys
  static const prefHasOnboarded = 'has_onboarded';
  static const prefOnboardingPayload = 'onboarding_payload';

  // Resume templates
  static const defaultTemplate = 'classic';
  static const availableTemplates = ['classic', 'modern', 'minimal'];

  // ATS thresholds
  static const atsThresholdGood = 75;
  static const atsThresholdMid = 50;
}

/// Plan tiers.
enum Plan { free, pro }

/// AI features that go through the rate-limited edge function.
enum AiFeature {
  professionalSummary,
  bulletImprover,
  atsCheck,
  coverLetter,
  linkedinHeadline,
  linkedinAbout,
  recruiterMessage,
  interviewAnswer,
  skillsSuggest,
}

/// Career-experience buckets used during onboarding (matches DB CHECK).
enum ExperienceLevel { entry, junior, mid, senior, executive }

extension ExperienceLevelX on ExperienceLevel {
  String get label => switch (this) {
        ExperienceLevel.entry => 'Entry',
        ExperienceLevel.junior => 'Junior',
        ExperienceLevel.mid => 'Mid',
        ExperienceLevel.senior => 'Senior',
        ExperienceLevel.executive => 'Executive',
      };

  String get value => name;
}
