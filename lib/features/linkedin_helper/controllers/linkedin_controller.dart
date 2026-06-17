import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../services/ai_service.dart';

/// The four LinkedIn helper sections.
enum LinkedInSection { headline, about, recruiter, skills }

extension LinkedInSectionX on LinkedInSection {
  String get title => switch (this) {
        LinkedInSection.headline => 'Headline',
        LinkedInSection.about => 'About section',
        LinkedInSection.recruiter => 'Recruiter message',
        LinkedInSection.skills => 'Skill suggestions',
      };

  String get subtitle => switch (this) {
        LinkedInSection.headline => '3 punchy headline options',
        LinkedInSection.about => 'A compelling first-person summary',
        LinkedInSection.recruiter => 'A short cold-outreach message',
        LinkedInSection.skills => '10 skills to list on your profile',
      };

  AiFeature get feature => switch (this) {
        LinkedInSection.headline => AiFeature.linkedinHeadline,
        LinkedInSection.about => AiFeature.linkedinAbout,
        LinkedInSection.recruiter => AiFeature.recruiterMessage,
        LinkedInSection.skills => AiFeature.skillsSuggest,
      };
}

class LinkedInController extends ChangeNotifier {
  String jobTitle = '';
  String yearsExp = '';
  String skills = '';

  final Map<LinkedInSection, String> results = {};
  final Set<LinkedInSection> _loading = {};
  String? error;

  bool get canGenerate => jobTitle.trim().isNotEmpty;
  bool isLoading(LinkedInSection s) => _loading.contains(s);

  /// Notifies so the section Generate buttons enable/disable live.
  void setJobTitle(String v) {
    jobTitle = v;
    notifyListeners();
  }

  Future<void> generate(LinkedInSection section) async {
    if (!canGenerate || _loading.contains(section)) return;
    _loading.add(section);
    error = null;
    notifyListeners();

    final res = await AiService.instance.generate(
      feature: section.feature,
      context: {
        'jobTitle': jobTitle.trim(),
        'yearsExp': yearsExp.trim(),
        'skills': skills.trim(),
        'name': '',
        'goal': '',
      },
    );

    _loading.remove(section);
    if (res.isOk && res.text != null) {
      results[section] = _format(section, res.text!);
    } else {
      error = res.error ?? 'Could not generate. Try again.';
    }
    notifyListeners();
  }

  /// Skills come back as a JSON array; render them as a comma list.
  String _format(LinkedInSection section, String raw) {
    if (section != LinkedInSection.skills) return raw.trim();
    try {
      final list = (jsonDecode(raw) as List).map((e) => e.toString());
      return list.join(', ');
    } catch (_) {
      return raw.trim();
    }
  }
}

final linkedInControllerProvider =
    ChangeNotifierProvider.autoDispose<LinkedInController>((ref) => LinkedInController());
