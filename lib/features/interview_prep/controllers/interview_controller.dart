import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../services/ai_service.dart';

/// One generated question + its lazily-generated STAR answer.
class InterviewQuestion {
  final String question;
  String? answer;
  bool answerLoading;
  InterviewQuestion(this.question, {this.answer, this.answerLoading = false});
}

class InterviewController extends ChangeNotifier {
  String jobTitle = '';
  String experienceLevel = '';

  bool questionsLoading = false;
  String? error;
  final List<InterviewQuestion> questions = [];

  bool get canGenerate => jobTitle.trim().isNotEmpty;

  /// Notifies so the Generate button enables/disables live as the title changes.
  void setJobTitle(String v) {
    jobTitle = v;
    notifyListeners();
  }

  Future<void> generateQuestions() async {
    if (!canGenerate || questionsLoading) return;
    questionsLoading = true;
    error = null;
    notifyListeners();

    final res = await AiService.instance.generate(
      feature: AiFeature.interviewQuestions,
      context: {'jobTitle': jobTitle.trim(), 'experienceLevel': experienceLevel.trim()},
    );

    questionsLoading = false;
    if (res.isOk && res.text != null) {
      try {
        final list = (jsonDecode(res.text!) as List).map((e) => e.toString());
        questions
          ..clear()
          ..addAll(list.map(InterviewQuestion.new));
      } catch (_) {
        error = 'Could not parse questions.';
      }
    } else {
      error = res.error ?? 'Could not generate questions.';
    }
    notifyListeners();
  }

  Future<void> generateAnswer(InterviewQuestion q) async {
    if (q.answerLoading) return;
    q.answerLoading = true;
    notifyListeners();

    final res = await AiService.instance.generate(
      feature: AiFeature.interviewAnswer,
      context: {'question': q.question, 'jobTitle': jobTitle.trim(), 'experience': ''},
    );

    q.answerLoading = false;
    if (res.isOk && res.text != null) {
      q.answer = res.text!.trim();
    } else {
      error = res.error ?? 'Could not generate answer.';
    }
    notifyListeners();
  }
}

final interviewControllerProvider =
    ChangeNotifierProvider.autoDispose<InterviewController>((ref) => InterviewController());
