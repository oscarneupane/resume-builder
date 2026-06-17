class AtsCheck {
  final String id;
  final String userId;
  final String? resumeId;
  final String jobDescription;
  final int score;
  final List<String> matchingKeywords;
  final List<String> missingKeywords;
  final List<String> weakSections;
  final List<AtsSuggestion> suggestions;
  final DateTime? createdAt;

  const AtsCheck({
    required this.id,
    required this.userId,
    this.resumeId,
    required this.jobDescription,
    required this.score,
    this.matchingKeywords = const [],
    this.missingKeywords = const [],
    this.weakSections = const [],
    this.suggestions = const [],
    this.createdAt,
  });

  factory AtsCheck.fromMap(Map<String, dynamic> m) => AtsCheck(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        resumeId: m['resume_id'] as String?,
        jobDescription: m['job_description'] as String,
        score: (m['ats_score'] as int?) ?? 0,
        matchingKeywords: List<String>.from(m['matching_keywords'] ?? const []),
        missingKeywords: List<String>.from(m['missing_keywords'] ?? const []),
        weakSections: List<String>.from(m['weak_sections'] ?? const []),
        suggestions: ((m['suggestions'] as List?) ?? const [])
            .map((e) => AtsSuggestion.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at'].toString()) : null,
      );
}

class AtsSuggestion {
  final String section;
  final String issue;
  final String fix;
  const AtsSuggestion({required this.section, required this.issue, required this.fix});

  factory AtsSuggestion.fromMap(Map<String, dynamic> m) =>
      AtsSuggestion(section: m['section'] ?? '', issue: m['issue'] ?? '', fix: m['fix'] ?? '');
}
