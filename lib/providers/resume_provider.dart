import 'package:flutter/foundation.dart';
import '../models/resume_data.dart';

/// Single source of truth for the resume being built. Screens read/update
/// through this provider so changes show up everywhere consistently.
class ResumeProvider extends ChangeNotifier {
  final ResumeData resumeData = ResumeData();

  void updateGoals({
    String? targetField,
    String? targetJobTitle,
    String? experienceLevel,
    List<String>? priorities,
  }) {
    if (targetField != null) resumeData.goals.targetField = targetField;
    if (targetJobTitle != null) resumeData.goals.targetJobTitle = targetJobTitle;
    if (experienceLevel != null) resumeData.goals.experienceLevel = experienceLevel;
    if (priorities != null) {
      resumeData.goals.priorities
        ..clear()
        ..addAll(priorities);
    }
    notifyListeners();
  }

  /// Replaces personal info / education / experience / skills with data
  /// parsed (by AI) from a pasted-in old resume. Goals and template choice
  /// are left untouched since those are separate questions.
  void loadImportedResume(ResumeData parsed) {
    resumeData.personalInfo = parsed.personalInfo;
    resumeData.education = parsed.education;
    resumeData.experience = parsed.experience;
    resumeData.skills = parsed.skills;
    notifyListeners();
  }

  void updatePersonalInfo({
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? linkedIn,
    String? summary,
  }) {
    if (fullName != null) resumeData.personalInfo.fullName = fullName;
    if (email != null) resumeData.personalInfo.email = email;
    if (phone != null) resumeData.personalInfo.phone = phone;
    if (location != null) resumeData.personalInfo.location = location;
    if (linkedIn != null) resumeData.personalInfo.linkedIn = linkedIn;
    if (summary != null) resumeData.personalInfo.summary = summary;
    notifyListeners();
  }

  void addEducation(Education edu) {
    resumeData.education.add(edu);
    notifyListeners();
  }

  void removeEducation(int index) {
    resumeData.education.removeAt(index);
    notifyListeners();
  }

  void addExperience(Experience exp) {
    resumeData.experience.add(exp);
    notifyListeners();
  }

  void removeExperience(int index) {
    resumeData.experience.removeAt(index);
    notifyListeners();
  }

  void updateExperienceBullet(int expIndex, int bulletIndex, String text) {
    resumeData.experience[expIndex].bullets[bulletIndex] = text;
    notifyListeners();
  }

  void addBulletToExperience(int expIndex) {
    resumeData.experience[expIndex].bullets.add('');
    notifyListeners();
  }

  void removeBulletFromExperience(int expIndex, int bulletIndex) {
    resumeData.experience[expIndex].bullets.removeAt(bulletIndex);
    notifyListeners();
  }

  void setSkills(List<String> skills) {
    resumeData.skills
      ..clear()
      ..addAll(skills);
    notifyListeners();
  }

  void setTemplate(int templateId) {
    resumeData.selectedTemplate = templateId;
    notifyListeners();
  }
}
