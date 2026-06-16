/// Core data models for the resume builder. These are intentionally simple,
/// mutable classes — state changes flow through ResumeProvider so the UI
/// updates consistently via ChangeNotifier.

class PersonalInfo {
  String fullName;
  String email;
  String phone;
  String location;
  String linkedIn;
  String summary;

  PersonalInfo({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedIn = '',
    this.summary = '',
  });
}

class Education {
  String institution;
  String degree;
  String fieldOfStudy;
  String startDate;
  String endDate;

  Education({
    this.institution = '',
    this.degree = '',
    this.fieldOfStudy = '',
    this.startDate = '',
    this.endDate = '',
  });
}

class Experience {
  String company;
  String role;
  String location;
  String startDate;
  String endDate;
  List<String> bullets;

  Experience({
    this.company = '',
    this.role = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    List<String>? bullets,
  }) : bullets = bullets ?? [''];
}

/// Answers to the upfront "tell us about your goals" questions. These give
/// the AI bullet-point improver real context instead of generic advice.
class UserGoals {
  String targetField;
  String targetJobTitle;
  String experienceLevel; // 'Entry-level' | 'Mid-level' | 'Senior'
  List<String> priorities; // e.g. ['Leadership', 'Technical skills']

  UserGoals({
    this.targetField = '',
    this.targetJobTitle = '',
    this.experienceLevel = 'Entry-level',
    List<String>? priorities,
  }) : priorities = priorities ?? [];
}

class ResumeData {
  UserGoals goals;
  PersonalInfo personalInfo;
  List<Education> education;
  List<Experience> experience;
  List<String> skills;
  int selectedTemplate; // 0 = none chosen yet, 1/2/3 = template id

  ResumeData({
    UserGoals? goals,
    PersonalInfo? personalInfo,
    List<Education>? education,
    List<Experience>? experience,
    List<String>? skills,
    this.selectedTemplate = 0,
  })  : goals = goals ?? UserGoals(),
        personalInfo = personalInfo ?? PersonalInfo(),
        education = education ?? [],
        experience = experience ?? [],
        skills = skills ?? [];
}
