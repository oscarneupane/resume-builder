import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'supabase_service.dart';

/// Routes AI requests with a three-tier priority ("Both" mode):
///
///   1. Supabase Edge Function  — when Supabase is configured. Most secure;
///      the OpenAI key lives server-side and rate limiting is enforced.
///   2. Direct AI provider       — when a provider key is set in `.env`
///      (Gemini / OpenRouter / OpenAI, all OpenAI-compatible). Lets the app
///      produce real output during MVP/dev before the backend is deployed.
///      Free providers win over OpenAI. NOTE: the key ships inside the app, so
///      use this for testing only — production should rely on tier 1.
///   3. Deterministic mock       — when neither is available, so UI flows still work.
///
/// Edge routing: `atsCheck` → `ats-check`, `coverLetter` → `cover-letter`,
/// everything else → `ai-generate`.
class AiService {
  AiService._();
  static final instance = AiService._();

  String _endpointFor(AiFeature feature) => switch (feature) {
        AiFeature.atsCheck => AppConstants.fnAtsCheck,
        AiFeature.coverLetter => AppConstants.fnCoverLetter,
        _ => AppConstants.fnAiGenerate,
      };

  /// A non-empty, non-placeholder key from `.env`, or null.
  String? _key(String name) {
    try {
      final k = dotenv.env[name];
      if (k == null || k.trim().isEmpty) return null;
      final low = k.toLowerCase();
      if (low.startsWith('your-') || low.startsWith('sk-your') || low.contains('placeholder')) return null;
      return k.trim();
    } catch (_) {
      return null;
    }
  }

  /// The active "direct" AI provider, selected by which key is set in `.env`.
  /// All three speak the OpenAI chat-completions format. Free providers
  /// (Gemini, OpenRouter) are preferred so a free key takes over a
  /// quota-blocked OpenAI key without any code change.
  _AiProvider? get _provider {
    final gemini = _key('GEMINI_API_KEY');
    if (gemini != null) {
      return const _AiProvider('Gemini', 'https://generativelanguage.googleapis.com/v1beta/openai')
          .withKey(gemini, 'gemini-2.0-flash');
    }
    final openrouter = _key('OPENROUTER_API_KEY');
    if (openrouter != null) {
      return const _AiProvider('OpenRouter', 'https://openrouter.ai/api/v1')
          .withKey(openrouter, 'google/gemini-2.0-flash-exp:free');
    }
    final openai = _key('OPENAI_API_KEY');
    if (openai != null) {
      return const _AiProvider('OpenAI', 'https://api.openai.com/v1').withKey(openai, 'gpt-4o');
    }
    return null;
  }

  Future<AiResult> generate({
    required AiFeature feature,
    required Map<String, dynamic> context,
  }) async {
    // Tier 1 — secure Edge Function.
    if (SupabaseService.isConfigured) {
      return _viaEdgeFunction(feature, context);
    }
    // Tier 2 — direct AI provider (Gemini / OpenRouter / OpenAI).
    final provider = _provider;
    if (provider != null) {
      return _viaProvider(feature, context, provider);
    }
    // Tier 3 — mock.
    return AiResult.ok(_mockResponse(feature, context));
  }

  // ── Tier 1 ────────────────────────────────────────────────────────────────
  Future<AiResult> _viaEdgeFunction(AiFeature feature, Map<String, dynamic> context) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const AiResult.failure('Not signed in.');

    final url = dotenv.env['SUPABASE_URL'];
    final endpoint = Uri.parse('$url/functions/v1/${_endpointFor(feature)}');
    final isDedicated = feature == AiFeature.atsCheck || feature == AiFeature.coverLetter;
    final payload = isDedicated ? context : {'feature': feature.name, 'context': context};

    final res = await http.post(
      endpoint,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode == 429) {
      return const AiResult.failure(
        'Free plan limit reached (3/week). Upgrade to Pro for unlimited.',
        rateLimited: true,
      );
    }
    if (res.statusCode >= 400) {
      return AiResult.failure('AI request failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return AiResult.ok((body['result'] as String?) ?? '');
  }

  // ── Tier 2 ────────────────────────────────────────────────────────────────
  Future<AiResult> _viaProvider(AiFeature feature, Map<String, dynamic> context, _AiProvider p) async {
    final (prompt, wantsJson) = _buildPrompt(feature, context);
    try {
      final res = await http.post(
        Uri.parse('${p.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${p.key}',
          'Content-Type': 'application/json',
          // OpenRouter likes these for attribution (optional, harmless elsewhere).
          'HTTP-Referer': 'https://applymate.app',
          'X-Title': 'ApplyMate',
        },
        body: jsonEncode({
          'model': p.model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          if (wantsJson) 'response_format': {'type': 'json_object'},
        }),
      );

      if (res.statusCode == 401) {
        return AiResult.failure('${p.name} rejected the API key. Check your key in .env.');
      }
      if (res.statusCode == 429) {
        return AiResult.failure('${p.name} is rate-limited or out of quota. Try again shortly or switch provider.');
      }
      if (res.statusCode >= 400) {
        return AiResult.failure('${p.name} request failed (${res.statusCode}).');
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final content = (body['choices']?[0]?['message']?['content'] as String?)?.trim() ?? '';

      // Normalize list-style features to a bare JSON array string (client parses a List).
      if (feature == AiFeature.skillsSuggest || feature == AiFeature.interviewQuestions) {
        final key = feature == AiFeature.skillsSuggest ? 'skills' : 'questions';
        try {
          final parsed = jsonDecode(content);
          final list = parsed is List ? parsed : (parsed[key] ?? []);
          return AiResult.ok(jsonEncode(list));
        } catch (_) {
          return const AiResult.ok('[]');
        }
      }
      return AiResult.ok(content);
    } catch (e) {
      return AiResult.failure('${p.name} request error: $e');
    }
  }

  /// Dart-side prompt templates (mirror supabase/functions/_shared/openai.ts).
  (String, bool) _buildPrompt(AiFeature feature, Map<String, dynamic> c) {
    String s(String k) => (c[k] ?? '').toString();
    switch (feature) {
      case AiFeature.professionalSummary:
        return (
          'You are a professional resume writer.\n'
              'Write a 3-4 sentence professional summary for a resume.\n'
              'Job title: ${s('jobTitle')}\n'
              'Years of experience: ${s('yearsExp')}\n'
              'Top skills: ${s('skills')}\n'
              'Career goal: ${s('careerGoal')}\n'
              "Write in first person without using 'I'. Be specific and impactful. "
              'Return ONLY the summary text, no preamble.',
          false
        );
      case AiFeature.fullResume:
        return (
          'You are an expert resume writer and career coach.\n'
              'Using ONLY the candidate details below, produce a complete, polished, '
              'ATS-friendly resume. Improve the wording, write strong action-verb '
              'bullet points with quantified impact where plausible, group technical '
              'skills by category, and write concise one-line project descriptions.\n'
              'Do NOT invent employers, schools, job titles, dates, or contact details '
              'that are not present in the details — only enrich the wording around the '
              'real facts. If a section has no source data, return it empty.\n'
              'Target role: ${s('jobTitle')}\n'
              "${s('notes').isEmpty ? '' : 'Extra notes from the candidate: ${s('notes')}\n'}"
              'Candidate details:\n${s('details')}\n'
              'Return a JSON object with EXACTLY these keys: '
              '"personal" {"fullName","title","email","phone","location","linkedin","github","portfolio"}, '
              '"summary" (string, 3-4 sentences), '
              '"skills" (array of strings, each formatted as "Category: skill, skill, skill"), '
              '"projects" (array of {"name","description","link"}), '
              '"experience" (array of {"title","company","startDate","endDate","bullets":[string]}), '
              '"education" (array of {"degree","school","startDate","endDate"}). '
              'Use empty strings/arrays where unknown.',
          true
        );
      case AiFeature.bulletImprover:
        return (
          'You are an expert resume writer.\n'
              'Rewrite this resume bullet point to be more impactful. Use strong action '
              'verbs and quantify results where possible.\n'
              'Original: ${s('bullet')}\n'
              'Job title: ${s('jobTitle')}\n'
              'Return ONLY the improved bullet point. No explanations.',
          false
        );
      case AiFeature.atsCheck:
        return (
          'You are an ATS expert. Analyze this resume against the job description.\n'
              'RESUME: ${s('resumeText')}\n'
              'JOB DESCRIPTION: ${s('jobDescription')}\n'
              'Return a JSON object with these exact keys: '
              '"score" (number 0-100), "matching_keywords" (string[]), '
              '"missing_keywords" (string[]), "weak_sections" (string[]), '
              '"suggestions" (array of { "section", "issue", "fix" }).',
          true
        );
      case AiFeature.coverLetter:
        final bg = s('background');
        return (
          'You are a professional cover letter writer.\n'
              'Write a ${s('tone')} cover letter for:\n'
              'Job Title: ${s('jobTitle')}\n'
              'Company: ${s('companyName')}\n'
              'Applicant skills: ${s('skills')}\n'
              'Job Description: ${s('jobDescription')}\n'
              '${bg.isEmpty ? '' : 'Applicant background (use real details from this, do not invent):\n$bg\n'}'
              'Return a JSON object with keys: full_letter, short_email, recruiter_msg.',
          true
        );
      case AiFeature.linkedinHeadline:
        return (
          'Write 3 punchy LinkedIn headline options (max 120 chars each) for a '
              '${s('jobTitle')} with ${s('yearsExp')} years of experience.\n'
              'Skills: ${s('skills')}\n'
              'Return each headline on its own line, no numbering or quotes.',
          false
        );
      case AiFeature.linkedinAbout:
        return (
          'Write a compelling LinkedIn About section.\n'
              'Name: ${s('name')} | Job Title: ${s('jobTitle')}\n'
              'Skills: ${s('skills')} | Career Goal: ${s('goal')}\n'
              'Max 300 words. Professional tone. First person.',
          false
        );
      case AiFeature.recruiterMessage:
        return (
          'Write a short, friendly cold outreach message to a recruiter (max 90 '
              'words) from a ${s('jobTitle')} with ${s('yearsExp')} years of experience.\n'
              'Skills: ${s('skills')}\n'
              'Polite, specific, and easy to reply to. Return only the message.',
          false
        );
      case AiFeature.interviewQuestions:
        return (
          'Generate 10 realistic interview questions for a ${s('jobTitle')} role'
              '${s('experienceLevel').isEmpty ? '' : ' (${s('experienceLevel')} level)'}.\n'
              'Mix behavioral, technical, and role-specific.\n'
              'Return a JSON object with a single key "questions" whose value is an array of 10 strings.',
          true
        );
      case AiFeature.interviewAnswer:
        return (
          'Generate a STAR-method interview answer.\n'
              'Question: ${s('question')}\n'
              'Job Title: ${s('jobTitle')}\n'
              'My Experience: ${s('experience')}\n'
              'Format as: Situation: ...\nTask: ...\nAction: ...\nResult: ...',
          false
        );
      case AiFeature.interviewFeedback:
        return (
          'You are an experienced interview coach. Score and critique the '
              "candidate's answer to an interview question.\n"
              'Question: ${s('question')}\n'
              'Job title: ${s('jobTitle')}\n'
              "Candidate's answer: ${s('answer')}\n"
              'Return a JSON object with EXACTLY these keys: '
              '"score" (number 0-100), '
              '"summary" (string, one or two sentences of overall feedback), '
              '"strengths" (array of short strings), '
              '"improvements" (array of short, specific, actionable strings).',
          true
        );
      case AiFeature.skillsSuggest:
        return (
          'Suggest 10 relevant resume skills for the job title: ${s('jobTitle')}.\n'
              'Return a JSON object with a single key "skills" whose value is an array of strings.',
          true
        );
    }
  }

  // ── Tier 3 ────────────────────────────────────────────────────────────────
  String _mockResponse(AiFeature feature, Map<String, dynamic> ctx) {
    switch (feature) {
      case AiFeature.professionalSummary:
        final title = ctx['jobTitle'] ?? 'professional';
        return 'Results-driven $title with a track record of delivering measurable impact. '
            'Skilled at collaborating across teams, simplifying complex problems, and shipping '
            'production-quality work. Eager to bring strong technical fundamentals and a growth '
            'mindset to a high-performing team.';
      case AiFeature.fullResume:
        final title = (ctx['jobTitle'] ?? 'Professional').toString();
        return jsonEncode({
          'personal': {
            'fullName': '',
            'title': title,
            'email': '',
            'phone': '',
            'location': '',
            'linkedin': '',
            'github': '',
            'portfolio': '',
          },
          'summary': 'Motivated $title with hands-on experience and a track record of delivering '
              'measurable results. Combines strong fundamentals with clear communication and a '
              'bias for shipping. Seeking to bring reliable, high-quality work to a growing team.',
          'skills': [
            'Core: Problem solving, Communication, Teamwork',
            'Tools: Git, Excel, Project management',
          ],
          'projects': [
            {'name': 'Sample Project', 'description': 'Built and shipped a small end-to-end project demonstrating core skills.', 'link': ''},
          ],
          'experience': [
            {
              'title': title,
              'company': 'Recent role',
              'startDate': '2024',
              'endDate': 'Present',
              'bullets': [
                'Delivered key tasks on time, improving team output by an estimated 20%.',
                'Collaborated across functions to resolve issues and streamline workflows.',
              ],
            },
          ],
          'education': [
            {'degree': 'Relevant qualification', 'school': 'University', 'startDate': '', 'endDate': '2024'},
          ],
        });
      case AiFeature.bulletImprover:
        final original = (ctx['bullet'] ?? '').toString();
        return original.isEmpty
            ? 'Spearheaded a cross-functional initiative that reduced cycle time by 28% in one quarter.'
            : 'Improved: $original — now with stronger action verb and quantified result (e.g. 25%).';
      case AiFeature.atsCheck:
        return jsonEncode({
          'score': 72,
          'matching_keywords': ['flutter', 'rest api', 'agile'],
          'missing_keywords': ['kubernetes', 'graphql'],
          'weak_sections': ['summary'],
          'suggestions': [
            {'section': 'summary', 'issue': 'Too generic', 'fix': 'Lead with role + years of experience.'}
          ]
        });
      case AiFeature.coverLetter:
        return jsonEncode({
          'full_letter': 'Dear Hiring Manager,\n\n[Generated cover letter draft]\n\nSincerely,',
          'short_email': 'Hi — quick note to express interest in the role...',
          'recruiter_msg': 'Hi {recruiter}, saw the role — would love to chat.',
        });
      case AiFeature.linkedinHeadline:
        return 'Software Engineer | Flutter & Dart | Building delightful mobile apps\n'
            'Mobile Developer turning ideas into shipped products\n'
            'Engineer • Problem solver • Lifelong learner';
      case AiFeature.linkedinAbout:
        return 'Builder, learner, shipper. I help teams turn ambiguous problems into clear plans...';
      case AiFeature.recruiterMessage:
        return 'Hi {recruiter}, I came across the {role} opening and it lines up well with my '
            'experience in {skills}. I would love to learn more — open to a quick chat this week?';
      case AiFeature.interviewQuestions:
        return jsonEncode([
          'Tell me about yourself and your background.',
          'Why are you interested in this role?',
          'Describe a challenging project and how you handled it.',
          'How do you prioritise competing deadlines?',
          'Tell me about a time you disagreed with a teammate.',
          'What is your greatest professional achievement?',
          'How do you stay current in your field?',
          'Describe a time you failed and what you learned.',
          'How do you handle feedback?',
          'Where do you see yourself in five years?',
        ]);
      case AiFeature.interviewAnswer:
        return 'Situation: Briefly set the context.\n'
            'Task: What you needed to achieve.\n'
            'Action: The specific steps you took.\n'
            'Result: The measurable outcome.';
      case AiFeature.interviewFeedback:
        return jsonEncode({
          'score': 78,
          'summary': 'Solid, relevant answer with a clear example — tighten the structure and quantify the result.',
          'strengths': ['Stayed on topic', 'Used a concrete example'],
          'improvements': [
            'Open with the situation in one sentence so the listener has context.',
            'Quantify the outcome (e.g. “cut response time 30%”).',
            'End by linking the result back to the role you are applying for.',
          ],
        });
      case AiFeature.skillsSuggest:
        return jsonEncode(['Communication', 'Problem solving', 'Leadership', 'Adaptability']);
    }
  }

  // ── Extraction (upload → AI scan) ───────────────────────────────────────────

  /// Scan a source into a concise plain-text summary (stored on a Material and
  /// reused as generation context).
  Future<AiResult> scanToSummary({Uint8List? imageBytes, Uint8List? pdfBytes, String? text}) {
    return _extract(
      imageBytes: imageBytes,
      pdfBytes: pdfBytes,
      text: text,
      structured: false,
      prompt: 'Extract the key professional information from this document as clean, '
          'concise plain text: full name, contact details, job titles & companies with '
          'dates, education, and skills. Be faithful to the source and do NOT invent '
          'anything. If a section is absent, omit it.',
    );
  }

  /// Scan a source into structured resume JSON used to pre-fill the builder.
  Future<AiResult> scanToResume({Uint8List? imageBytes, Uint8List? pdfBytes, String? text}) {
    return _extract(
      imageBytes: imageBytes,
      pdfBytes: pdfBytes,
      text: text,
      structured: true,
      prompt: 'Extract resume data from this document as a JSON object with EXACTLY these keys: '
          '"personal" {"fullName","title","email","phone","location","linkedin"}, '
          '"summary" (string), '
          '"experience" (array of {"title","company","startDate","endDate","bullets":[string]}), '
          '"education" (array of {"degree","school","startDate","endDate"}), '
          '"skills" (array of strings). '
          'Use empty strings/arrays where unknown. Do NOT invent information.',
    );
  }

  /// Scan a job posting (screenshot/photo/PDF/pasted text) into structured
  /// fields used to pre-fill the cover-letter builder. The applicant's own
  /// details are supplied separately (saved Materials / profile).
  Future<AiResult> scanJobPost({Uint8List? imageBytes, Uint8List? pdfBytes, String? text}) {
    return _extract(
      imageBytes: imageBytes,
      pdfBytes: pdfBytes,
      text: text,
      structured: true,
      prompt: 'Extract the job posting details from this document/image as a JSON object with '
          'EXACTLY these keys: "jobTitle" (string), "companyName" (string), '
          '"jobDescription" (string — a concise summary of the role’s responsibilities and '
          'requirements), "keySkills" (array of strings — the most important skills/keywords). '
          'Use empty strings/arrays where unknown. Do NOT invent details.',
      mock: _mockJobScan,
    );
  }

  Future<AiResult> _extract({
    Uint8List? imageBytes,
    Uint8List? pdfBytes,
    String? text,
    required String prompt,
    required bool structured,
    String? mock,
  }) async {
    // PDFs are rasterized to an image so the vision model can read them.
    Uint8List? image = imageBytes;
    if (image == null && pdfBytes != null) {
      image = await _pdfFirstPagePng(pdfBytes);
    }

    if (SupabaseService.isConfigured) {
      return _extractViaEdge(prompt: prompt, image: image, text: text, structured: structured);
    }
    final provider = _provider;
    if (provider != null) {
      return _extractViaProvider(prompt: prompt, image: image, text: text, structured: structured, provider: provider);
    }
    return AiResult.ok(mock ?? _mockExtraction(structured));
  }

  String get _mockJobScan => jsonEncode({
        'jobTitle': 'IT Support Officer',
        'companyName': 'Northwind Technologies',
        'jobDescription': 'Provide first-line technical support, troubleshoot hardware and '
            'software issues, administer Active Directory accounts, and maintain Windows '
            'devices. Looking for strong communication and a customer-first mindset.',
        'keySkills': ['Help Desk', 'Active Directory', 'Windows', 'Troubleshooting', 'Customer service'],
      });

  Future<Uint8List?> _pdfFirstPagePng(Uint8List pdf) async {
    try {
      await for (final page in Printing.raster(pdf, pages: [0], dpi: 150)) {
        return page.toPng();
      }
    } catch (_) {/* fall through */}
    return null;
  }

  Future<AiResult> _extractViaEdge({
    required String prompt,
    Uint8List? image,
    String? text,
    required bool structured,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const AiResult.failure('Not signed in.');
    final url = dotenv.env['SUPABASE_URL'];
    final endpoint = Uri.parse('$url/functions/v1/${AppConstants.fnAiExtract}');
    final res = await http.post(
      endpoint,
      headers: {'Authorization': 'Bearer ${session.accessToken}', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'structured': structured,
        if (image != null) 'image': base64Encode(image),
        if (text != null && text.trim().isNotEmpty) 'text': text,
      }),
    );
    if (res.statusCode == 429) {
      return const AiResult.failure('Free plan limit reached (3/week). Upgrade to Pro.', rateLimited: true);
    }
    if (res.statusCode >= 400) return AiResult.failure('Scan failed (${res.statusCode})');
    return AiResult.ok((jsonDecode(res.body)['result'] as String?) ?? '');
  }

  Future<AiResult> _extractViaProvider({
    required String prompt,
    Uint8List? image,
    String? text,
    required bool structured,
    required _AiProvider provider,
  }) async {
    final content = <Map<String, dynamic>>[
      {'type': 'text', 'text': text == null || text.trim().isEmpty ? prompt : '$prompt\n\nSOURCE:\n$text'},
      if (image != null)
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/png;base64,${base64Encode(image)}'},
        },
    ];
    try {
      final res = await http.post(
        Uri.parse('${provider.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${provider.key}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://applymate.app',
          'X-Title': 'ApplyMate',
        },
        body: jsonEncode({
          'model': provider.model,
          'messages': [
            {'role': 'user', 'content': content}
          ],
          if (structured) 'response_format': {'type': 'json_object'},
        }),
      );
      if (res.statusCode == 401) {
        return AiResult.failure('${provider.name} rejected the API key. Check your key in .env.');
      }
      if (res.statusCode >= 400) return AiResult.failure('Scan failed (${provider.name} ${res.statusCode}).');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final out = (body['choices']?[0]?['message']?['content'] as String?)?.trim() ?? '';
      return AiResult.ok(out);
    } catch (e) {
      return AiResult.failure('Scan error: $e');
    }
  }

  String _mockExtraction(bool structured) {
    if (!structured) {
      return 'Alex Doe — Senior Product Designer\n'
          'alex.doe@example.com • Sydney, AU\n'
          'Experience: Product Designer at Northwind (2021–present); Designer at Acme (2018–2021).\n'
          'Education: BDes, UNSW (2018).\n'
          'Skills: Figma, design systems, user research, prototyping.';
    }
    return jsonEncode({
      'personal': {
        'fullName': 'Alex Doe',
        'title': 'Senior Product Designer',
        'email': 'alex.doe@example.com',
        'phone': '0400 000 000',
        'location': 'Sydney, AU',
        'linkedin': 'in/alexdoe',
      },
      'summary': 'Product designer with 6+ years crafting accessible, data-informed experiences.',
      'experience': [
        {
          'title': 'Senior Product Designer',
          'company': 'Northwind',
          'startDate': '2021',
          'endDate': 'Present',
          'bullets': ['Led the design system used across 4 squads', 'Raised activation 18% via onboarding redesign'],
        },
      ],
      'education': [
        {'degree': 'BDes', 'school': 'UNSW', 'startDate': '2014', 'endDate': '2018'},
      ],
      'skills': ['Figma', 'Design systems', 'User research', 'Prototyping'],
    });
  }
}

class AiResult {
  final String? text;
  final String? error;
  final bool rateLimited;

  const AiResult._(this.text, this.error, this.rateLimited);
  const AiResult.ok(String text) : this._(text, null, false);
  const AiResult.failure(String error, {bool rateLimited = false}) : this._(null, error, rateLimited);

  bool get isOk => error == null;
}

/// A "direct" AI provider that speaks the OpenAI chat-completions format
/// (OpenAI, OpenRouter, or Gemini's OpenAI-compatible endpoint).
class _AiProvider {
  final String name;
  final String baseUrl;
  final String key;
  final String model;
  const _AiProvider(this.name, this.baseUrl, {this.key = '', this.model = ''});

  _AiProvider withKey(String key, String model) => _AiProvider(name, baseUrl, key: key, model: model);
}
