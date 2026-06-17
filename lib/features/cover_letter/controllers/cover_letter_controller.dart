import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../services/ai_service.dart';

enum CoverLetterTone {
  professional,
  confident,
  friendly,
  simple;

  String get label => switch (this) {
        CoverLetterTone.professional => 'Professional',
        CoverLetterTone.confident => 'Confident',
        CoverLetterTone.friendly => 'Friendly',
        CoverLetterTone.simple => 'Simple',
      };
}

/// Holds the three generated formats from the cover-letter function.
class CoverLetterResult {
  final String fullLetter;
  final String shortEmail;
  final String recruiterMsg;
  const CoverLetterResult({
    required this.fullLetter,
    required this.shortEmail,
    required this.recruiterMsg,
  });

  /// Parses the `{full_letter, short_email, recruiter_msg}` JSON the
  /// cover-letter function returns. Tolerant of missing keys.
  factory CoverLetterResult.parse(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return CoverLetterResult(
        fullLetter: (m['full_letter'] ?? '').toString(),
        shortEmail: (m['short_email'] ?? '').toString(),
        recruiterMsg: (m['recruiter_msg'] ?? '').toString(),
      );
    } catch (_) {
      // If the model returned plain prose, treat it all as the full letter.
      return CoverLetterResult(fullLetter: raw, shortEmail: '', recruiterMsg: '');
    }
  }
}

class CoverLetterController extends ChangeNotifier {
  String jobTitle = '';
  String companyName = '';
  String skills = '';
  String jobDescription = '';
  CoverLetterTone tone = CoverLetterTone.professional;

  bool loading = false;
  String? error;
  CoverLetterResult? result;

  bool get canGenerate => jobTitle.trim().isNotEmpty && companyName.trim().isNotEmpty;

  void setTone(CoverLetterTone t) {
    tone = t;
    notifyListeners();
  }

  Future<void> generate() async {
    if (!canGenerate || loading) return;
    loading = true;
    error = null;
    notifyListeners();

    final res = await AiService.instance.generate(
      feature: AiFeature.coverLetter,
      context: {
        'jobTitle': jobTitle.trim(),
        'companyName': companyName.trim(),
        'skills': skills.trim(),
        'jobDescription': jobDescription.trim(),
        'tone': tone.name,
      },
    );

    loading = false;
    if (res.isOk && res.text != null) {
      result = CoverLetterResult.parse(res.text!);
    } else {
      error = res.error ?? 'Could not generate cover letter.';
    }
    notifyListeners();
  }
}

final coverLetterControllerProvider =
    ChangeNotifierProvider.autoDispose<CoverLetterController>((ref) => CoverLetterController());
