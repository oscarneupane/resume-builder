import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'supabase_service.dart';

/// Calls the Supabase Edge Function `ai-generate` (Part G3).
///
/// CRITICAL: never embed OpenAI keys here. We hit our Edge Function, which
/// holds the key in env vars and enforces rate limiting.
///
/// If Supabase isn't configured yet, we return a deterministic placeholder so
/// the UI flows are exercisable in dev.
class AiService {
  AiService._();
  static final instance = AiService._();

  Future<AiResult> generate({
    required AiFeature feature,
    required Map<String, dynamic> context,
  }) async {
    if (!SupabaseService.isConfigured) {
      return AiResult.ok(_mockResponse(feature, context));
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const AiResult.failure('Not signed in.');
    }
    final url = dotenv.env['SUPABASE_URL'];
    final endpoint = Uri.parse('$url/functions/v1/${AppConstants.fnAiGenerate}');

    final res = await http.post(
      endpoint,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'feature': feature.name, 'context': context}),
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
