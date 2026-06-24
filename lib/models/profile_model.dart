import '../core/constants.dart';

class Profile {
  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String? careerGoal;
  final String? jobTitle;
  final String? country;
  final ExperienceLevel? experience;
  final String? resumeStyle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.careerGoal,
    this.jobTitle,
    this.country,
    this.experience,
    this.resumeStyle,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: m['full_name'] as String?,
        username: m['username'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        careerGoal: m['career_goal'] as String?,
        jobTitle: m['job_title'] as String?,
        country: m['country'] as String?,
        experience: _parseExperience(m['experience'] as String?),
        resumeStyle: m['resume_style'] as String?,
        createdAt: _ts(m['created_at']),
        updatedAt: _ts(m['updated_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        if (fullName != null) 'full_name': fullName,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (careerGoal != null) 'career_goal': careerGoal,
        if (jobTitle != null) 'job_title': jobTitle,
        if (country != null) 'country': country,
        if (experience != null) 'experience': experience!.value,
        if (resumeStyle != null) 'resume_style': resumeStyle,
      };

  Profile copyWith({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? careerGoal,
    String? jobTitle,
    String? country,
    ExperienceLevel? experience,
    String? resumeStyle,
  }) =>
      Profile(
        id: id,
        fullName: fullName ?? this.fullName,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        careerGoal: careerGoal ?? this.careerGoal,
        jobTitle: jobTitle ?? this.jobTitle,
        country: country ?? this.country,
        experience: experience ?? this.experience,
        resumeStyle: resumeStyle ?? this.resumeStyle,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

ExperienceLevel? _parseExperience(String? v) =>
    v == null ? null : ExperienceLevel.values.firstWhere(
          (e) => e.value == v,
          orElse: () => ExperienceLevel.entry,
        );

DateTime? _ts(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
