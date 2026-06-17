/// Maps to `resumes` and `resume_sections` tables.
class Resume {
  final String id;
  final String userId;
  final String title;
  final String template;
  final bool isPrimary;
  final List<ResumeSection> sections;
  final DateTime? updatedAt;

  const Resume({
    required this.id,
    required this.userId,
    required this.title,
    this.template = 'classic',
    this.isPrimary = false,
    this.sections = const [],
    this.updatedAt,
  });

  factory Resume.fromMap(Map<String, dynamic> m, {List<ResumeSection> sections = const []}) => Resume(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        title: (m['title'] as String?) ?? 'My Resume',
        template: (m['template'] as String?) ?? 'classic',
        isPrimary: (m['is_primary'] as bool?) ?? false,
        sections: sections,
        updatedAt: m['updated_at'] != null ? DateTime.tryParse(m['updated_at'].toString()) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'template': template,
        'is_primary': isPrimary,
      };

  Resume copyWith({String? title, String? template, bool? isPrimary, List<ResumeSection>? sections}) => Resume(
        id: id,
        userId: userId,
        title: title ?? this.title,
        template: template ?? this.template,
        isPrimary: isPrimary ?? this.isPrimary,
        sections: sections ?? this.sections,
        updatedAt: updatedAt,
      );

  ResumeSection? section(SectionType t) {
    for (final s in sections) {
      if (s.type == t) return s;
    }
    return null;
  }
}

enum SectionType {
  personal,
  summary,
  experience,
  education,
  skills,
  projects,
  certifications,
  languages,
  references;

  String get value => name;
  static SectionType parse(String v) =>
      SectionType.values.firstWhere((e) => e.value == v, orElse: () => SectionType.personal);
}

class ResumeSection {
  final String id;
  final String resumeId;
  final String userId;
  final SectionType type;
  final Map<String, dynamic> content;
  final int displayOrder;

  const ResumeSection({
    required this.id,
    required this.resumeId,
    required this.userId,
    required this.type,
    required this.content,
    this.displayOrder = 0,
  });

  factory ResumeSection.fromMap(Map<String, dynamic> m) => ResumeSection(
        id: m['id'] as String,
        resumeId: m['resume_id'] as String,
        userId: m['user_id'] as String,
        type: SectionType.parse(m['section_type'] as String),
        content: Map<String, dynamic>.from(m['content'] as Map? ?? {}),
        displayOrder: (m['display_order'] as int?) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'resume_id': resumeId,
        'user_id': userId,
        'section_type': type.value,
        'content': content,
        'display_order': displayOrder,
      };
}
