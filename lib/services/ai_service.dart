import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resume_data.dart';

/// Talks to YOUR backend (not the AI provider directly!) for two things:
///  1. Improving a single resume bullet point.
///  2. Parsing + improving a whole pasted-in resume into structured fields.
///
/// SECURITY NOTE: never call an AI API directly from a shipped mobile app
/// with a hard-coded API key — anyone can decompile the APK/IPA and pull
/// the key straight out of the binary. The fix is a tiny backend (Node +
/// Express, a Cloudflare Worker, or a Firebase Cloud Function) that holds
/// the key server-side and exposes the endpoints below. Point the URLs at
/// it once it exists.
///
/// Until that backend is built, this falls back to simple local mocks so
/// you can test the rest of the app end-to-end right away.
class AIService {
  static const String _improveUrl = 'https://YOUR-BACKEND-URL/improve-bullet';
  static const String _parseUrl = 'https://YOUR-BACKEND-URL/parse-resume';

  // Flip to false once your backend is live.
  static const bool _useMockFallback = true;

  /// Improves a single bullet point. [targetField], [targetJobTitle] and
  /// [priorities] come from the Goals step and let the AI tailor the
  /// rewrite (e.g. emphasize "Leadership" vs "Technical skills") instead of
  /// giving generic advice.
  Future<String> improveBulletPoint({
    required String original,
    String? role,
    String? company,
    String? targetField,
    String? targetJobTitle,
    List<String>? priorities,
  }) async {
    if (_useMockFallback) {
      await Future.delayed(const Duration(milliseconds: 600)); // simulate latency
      return _mockImprove(original);
    }

    final response = await http
        .post(
          Uri.parse(_improveUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'bullet': original,
            'role': role,
            'company': company,
            'targetField': targetField,
            'targetJobTitle': targetJobTitle,
            'priorities': priorities,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('AI service returned ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['improved'] as String;
  }

  /// Sends a pasted-in resume's raw text to AI and gets back structured,
  /// improved fields ready to drop into ResumeData.
  ///
  /// EXPECTED BACKEND RESPONSE SHAPE (your backend's job is to prompt the
  /// AI to return exactly this JSON):
  /// {
  ///   "personalInfo": {"fullName": "", "email": "", "phone": "",
  ///                     "location": "", "linkedIn": "", "summary": ""},
  ///   "education": [{"institution": "", "degree": "", "fieldOfStudy": "",
  ///                   "startDate": "", "endDate": ""}],
  ///   "experience": [{"company": "", "role": "", "location": "",
  ///                    "startDate": "", "endDate": "", "bullets": [""]}],
  ///   "skills": [""]
  /// }
  Future<ResumeData> parseResume(String rawText) async {
    if (_useMockFallback) {
      await Future.delayed(const Duration(milliseconds: 900));
      return _mockParseResume(rawText);
    }

    final response = await http
        .post(
          Uri.parse(_parseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'resumeText': rawText}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Resume parsing failed (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _resumeDataFromJson(json);
  }

  ResumeData _resumeDataFromJson(Map<String, dynamic> json) {
    final data = ResumeData();
    final pi = (json['personalInfo'] as Map?)?.cast<String, dynamic>() ?? {};
    data.personalInfo
      ..fullName = (pi['fullName'] ?? '').toString()
      ..email = (pi['email'] ?? '').toString()
      ..phone = (pi['phone'] ?? '').toString()
      ..location = (pi['location'] ?? '').toString()
      ..linkedIn = (pi['linkedIn'] ?? '').toString()
      ..summary = (pi['summary'] ?? '').toString();

    data.education = (json['education'] as List? ?? []).map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return Education(
        institution: (m['institution'] ?? '').toString(),
        degree: (m['degree'] ?? '').toString(),
        fieldOfStudy: (m['fieldOfStudy'] ?? '').toString(),
        startDate: (m['startDate'] ?? '').toString(),
        endDate: (m['endDate'] ?? '').toString(),
      );
    }).toList();

    data.experience = (json['experience'] as List? ?? []).map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return Experience(
        company: (m['company'] ?? '').toString(),
        role: (m['role'] ?? '').toString(),
        location: (m['location'] ?? '').toString(),
        startDate: (m['startDate'] ?? '').toString(),
        endDate: (m['endDate'] ?? '').toString(),
        bullets: (m['bullets'] as List? ?? ['']).map((b) => b.toString()).toList(),
      );
    }).toList();

    data.skills = (json['skills'] as List? ?? []).map((s) => s.toString()).toList();

    return data;
  }

  /// Placeholder "improvement" so the UX can be demoed before a real AI
  /// backend is wired up. Replace by setting _useMockFallback = false above.
  String _mockImprove(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final capitalized = trimmed[0].toUpperCase() + trimmed.substring(1);
    final endsWithPunctuation = capitalized.endsWith('.') || capitalized.endsWith('!');
    return '$capitalized${endsWithPunctuation ? '' : '.'} (AI-enhanced — connect a real backend for genuine rewrites)';
  }

  /// Best-effort placeholder parsing so the import flow is testable before
  /// a real backend exists. It can pull out an email/phone with regex and
  /// guesses the name is the first line, but it can't reliably split
  /// experience/education/skills without real AI — that content goes into
  /// a single "Imported content" entry for you to split manually for now.
  ResumeData _mockParseResume(String rawText) {
    final emailMatch = RegExp(r'[\w\.\-]+@[\w\.\-]+\.\w+').firstMatch(rawText);
    final phoneMatch = RegExp(r'(\+?\d[\d \-\(\)]{7,}\d)').firstMatch(rawText);
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final guessedName = lines.isNotEmpty ? lines.first : '';

    final data = ResumeData();
    data.personalInfo.fullName = guessedName;
    data.personalInfo.email = emailMatch?.group(0) ?? '';
    data.personalInfo.phone = phoneMatch?.group(0) ?? '';
    data.personalInfo.summary = 'Pasted resume detected (${lines.length} lines). Connect a real AI '
        'backend to automatically split this into Experience, Education, and Skills — for now '
        'it\'s dropped into the experience section below so nothing is lost; edit it manually '
        'on the next screens.';
    data.experience.add(Experience(
      role: 'Imported content (edit or delete me)',
      bullets: [rawText.length > 600 ? '${rawText.substring(0, 600)}...' : rawText],
    ));
    return data;
  }
}
