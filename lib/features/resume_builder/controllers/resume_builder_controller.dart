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

/// One project entry being edited in the builder.
class ProjectEntry {
  String name;
  String description;
  String link;

  ProjectEntry({this.name = '', this.description = '', this.link = ''});

  Map<String, dynamic> toContent() => {
        'name': name,
        'description': description,
        if (link.trim().isNotEmpty) 'link': link,
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
  String github = '';
  String portfolio = '';

  // Summary
  String summary = '';

  // Repeating sections
  final List<ExperienceEntry> experiences = [ExperienceEntry()];
  final List<EducationEntry> education = [EducationEntry()];
  final List<ProjectEntry> projects = [ProjectEntry()];
  final List<String> skills = [];

  // Extras
  final List<String> certifications = [];
  final List<String> languages = [];

  String template = AppConstants.defaultTemplate;

  /// Set once the draft has been persisted to Supabase, so subsequent saves
  /// update the same row instead of creating duplicates.
  String? savedResumeId;

  /// Bumped when data is applied externally (e.g. Smart Import) so the builder
  /// can re-key its fields and pick up the new initialValues.
  int revision = 0;

  /// Pre-fills the draft from AI-extracted resume JSON (Smart Import).
  void applyExtracted(Map<String, dynamic> data) {
    String s(Object? v) => (v ?? '').toString().trim();
    final p = Map<String, dynamic>.from((data['personal'] as Map?) ?? const {});
    if (s(p['fullName']).isNotEmpty) fullName = s(p['fullName']);
    if (s(p['title']).isNotEmpty) title = s(p['title']);
    if (s(p['email']).isNotEmpty) email = s(p['email']);
    if (s(p['phone']).isNotEmpty) phone = s(p['phone']);
    if (s(p['location']).isNotEmpty) location = s(p['location']);
    if (s(p['linkedin']).isNotEmpty) linkedin = s(p['linkedin']);
    if (s(p['github']).isNotEmpty) github = s(p['github']);
    if (s(p['portfolio']).isNotEmpty) portfolio = s(p['portfolio']);
    if (s(data['summary']).isNotEmpty) summary = s(data['summary']);

    final exp = (data['experience'] as List?) ?? const [];
    if (exp.isNotEmpty) {
      experiences
        ..clear()
        ..addAll(exp.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final bullets = ((m['bullets'] as List?) ?? const []).map((b) => b.toString()).toList();
          final end = s(m['endDate']);
          return ExperienceEntry(
            title: s(m['title']),
            company: s(m['company']),
            startDate: s(m['startDate']),
            endDate: end.toLowerCase() == 'present' ? '' : end,
            current: end.toLowerCase() == 'present',
            bullets: bullets.isEmpty ? [''] : bullets,
          );
        }));
    }

    final edu = (data['education'] as List?) ?? const [];
    if (edu.isNotEmpty) {
      education
        ..clear()
        ..addAll(edu.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return EducationEntry(
            degree: s(m['degree']),
            school: s(m['school']),
            startDate: s(m['startDate']),
            endDate: s(m['endDate']),
          );
        }));
    }

    final proj = (data['projects'] as List?) ?? const [];
    if (proj.isNotEmpty) {
      projects
        ..clear()
        ..addAll(proj.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return ProjectEntry(
            name: s(m['name']),
            description: s(m['description']),
            link: s(m['link']),
          );
        }));
    }

    for (final sk in ((data['skills'] as List?) ?? const [])) {
      final v = sk.toString().trim();
      if (v.isNotEmpty && !skills.contains(v)) skills.add(v);
    }

    revision++;
    notifyListeners();
  }

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

  void addProject() {
    projects.add(ProjectEntry());
    notifyListeners();
  }

  void removeProject(int i) {
    if (projects.length > 1) projects.removeAt(i);
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

  /// Weighted 0-100 measure of how strong/complete the resume is — the
  /// "potential" shown on the dashboard. Rewards depth (quantified bullets,
  /// enough skills, a substantive summary), not just presence of a field.
  int get strengthScore {
    var score = 0;

    // Contact essentials — 20 (4 each).
    if (fullName.trim().isNotEmpty) score += 4;
    if (email.trim().isNotEmpty) score += 4;
    if (phone.trim().isNotEmpty) score += 4;
    if (location.trim().isNotEmpty) score += 4;
    if (title.trim().isNotEmpty) score += 4;

    // Summary — 15 (presence + substance).
    final summaryLen = summary.trim().length;
    if (summaryLen > 0) score += 8;
    if (summaryLen >= 120) score += 7;

    // Experience — 24 (an entry + quantified-ish bullets).
    final filledExp = experiences.where((e) => e.title.trim().isNotEmpty && e.company.trim().isNotEmpty);
    if (filledExp.isNotEmpty) score += 12;
    final bulletCount = filledExp.fold<int>(0, (n, e) => n + e.bullets.where((b) => b.trim().isNotEmpty).length);
    if (bulletCount >= 1) score += 6;
    if (bulletCount >= 3) score += 6;

    // Education — 12.
    if (education.any((e) => e.degree.trim().isNotEmpty && e.school.trim().isNotEmpty)) score += 12;

    // Skills — 16 (depth).
    if (skills.length >= 3) score += 10;
    if (skills.length >= 6) score += 6;

    // Extras — 8.
    if (certifications.isNotEmpty) score += 4;
    if (languages.isNotEmpty) score += 4;

    // LinkedIn — 5 bonus.
    if (linkedin.trim().isNotEmpty) score += 5;

    return score.clamp(0, 100);
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
          'github': github,
          'portfolio': portfolio,
        }, 0),
        sec(SectionType.summary, {'text': summary}, 1),
        sec(SectionType.skills, {'items': List<String>.from(skills)}, 2),
        sec(SectionType.projects, {
          'items': projects
              .where((p) => p.name.trim().isNotEmpty || p.description.trim().isNotEmpty)
              .map((p) => p.toContent())
              .toList(),
        }, 3),
        sec(SectionType.experience, {
          'items': experiences
              .where((e) => e.title.trim().isNotEmpty || e.company.trim().isNotEmpty)
              .map((e) => e.toContent())
              .toList(),
        }, 4),
        sec(SectionType.education, {
          'items': education
              .where((e) => e.degree.trim().isNotEmpty || e.school.trim().isNotEmpty)
              .map((e) => e.toContent())
              .toList(),
        }, 5),
        sec(SectionType.certifications, {'items': List<String>.from(certifications)}, 6),
        sec(SectionType.languages, {'items': List<String>.from(languages)}, 7),
      ],
    );
  }

  /// Flattens whatever the user has entered so far into a plain-text brief that
  /// the AI uses as the factual basis for a full-resume generation. Only real
  /// facts go in — the AI is instructed to enrich wording, not invent history.
  String aiDetails() {
    final b = StringBuffer();
    void line(String label, String v) {
      if (v.trim().isNotEmpty) b.writeln('$label: ${v.trim()}');
    }

    line('Name', fullName);
    line('Target title', title);
    line('Email', email);
    line('Phone', phone);
    line('Location', location);
    line('LinkedIn', linkedin);
    line('GitHub', github);
    line('Portfolio', portfolio);
    if (summary.trim().isNotEmpty) line('Current summary', summary);

    final exp = experiences.where((e) => e.title.trim().isNotEmpty || e.company.trim().isNotEmpty).toList();
    if (exp.isNotEmpty) {
      b.writeln('Experience:');
      for (final e in exp) {
        final end = e.current ? 'Present' : e.endDate;
        b.writeln('  - ${e.title} at ${e.company} (${e.startDate} – $end)');
        for (final bul in e.bullets.where((x) => x.trim().isNotEmpty)) {
          b.writeln('    • ${bul.trim()}');
        }
      }
    }

    final edu = education.where((e) => e.degree.trim().isNotEmpty || e.school.trim().isNotEmpty).toList();
    if (edu.isNotEmpty) {
      b.writeln('Education:');
      for (final e in edu) {
        b.writeln('  - ${e.degree}, ${e.school} (${e.startDate} – ${e.endDate})');
      }
    }

    final proj = projects.where((p) => p.name.trim().isNotEmpty).toList();
    if (proj.isNotEmpty) {
      b.writeln('Projects:');
      for (final p in proj) {
        b.writeln('  - ${p.name}: ${p.description}${p.link.trim().isEmpty ? '' : ' (${p.link})'}');
      }
    }

    if (skills.isNotEmpty) line('Skills', skills.join(', '));
    if (certifications.isNotEmpty) line('Certifications', certifications.join(', '));
    if (languages.isNotEmpty) line('Languages', languages.join(', '));

    return b.toString().trim();
  }
}

final resumeBuilderControllerProvider =
    ChangeNotifierProvider.autoDispose<ResumeBuilderController>((ref) {
  // Keep the draft alive while the builder/preview flow is active.
  ref.keepAlive();
  return ResumeBuilderController();
});
