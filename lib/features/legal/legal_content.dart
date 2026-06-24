/// Ownership / legal attribution for the Privacy Policy and Terms.
///
/// EDIT THESE to your real details before publishing to the stores.
class LegalInfo {
  static const ownerName = 'ApplyMate';
  static const appName = 'ApplyMate';
  static const contactEmail = 'support@applymate.app'; // <-- change to your support email
  static const effectiveDate = '18 June 2026';
  static const governingLocation = 'Australia';
}

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}

/// Privacy Policy — plain-language, store-submission friendly. Reviewed text,
/// but not legal advice; have it checked before a production launch.
const privacyPolicySections = <LegalSection>[
  LegalSection(
    'Overview',
    '${LegalInfo.appName} ("we", "us", "our") is owned and operated by ${LegalInfo.ownerName}. '
        'This Privacy Policy explains what we collect, why, and how we handle it when you use the app. '
        'Effective ${LegalInfo.effectiveDate}.',
  ),
  LegalSection(
    'Information we collect',
    'Account details you provide (name, username, email). Content you create or upload — resumes, '
        'cover letters, job applications, and files you add to Materials. Basic usage information needed '
        'to operate features (for example, AI generation counts used for rate limiting).',
  ),
  LegalSection(
    'How we use your information',
    'To provide the app’s features: building documents, AI generation, ATS checks, and storage. '
        'We use your content only to deliver the result you asked for. We do not sell your data, and we do '
        'not use your resume content to train AI models.',
  ),
  LegalSection(
    'AI processing',
    'When you use an AI feature, the relevant content is sent to our AI provider (Google’s Gemini API) '
        'solely to generate your result. We log only usage counts for rate limiting — not the content of your '
        'requests.',
  ),
  LegalSection(
    'Storage & security',
    'Your data is stored with our backend provider (Supabase) and protected with row-level security so '
        'you can only access your own data. Files are kept in per-user private storage. Sensitive keys are '
        'never stored in the app.',
  ),
  LegalSection(
    'Your choices & rights',
    'You can edit or delete your documents at any time. You can export your data and permanently delete '
        'your account from Settings, which removes your associated records.',
  ),
  LegalSection(
    'Contact',
    'Questions about this policy? Contact ${LegalInfo.ownerName} at ${LegalInfo.contactEmail}.',
  ),
];

/// Terms of Service.
const termsSections = <LegalSection>[
  LegalSection(
    'Acceptance of terms',
    'By using ${LegalInfo.appName}, owned and operated by ${LegalInfo.ownerName}, you agree to these Terms. '
        'If you do not agree, please do not use the app. Effective ${LegalInfo.effectiveDate}.',
  ),
  LegalSection(
    'Your account',
    'You are responsible for your account and for the accuracy of the information you provide. Keep your '
        'login credentials secure.',
  ),
  LegalSection(
    'Acceptable use',
    'Use the app lawfully. Do not upload content you do not have the right to use, and do not attempt to '
        'disrupt or reverse-engineer the service.',
  ),
  LegalSection(
    'Your content',
    'You own the content you create and upload. You grant us a limited licence to process it only to '
        'provide the app’s features to you.',
  ),
  LegalSection(
    'AI-generated content',
    'AI output is provided as a draft to assist you. You are responsible for reviewing it for accuracy '
        'before using it in real applications. We do not guarantee any particular hiring outcome.',
  ),
  LegalSection(
    'Cost',
    'ApplyMate is currently free to use. There are no in-app purchases or subscriptions.',
  ),
  LegalSection(
    'Disclaimer & liability',
    'The app is provided "as is" without warranties. To the extent permitted by law, ${LegalInfo.ownerName} '
        'is not liable for indirect or consequential loss arising from use of the app.',
  ),
  LegalSection(
    'Governing law',
    'These Terms are governed by the laws of ${LegalInfo.governingLocation}.',
  ),
  LegalSection(
    'Contact',
    'Questions about these Terms? Contact ${LegalInfo.ownerName} at ${LegalInfo.contactEmail}.',
  ),
];
