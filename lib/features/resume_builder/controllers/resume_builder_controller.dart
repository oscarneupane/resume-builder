import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../models/resume_model.dart';

/// One work-experience entry being edited in the builder.
class ExperienceEntry {
  String title;
  String company;
  String location;
  String startDate;
  String endDate;
  bool current;
  List<String> bullets;

  ExperienceEntry({
    this.title = '',
    this.company = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.current = false,
    List<String>? bullets,
  }) : bullets = bullets ?? [''];

  Map<String, dynamic> toContent() => {
        'title': title,
        'company': company,
        'location': location,
        'startDate': startDate,
        'endDate': current ? 'Present' : endDate,
        'bullets': bullets.where((b) => b.trim().isNotEmpty).toList(),
      };
}

/// One education entry being edited in the builder.
class EducationEntry {
  String degree;
  String school;
  String startDate;
  String endDate;
  String gpa;

  EducationEntry({
    this.degree = '',
    this.school = '',
    this.startDate = '',
    this.endDate = '',
    this.gpa = '',
  });

  Map<String, dynamic> toContent() => {
        'degree': degree,
        'school': school,
        'startDate': startDate,
        'endDate': endDate,
        if (gpa.trim().isNotEmpty) 'gpa': gpa,
      };
}

/// Mutable draft held while the user fills the multi-step builder. Kept in
/// memory for now; once Supabase is wired, [toResume] maps cleanly to the
/// `resume_sections` JSONB rows.
class ResumeBuilderController extends ChangeNotifier {
  // Personal
  String fullName = '';
  String title = '';
  String email = '';
  String phone = '';
  String location = '';
  String linkedin = '';

  // Summary
  String summary = '';

  // Repeating sections
  final List<ExperienceEntry> experiences = [ExperienceEntry()];
  final List<EducationEntry> education = [EducationEntry()];
  final List<String> skills = [];

  // Extras
  final List<String> certifications = [];
  final List<String> languages = [];

  String template = AppConstants.defaultTemplate;

  void update(VoidCallback mutate) {
    mutate();
    notifyListeners();
  }

  void setTemplate(String t) {
    template = t;
    notifyListeners();
  }

  void addExperience() {
    experiences.add(ExperienceEntry());
    notifyListeners();
  }

  void removeExperience(int i) {
    if (experiences.length > 1) experiences.removeAt(i);
    notifyListeners();
  }

  void addEducation() {
    education.add(EducationEntry());
    notifyListeners();
  }

  void removeEducation(int i) {
    if (education.length > 1) education.removeAt(i);
    notifyListeners();
  }

  void addSkill(String s) {
    final v = s.trim();
    if (v.isNotEmpty && !skills.contains(v)) {
      skills.add(v);
      notifyListeners();
    }
  }

  void removeSkill(String s) {
    skills.remove(s);
    notifyListeners();
  }

  void toggleSimpleListItem(List<String> list, String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    notifyListeners();
  }

  /// 0..1 completion across the seven builder steps, used for the progress bar.
  double get completion {
    var done = 0;
    const total = 6; // personal, summary, experience, education, skills, extras
    if (fullName.trim().isNotEmpty && email.trim().isNotEmpty) done++;
    if (summary.trim().isNotEmpty) done++;
    if (experiences.any((e) => e.title.trim().isNotEmpty)) done++;
    if (education.any((e) => e.degree.trim().isNotEmpty)) done++;
    if (skills.isNotEmpty) done++;
    if (certifications.isNotEmpty || languages.isNotEmpty) done++;
    return done / total;
  }

  /// Builds an in-memory [Resume] shaped for [PdfService] and (later) Supabase.
  Resume toResume({String userId = 'local', String id = 'draft'}) {
    ResumeSection sec(SectionType type, Map<String, dynamic> content, int order) => ResumeSection(
          id: '$id-${type.value}',
          resumeId: id,
          userId: userId,
          type: type,
          content: content,
          displayOrder: order,
        );

    return Resume(
      id: id,
      userId: userId,
      title: fullName.trim().isEmpty ? 'My Resume' : '$fullName — Resume',
      template: template,
      sections: [
        sec(SectionType.personal, {
          'fullName': fullName,
          'title': title,
          'email': email,
          'phone': phone,
          'location': location,
          'linkedin': linkedin,
        }, 0),
        sec(SectionType.summary, {'text': summary}, 1),
        sec(SectionType.experience, {
          'items': experiences
              .where((e) => e.title.trim().isNotEmpty || e.company.trim().isNotEmpty)
              .map((e) => e.toContent())
              .toList(),
        }, 2),
        sec(SectionType.education, {
          'items': education
              .where((e) => e.degree.trim().isNotEmpty || e.school.trim().isNotEmpty)
              .map((e) => e.toContent())
              .toList(),
        }, 3),
        sec(SectionType.skills, {'items': List<String>.from(skills)}, 4),
        sec(SectionType.certifications, {'items': List<String>.from(certifications)}, 5),
        sec(SectionType.languages, {'items': List<String>.from(languages)}, 6),
      ],
    );
  }
}

final resumeBuilderControllerProvider =
    ChangeNotifierProvider.autoDispose<ResumeBuilderController>((ref) {
  // Keep the draft alive while the builder/preview flow is active.
  ref.keepAlive();
  return ResumeBuilderController();
});
