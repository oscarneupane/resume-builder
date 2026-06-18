import 'package:flutter_test/flutter_test.dart';

import 'package:applymate/core/constants.dart';
import 'package:applymate/features/cover_letter/controllers/cover_letter_controller.dart';
import 'package:applymate/features/interview_prep/controllers/interview_controller.dart';
import 'package:applymate/features/linkedin_helper/controllers/linkedin_controller.dart';
import 'package:applymate/features/resume_builder/controllers/resume_builder_controller.dart';
import 'package:applymate/models/document_model.dart';
import 'package:applymate/models/job_application_model.dart';
import 'package:applymate/models/resume_model.dart';
import 'package:applymate/services/job_repository.dart';
import 'package:applymate/shared/utils/validators.dart';

void main() {
  group('ResumeBuilderController.toResume', () {
    test('maps personal + summary into the expected section shapes', () {
      final c = ResumeBuilderController()
        ..fullName = 'Ada Lovelace'
        ..title = 'Software Engineer'
        ..email = 'ada@example.com'
        ..summary = 'Pioneering engineer.';

      final resume = c.toResume(userId: 'u1');

      expect(resume.userId, 'u1');
      expect(resume.title, 'Ada Lovelace — Resume');

      final personal = resume.section(SectionType.personal)!.content;
      expect(personal['fullName'], 'Ada Lovelace');
      expect(personal['email'], 'ada@example.com');

      expect(resume.section(SectionType.summary)!.content['text'], 'Pioneering engineer.');
    });

    test('drops empty experience entries and blank bullets', () {
      final c = ResumeBuilderController();
      c.experiences.first.title = 'Engineer';
      c.experiences.first.company = 'Acme';
      c.experiences.first.bullets = ['Shipped X', '', '   '];
      c.addExperience(); // second entry left empty -> filtered out

      final items = c.toResume().section(SectionType.experience)!.content['items'] as List;
      expect(items.length, 1);
      expect((items.first['bullets'] as List).length, 1);
      expect(items.first['bullets'].first, 'Shipped X');
    });

    test('current job renders end date as Present', () {
      final c = ResumeBuilderController();
      c.experiences.first
        ..title = 'Engineer'
        ..current = true
        ..endDate = 'ignored';

      final items = c.toResume().section(SectionType.experience)!.content['items'] as List;
      expect(items.first['endDate'], 'Present');
    });

    test('skills are de-duplicated and template defaults are honoured', () {
      final c = ResumeBuilderController()
        ..addSkill('Dart')
        ..addSkill('Dart')
        ..addSkill('Flutter');

      expect(c.skills, ['Dart', 'Flutter']);
      expect(c.toResume().template, AppConstants.defaultTemplate);
    });

    test('completion increases as sections are filled', () {
      final c = ResumeBuilderController();
      expect(c.completion, 0);
      c
        ..fullName = 'Ada'
        ..email = 'a@b.com';
      expect(c.completion, greaterThan(0));
    });
  });

  group('ResumeBuilderController.strengthScore', () {
    test('empty resume scores 0', () {
      expect(ResumeBuilderController().strengthScore, 0);
    });

    test('a fully built resume scores 100', () {
      final c = ResumeBuilderController()
        ..fullName = 'Ada Lovelace'
        ..email = 'ada@example.com'
        ..phone = '0412345678'
        ..location = 'Sydney, AU'
        ..title = 'Engineer'
        ..summary = 'A' * 130
        ..linkedin = 'in/ada'
        ..addSkill('Dart')
        ..addSkill('Flutter')
        ..addSkill('SQL')
        ..addSkill('Go')
        ..addSkill('AWS')
        ..addSkill('CI/CD');
      c.experiences.first
        ..title = 'Engineer'
        ..company = 'Acme'
        ..bullets = ['Shipped X', 'Improved Y by 30%', 'Led Z'];
      c.education.first
        ..degree = 'BSc'
        ..school = 'UNSW';
      c.certifications.add('AWS SAA');
      c.languages.add('English');

      expect(c.strengthScore, 100);
    });

    test('partial resume scores between 0 and 100', () {
      final c = ResumeBuilderController()
        ..fullName = 'Ada'
        ..email = 'a@b.com';
      final s = c.strengthScore;
      expect(s, greaterThan(0));
      expect(s, lessThan(100));
    });
  });

  group('CoverLetterResult.parse', () {
    test('parses the 3-format JSON object', () {
      final r = CoverLetterResult.parse(
          '{"full_letter":"Dear...","short_email":"Hi","recruiter_msg":"Hey"}');
      expect(r.fullLetter, 'Dear...');
      expect(r.shortEmail, 'Hi');
      expect(r.recruiterMsg, 'Hey');
    });

    test('falls back to full letter when given plain prose', () {
      final r = CoverLetterResult.parse('just some text, not json');
      expect(r.fullLetter, 'just some text, not json');
      expect(r.shortEmail, '');
    });

    test('tolerates missing keys', () {
      final r = CoverLetterResult.parse('{"full_letter":"Only this"}');
      expect(r.fullLetter, 'Only this');
      expect(r.recruiterMsg, '');
    });
  });

  group('CoverLetterController', () {
    test('canGenerate requires job title and company', () {
      final c = CoverLetterController();
      expect(c.canGenerate, isFalse);
      c
        ..jobTitle = 'Engineer'
        ..companyName = 'Acme';
      expect(c.canGenerate, isTrue);
    });
  });

  group('LinkedInController', () {
    test('canGenerate requires a job title', () {
      final c = LinkedInController();
      expect(c.canGenerate, isFalse);
      c.jobTitle = 'Engineer';
      expect(c.canGenerate, isTrue);
    });

    test('each section maps to the right AI feature', () {
      expect(LinkedInSection.headline.feature, AiFeature.linkedinHeadline);
      expect(LinkedInSection.about.feature, AiFeature.linkedinAbout);
      expect(LinkedInSection.recruiter.feature, AiFeature.recruiterMessage);
      expect(LinkedInSection.skills.feature, AiFeature.skillsSuggest);
    });
  });

  group('InterviewController', () {
    test('canGenerate requires a job title', () {
      final c = InterviewController();
      expect(c.canGenerate, isFalse);
      c.jobTitle = 'Product Manager';
      expect(c.canGenerate, isTrue);
    });

    test('starts with no questions', () {
      expect(InterviewController().questions, isEmpty);
    });
  });

  group('JobApplication', () {
    test('status parse + label round-trip', () {
      for (final s in JobStatus.values) {
        expect(JobStatus.parse(s.value), s);
        expect(s.label, isNotEmpty);
      }
    });

    test('copyWith changes only the given fields', () {
      final base = JobApplication(
        id: '1', userId: 'u', companyName: 'Acme', jobTitle: 'Eng',
        applicationDate: DateTime(2026), status: JobStatus.saved,
      );
      final moved = base.copyWith(status: JobStatus.interview);
      expect(moved.status, JobStatus.interview);
      expect(moved.companyName, 'Acme');
      expect(moved.id, '1');
    });
  });

  group('JobRepository (mock mode)', () {
    test('create → list → updateStatus → delete lifecycle', () async {
      final repo = JobRepository.instance;
      final job = await repo.create(
        companyName: 'Acme', jobTitle: 'Engineer', status: JobStatus.saved);
      expect((await repo.list()).any((j) => j.id == job.id), isTrue);

      await repo.updateStatus(job.id, JobStatus.applied);
      final afterMove = (await repo.list()).firstWhere((j) => j.id == job.id);
      expect(afterMove.status, JobStatus.applied);

      await repo.delete(job.id);
      expect((await repo.list()).any((j) => j.id == job.id), isFalse);
    });
  });

  group('Document', () {
    test('DocType parse/value round-trip (cover_letter)', () {
      expect(DocType.coverLetter.value, 'cover_letter');
      expect(DocType.parse('cover_letter'), DocType.coverLetter);
      expect(DocType.parse('resume'), DocType.resume);
    });

    test('prettySize formats bytes/KB/MB', () {
      Document d(int size) => Document(
            id: '1', userId: 'u', docType: DocType.resume, fileName: 'a.pdf',
            storagePath: 'p', fileSize: size, createdAt: DateTime(2026));
      expect(d(0).prettySize, '—');
      expect(d(512).prettySize, '512 B');
      expect(d(2048).prettySize, '2.0 KB');
      expect(d(2 * 1024 * 1024).prettySize, '2.0 MB');
    });
  });

  group('Validators', () {
    test('email validation', () {
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email('good@example.com'), isNull);
    });

    test('password strength buckets 0..4', () {
      expect(Validators.passwordStrength(''), 0);
      expect(Validators.passwordStrength('aB3!xxxx'), 4);
    });

    test('phone validation', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('abc'), isNotNull);
      expect(Validators.phone('123'), isNotNull); // too short
      expect(Validators.phone('0412 345 678'), isNull);
      expect(Validators.phone('+61 (412) 345-678'), isNull);
    });

    test('username validation', () {
      expect(Validators.username(''), isNotNull);
      expect(Validators.username('ab'), isNotNull); // too short
      expect(Validators.username('has space'), isNotNull);
      expect(Validators.username('bad!char'), isNotNull);
      expect(Validators.username('ada_lovelace'), isNull);
      expect(Validators.username('user.123-x'), isNull);
    });
  });
}
