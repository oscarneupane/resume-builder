import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'supabase_service.dart';

/// Multi-provider AI routing with automatic fallback.
///
/// Priority chain (first available key wins):
///   1. Supabase Edge Functions — production path, keys stored as Supabase secrets.
///   2. Claude (Anthropic)     — claude-haiku-4-5, best quality.
///   3. DeepSeek               — deepseek-chat, free tier, OpenAI-compatible.
///   4. Groq                   — llama-3.1-8b-instant, free & fast.
///   5. Gemini                 — gemini-2.0-flash, Google free tier.
///   6. Mock                   — deterministic offline fallback.
///
/// Set keys in your .env file (see .env.example).
/// For production: store keys as Supabase Edge Function secrets — never ship
/// AI provider keys inside the mobile bundle.
class AiService {
  AiService._();
  static final instance = AiService._();

  // ── Key helpers ────────────────────────────────────────────────────────────

  String? get _claudeKey   => _key('CLAUDE_API_KEY');
  String? get _deepseekKey => _key('DEEPSEEK_API_KEY');
  String? get _groqKey     => _key('GROQ_API_KEY');
  String? get _geminiKey   => _key('GEMINI_API_KEY');

  String? _key(String name) {
    final v = dotenv.env[name];
    return (v == null || v.isEmpty || v.startsWith('your-')) ? null : v;
  }

  String _endpointFor(AiFeature feature) => switch (feature) {
        AiFeature.atsCheck    => AppConstants.fnAtsCheck,
        AiFeature.coverLetter => AppConstants.fnCoverLetter,
        _                     => AppConstants.fnAiPlan,
      };

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<AiResult> generate({
    required AiFeature feature,
    required Map<String, dynamic> context,
  }) async {
    // 1. Supabase Edge Functions (production)
    if (SupabaseService.isConfigured) {
      final r = await _viaEdgeFunction(feature, context);
      if (r.isOk) return r;
    }

    final (prompt, wantsJson) = _buildPrompt(feature, context);

    // 2. Claude (Anthropic)
    if (_claudeKey != null) {
      final r = await _viaClaude(prompt, wantsJson, _claudeKey!);
      if (r.isOk) return r;
    }

    // 3. DeepSeek (Chinese free API, OpenAI-compatible)
    if (_deepseekKey != null) {
      final r = await _viaOpenAICompat(
        prompt, wantsJson, _deepseekKey!,
        baseUrl: 'https://api.deepseek.com',
        model: 'deepseek-chat',
        provider: 'DeepSeek',
      );
      if (r.isOk) return r;
    }

    // 4. Groq (free, OpenAI-compatible)
    if (_groqKey != null) {
      final r = await _viaOpenAICompat(
        prompt, wantsJson, _groqKey!,
        baseUrl: 'https://api.groq.com/openai',
        model: 'llama-3.1-8b-instant',
        provider: 'Groq',
      );
      if (r.isOk) return r;
    }

    // 5. Gemini (Google free tier)
    if (_geminiKey != null) {
      final r = await _viaGemini(prompt, _geminiKey!);
      if (r.isOk) return r;
    }

    // 6. Mock fallback
    return AiResult.ok(_mockResponse(feature, context));
  }

  // ── Tier 1 — Supabase Edge Functions ──────────────────────────────────────

  Future<AiResult> _viaEdgeFunction(
      AiFeature feature, Map<String, dynamic> context) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const AiResult.failure('Not signed in.');

    final url = dotenv.env['SUPABASE_URL'];
    final endpoint =
        Uri.parse('$url/functions/v1/${_endpointFor(feature)}');
    final isDedicated =
        feature == AiFeature.atsCheck || feature == AiFeature.coverLetter;
    final payload =
        isDedicated ? context : {'feature': feature.name, 'context': context};

    try {
      final res = await http
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 429) {
        return const AiResult.failure(
          'Free plan limit reached (3/week). Upgrade to Pro for unlimited.',
          rateLimited: true,
        );
      }
      if (res.statusCode >= 400) {
        final detail = res.body.isEmpty ? '' : ': ${res.body}';
        return AiResult.failure('Edge function error (${res.statusCode})$detail');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return AiResult.ok((body['result'] as String?) ?? '');
    } catch (e) {
      return AiResult.failure('Edge function unavailable: $e');
    }
  }

  // ── Tier 2a — Claude (Anthropic) ──────────────────────────────────────────

  Future<AiResult> _viaClaude(
      String prompt, bool wantsJson, String apiKey) async {
    try {
      final body = {
        'model': 'claude-haiku-4-5',
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      };

      final res = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 401) {
        return const AiResult.failure('Claude: invalid API key. Check CLAUDE_API_KEY in .env.');
      }
      if (res.statusCode == 429) {
        return const AiResult.failure('Claude: rate limit hit.', rateLimited: true);
      }
      if (res.statusCode >= 400) {
        return AiResult.failure('Claude error (${res.statusCode})');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (data['content'] as List?)
          ?.whereType<Map>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String)
          .join('') ?? '';
      return AiResult.ok(text.trim());
    } catch (e) {
      return AiResult.failure('Claude unavailable: $e');
    }
  }

  // ── Tier 2b — OpenAI-compatible (DeepSeek / Groq) ─────────────────────────

  Future<AiResult> _viaOpenAICompat(
    String prompt,
    bool wantsJson,
    String apiKey, {
    required String baseUrl,
    required String model,
    required String provider,
  }) async {
    try {
      final body = <String, dynamic>{
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 1024,
        if (wantsJson) 'response_format': {'type': 'json_object'},
      };

      final res = await http
          .post(
            Uri.parse('$baseUrl/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 401) {
        return AiResult.failure(
            '$provider: invalid API key. Check ${provider.toUpperCase()}_API_KEY in .env.');
      }
      if (res.statusCode == 429) {
        return AiResult.failure('$provider: rate limit hit.', rateLimited: true);
      }
      if (res.statusCode >= 400) {
        return AiResult.failure('$provider error (${res.statusCode}): ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (data['choices'] as List?)
              ?.firstOrNull?['message']?['content'] as String? ?? '';
      return AiResult.ok(text.trim());
    } catch (e) {
      return AiResult.failure('$provider unavailable: $e');
    }
  }

  // ── Tier 2d — Gemini (Google) ─────────────────────────────────────────────

  Future<AiResult> _viaGemini(String prompt, String apiKey) async {
    try {
      const model = 'gemini-2.0-flash';
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7},
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 400) {
        return const AiResult.failure('Gemini: invalid request or API key.');
      }
      if (res.statusCode == 429) {
        return const AiResult.failure('Gemini: rate limit hit.', rateLimited: true);
      }
      if (res.statusCode >= 400) {
        return AiResult.failure('Gemini error (${res.statusCode})');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (data['candidates'] as List?)
              ?.firstOrNull?['content']?['parts']
              ?.firstOrNull?['text'] as String? ??
          '';
      return AiResult.ok(text.trim());
    } catch (e) {
      return AiResult.failure('Gemini unavailable: $e');
    }
  }

  // ── Prompt builder ─────────────────────────────────────────────────────────

  (String prompt, bool wantsJson) _buildPrompt(
      AiFeature feature, Map<String, dynamic> ctx) {
    switch (feature) {
      case AiFeature.professionalSummary:
        return (
          'Write a concise 3-sentence professional resume summary for a '
          '${ctx['jobTitle'] ?? 'professional'}. Skills: ${ctx['skills'] ?? ''}. '
          'Start with a strong action phrase. Be specific. No fluff.',
          false,
        );

      case AiFeature.bulletImprover:
        return (
          'Rewrite this resume bullet point to be stronger, more quantified, '
          'and ATS-friendly. Return ONLY the improved bullet, no explanation.\n'
          'Original: ${ctx['bullet']}',
          false,
        );

      case AiFeature.atsCheck:
        return (
          'You are an ATS expert. Analyse this resume against the job description '
          'and return a JSON object with EXACTLY these keys: '
          '"score" (int 0-100), '
          '"matching_keywords" (string array), '
          '"missing_keywords" (string array), '
          '"weak_sections" (string array), '
          '"suggestions" (array of {"section","issue","fix"}). '
          'Resume: ${ctx['resumeText']}\n'
          'Job Description: ${ctx['jobDescription']}',
          true,
        );

      case AiFeature.coverLetter:
        return (
          'Write a professional cover letter for the role of ${ctx['jobTitle'] ?? 'this position'} '
          'at ${ctx['company'] ?? 'the company'}. '
          'Tone: ${ctx['tone'] ?? 'professional'}. '
          'Background: ${ctx['background'] ?? ''}. '
          'Return a JSON object with keys: "full_letter", "short_email", "recruiter_msg".',
          true,
        );

      case AiFeature.linkedinHeadline:
        return (
          'Write 3 LinkedIn headline options for a ${ctx['jobTitle'] ?? 'professional'}. '
          'Each should be under 120 characters, keyword-rich, and compelling. '
          'Return each on its own line, no numbering.',
          false,
        );

      case AiFeature.linkedinAbout:
        return (
          'Write a LinkedIn About section (first-person, 3 paragraphs) for a '
          '${ctx['jobTitle'] ?? 'professional'} with background: ${ctx['background'] ?? ''}. '
          'Make it engaging, keyword-rich, and end with a call to action.',
          false,
        );

      case AiFeature.recruiterMessage:
        return (
          'Write a short, friendly LinkedIn recruiter outreach message (under 300 chars) '
          'for a ${ctx['jobTitle'] ?? 'professional'} interested in ${ctx['role'] ?? 'this role'}. '
          'Include placeholders {recruiter} and {company}.',
          false,
        );

      case AiFeature.interviewQuestions:
        return (
          'Generate 10 realistic interview questions for the role of '
          '${ctx['jobTitle'] ?? 'professional'}. Mix behavioural and technical. '
          'Return as a JSON array of strings.',
          true,
        );

      case AiFeature.interviewAnswer:
        return (
          'Write a strong STAR-method answer to this interview question: "${ctx['question']}". '
          'Keep it concise (under 200 words). Role: ${ctx['jobTitle'] ?? 'professional'}.',
          false,
        );

      case AiFeature.skillsSuggest:
        return (
          'List 8 in-demand skills for the role of ${ctx['jobTitle'] ?? 'professional'}. '
          'Return as a JSON array of short skill strings (2-4 words max each).',
          true,
        );
    }
  }

  // ── Tier 5 — Mock (offline fallback) ─────────────────────────────────────

  String _mockResponse(AiFeature feature, Map<String, dynamic> ctx) {
    switch (feature) {
      case AiFeature.professionalSummary:
        final title = ctx['jobTitle'] ?? 'professional';
        return 'Results-driven $title with a track record of delivering measurable impact. '
            'Skilled at collaborating across teams, simplifying complex problems, and shipping '
            'production-quality work. Eager to bring strong technical fundamentals and a growth '
            'mindset to a high-performing team.';

      case AiFeature.bulletImprover:
        final original = (ctx['bullet'] ?? '').toString();
        return original.isEmpty
            ? 'Spearheaded a cross-functional initiative that reduced cycle time by 28% in one quarter.'
            : 'Improved: $original — with stronger action verb and quantified result (e.g. +25%).';

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
          'recruiter_msg': 'Hi {recruiter}, saw the role at {company} — would love to chat.',
        });

      case AiFeature.linkedinHeadline:
        return 'Software Engineer | Flutter & Dart | Building delightful mobile apps\n'
            'Mobile Developer turning ideas into shipped products\n'
            'Engineer • Problem solver • Lifelong learner';

      case AiFeature.linkedinAbout:
        return 'Builder, learner, shipper. I help teams turn ambiguous problems into clear plans '
            'and great products.\n\nWith experience across mobile and web, I bring technical depth '
            'and product thinking to every project.\n\nAlways open to interesting conversations — '
            'feel free to connect.';

      case AiFeature.recruiterMessage:
        return 'Hi {recruiter}, I came across the {role} opening at {company} and it lines up '
            'well with my experience. Would love to learn more — open for a quick chat?';

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

      case AiFeature.skillsSuggest:
        return jsonEncode(['Communication', 'Problem solving', 'Leadership', 'Adaptability',
            'Project management', 'Data analysis', 'Team collaboration', 'Critical thinking']);
    }
  }

  // ── Document extraction (resume import) ────────────────────────────────────

  Future<AiResult> scanToSummary(
      {Uint8List? imageBytes, Uint8List? pdfBytes, String? text}) {
    return _extract(
      imageBytes: imageBytes,
      pdfBytes: pdfBytes,
      text: text,
      structured: false,
      prompt: 'Extract the key professional information from this document as clean, '
          'concise plain text: full name, contact details, job titles & companies with '
          'dates, education, and skills. Be faithful to the source. Do NOT invent anything.',
    );
  }

  Future<AiResult> scanToResume(
      {Uint8List? imageBytes, Uint8List? pdfBytes, String? text}) {
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

  Future<AiResult> _extract({
    Uint8List? imageBytes,
    Uint8List? pdfBytes,
    String? text,
    required String prompt,
    required bool structured,
  }) async {
    Uint8List? image = imageBytes;
    if (image == null && pdfBytes != null) {
      image = await _pdfFirstPagePng(pdfBytes);
    }

    if (SupabaseService.isConfigured) {
      final r = await _extractViaEdge(
          prompt: prompt, image: image, text: text, structured: structured);
      if (r.isOk) return r;
    }

    // Direct Claude vision fallback (supports image input)
    if (_claudeKey != null && image != null) {
      final r = await _extractViaClaude(
          prompt: prompt, image: image, apiKey: _claudeKey!);
      if (r.isOk) return r;
    }

    // Text-only fallback via any provider
    if (text != null && text.trim().isNotEmpty) {
      return generate(
        feature: AiFeature.professionalSummary,
        context: {'jobTitle': 'professional', 'text': text},
      );
    }

    return AiResult.ok(_mockExtraction(structured));
  }

  Future<Uint8List?> _pdfFirstPagePng(Uint8List pdf) async {
    try {
      await for (final page in Printing.raster(pdf, pages: [0], dpi: 150)) {
        return page.toPng();
      }
    } catch (_) {}
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
    final endpoint =
        Uri.parse('$url/functions/v1/${AppConstants.fnAiExtract}');
    try {
      final res = await http
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'prompt': prompt,
              'structured': structured,
              if (image != null) 'image': base64Encode(image),
              if (text != null && text.trim().isNotEmpty) 'text': text,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 429) {
        return const AiResult.failure(
            'Free plan limit reached. Upgrade to Pro.', rateLimited: true);
      }
      if (res.statusCode >= 400) {
        return AiResult.failure('Scan failed (${res.statusCode})');
      }
      return AiResult.ok(
          (jsonDecode(res.body)['result'] as String?) ?? '');
    } catch (e) {
      return AiResult.failure('Extraction edge function unavailable: $e');
    }
  }

  Future<AiResult> _extractViaClaude({
    required String prompt,
    required Uint8List image,
    required String apiKey,
  }) async {
    try {
      final base64Image = base64Encode(image);
      final body = {
        'model': 'claude-haiku-4-5',
        'max_tokens': 2048,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/png',
                  'data': base64Image,
                },
              },
              {'type': 'text', 'text': prompt},
            ],
          }
        ],
      };

      final res = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      if (res.statusCode >= 400) {
        return AiResult.failure('Claude vision error (${res.statusCode})');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (data['content'] as List?)
              ?.whereType<Map>()
              .where((b) => b['type'] == 'text')
              .map((b) => b['text'] as String)
              .join('') ??
          '';
      return AiResult.ok(text.trim());
    } catch (e) {
      return AiResult.failure('Claude vision unavailable: $e');
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
      'summary':
          'Product designer with 6+ years crafting accessible, data-informed experiences.',
      'experience': [
        {
          'title': 'Senior Product Designer',
          'company': 'Northwind',
          'startDate': '2021',
          'endDate': 'Present',
          'bullets': [
            'Led the design system used across 4 squads',
            'Raised activation 18% via onboarding redesign'
          ],
        },
      ],
      'education': [
        {'degree': 'BDes', 'school': 'UNSW', 'startDate': '2014', 'endDate': '2018'},
      ],
      'skills': ['Figma', 'Design systems', 'User research', 'Prototyping'],
    });
  }
}

// ── Result type ─────────────────────────────────────────────────────────────

class AiResult {
  final String? text;
  final String? error;
  final bool rateLimited;

  const AiResult._(this.text, this.error, this.rateLimited);
  const AiResult.ok(String text) : this._(text, null, false);
  const AiResult.failure(String error, {bool rateLimited = false})
      : this._(null, error, rateLimited);

  bool get isOk => error == null;
}
