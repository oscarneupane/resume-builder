class CoverLetter {
  final String id;
  final String userId;
  final String? resumeId;
  final String? jobTitle;
  final String? companyName;
  final String tone;
  final String? fullLetter;
  final String? shortEmail;
  final String? recruiterMsg;
  final DateTime? createdAt;

  const CoverLetter({
    required this.id,
    required this.userId,
    this.resumeId,
    this.jobTitle,
    this.companyName,
    this.tone = 'professional',
    this.fullLetter,
    this.shortEmail,
    this.recruiterMsg,
    this.createdAt,
  });

  factory CoverLetter.fromMap(Map<String, dynamic> m) => CoverLetter(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        resumeId: m['resume_id'] as String?,
        jobTitle: m['job_title'] as String?,
        companyName: m['company_name'] as String?,
        tone: (m['tone'] as String?) ?? 'professional',
        fullLetter: m['full_letter'] as String?,
        shortEmail: m['short_email'] as String?,
        recruiterMsg: m['recruiter_msg'] as String?,
        createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at'].toString()) : null,
      );
}
