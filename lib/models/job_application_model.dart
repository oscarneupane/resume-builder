enum JobStatus { saved, applied, interview, offer, rejected;
  String get value => name;
  static JobStatus parse(String v) =>
      JobStatus.values.firstWhere((e) => e.value == v, orElse: () => JobStatus.saved);
  String get label => switch (this) {
        JobStatus.saved => 'Saved',
        JobStatus.applied => 'Applied',
        JobStatus.interview => 'Interview',
        JobStatus.offer => 'Offer',
        JobStatus.rejected => 'Rejected',
      };
}

class JobApplication {
  final String id;
  final String userId;
  final String companyName;
  final String jobTitle;
  final DateTime applicationDate;
  final JobStatus status;
  final String? notes;
  final String? resumeId;
  final String? coverLetterId;
  final DateTime? createdAt;

  const JobApplication({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.jobTitle,
    required this.applicationDate,
    this.status = JobStatus.saved,
    this.notes,
    this.resumeId,
    this.coverLetterId,
    this.createdAt,
  });

  JobApplication copyWith({JobStatus? status, String? notes, String? companyName, String? jobTitle}) =>
      JobApplication(
        id: id,
        userId: userId,
        companyName: companyName ?? this.companyName,
        jobTitle: jobTitle ?? this.jobTitle,
        applicationDate: applicationDate,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        resumeId: resumeId,
        coverLetterId: coverLetterId,
        createdAt: createdAt,
      );

  factory JobApplication.fromMap(Map<String, dynamic> m) => JobApplication(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        companyName: m['company_name'] as String,
        jobTitle: m['job_title'] as String,
        applicationDate: DateTime.tryParse((m['application_date'] ?? '').toString()) ?? DateTime.now(),
        status: JobStatus.parse((m['status'] as String?) ?? 'saved'),
        notes: m['notes'] as String?,
        resumeId: m['resume_id'] as String?,
        coverLetterId: m['cover_letter_id'] as String?,
        createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at'].toString()) : null,
      );
}
