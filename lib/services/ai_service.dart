import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'supabase_service.dart';

/// Routes AI requests with a three-tier priority ("Both" mode):
///
///   1. Supabase Edge Function  — when Supabase is configured. Most secure;
///      the OpenAI key lives server-side and rate limiting is enforced.
///   2. Direct OpenAI call       — when OPENAI_API_KEY is set in `.env`. Lets the
///      app produce real ChatGPT output during MVP/dev before the backend is
///      deployed. NOTE: the key ships inside the app, so use this for testing
///      only — production should rely on tier 1.
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

  /// OPENAI_API_KEY from `.env`, or null if absent/placeholder.
  String? get _openAiKey {
    try {
      final k = dotenv.env['OPENAI_API_KEY'];
      if (k == null || k.isEmpty || k.startsWith('sk-your') || k.startsWith('your-')) return null;
      return k;
    } catch (_) {
      return null;
    }
  }

  Future<AiResult> generate({
    required AiFeature feature,
    required Map<String, dynamic> context,
  }) async {
    // Tier 1 — secure Edge Function.
    if (SupabaseService.isConfigured) {
      return _viaEdgeFunction(feature, context);
    }
    // Tier 2 — direct OpenAI (MVP/dev).
    if (_openAiKey != null) {
      return _viaOpenAi(feature, context, _openAiKey!);
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
  Future<AiResult> _viaOpenAi(AiFeature feature, Map<String, dynamic> context, String apiKey) async {
    final (prompt, wantsJson) = _buildPrompt(feature, context);
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          if (wantsJson) 'response_format': {'type': 'json_object'},
        }),
      );

      if (res.statusCode == 401) {
        return const AiResult.failure('OpenAI rejected the API key. Check OPENAI_API_KEY in .env.');
      }
      if (res.statusCode >= 400) {
        return AiResult.failure('OpenAI request failed (${res.statusCode}).');
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final content = (body['choices']?[0]?['message']?['content'] as String?)?.trim() ?? '';

      // Normalize skillsSuggest to a bare JSON array string (the client parses a List).
      if (feature == AiFeature.skillsSuggest) {
        try {
          final parsed = jsonDecode(content);
          final skills = parsed is List ? parsed : (parsed['skills'] ?? []);
          return AiResult.ok(jsonEncode(skills));
        } catch (_) {
          return const AiResult.ok('[]');
        }
      }
      return AiResult.ok(content);
    } catch (e) {
      return AiResult.failure('OpenAI request error: $e');
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
        return (
          'You are a professional cover letter writer.\n'
              'Write a ${s('tone')} cover letter for:\n'
              'Job Title: ${s('jobTitle')}\n'
              'Company: ${s('companyName')}\n'
              'Applicant skills: ${s('skills')}\n'
              'Job Description: ${s('jobDescription')}\n'
              'Return a JSON object with keys: full_letter, short_email, recruiter_msg.',
          true
        );
      case AiFeature.linkedinAbout:
        return (
          'Write a compelling LinkedIn About section.\n'
              'Name: ${s('name')} | Job Title: ${s('jobTitle')}\n'
              'Skills: ${s('skills')} | Career Goal: ${s('goal')}\n'
              'Max 300 words. Professional tone. First person.',
          false
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
      case AiFeature.linkedinAbout:
        return 'Builder, learner, shipper. I help teams turn ambiguous problems into clear plans...';
      case AiFeature.interviewAnswer:
        return 'Situation: ...\nTask: ...\nAction: ...\nResult: ...';
      case AiFeature.skillsSuggest:
        return jsonEncode(['Communication', 'Problem solving', 'Leadership', 'Adaptability']);
    }
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
