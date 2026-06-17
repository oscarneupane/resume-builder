import 'package:flutter_test/flutter_test.dart';

import 'package:applymate/core/constants.dart';
import 'package:applymate/features/cover_letter/controllers/cover_letter_controller.dart';
import 'package:applymate/features/resume_builder/controllers/resume_builder_controller.dart';
import 'package:applymate/models/resume_model.dart';
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
