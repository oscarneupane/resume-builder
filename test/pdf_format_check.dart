// Smoke test: a full draft renders to a non-trivial ATS-format resume PDF.
// Guards against regressions in PdfService.buildResume (sections, fonts, bullets).
import 'package:flutter_test/flutter_test.dart';
import 'package:applymate/features/resume_builder/controllers/resume_builder_controller.dart';
import 'package:applymate/services/pdf_service.dart';

void main() {
  test('builds an ATS resume PDF from a full draft', () async {
    final c = ResumeBuilderController()
      ..fullName = 'Oscar Neupane'
      ..title = 'IT Support Officer'
      ..email = 'neupaneoscar143@gmail.com'
      ..phone = '+61 449 601 568'
      ..location = 'Sydney, NSW'
      ..linkedin = 'linkedin.com/in/oscar-neupane'
      ..github = 'github.com/oscarneupane'
      ..portfolio = 'portfolio-q31f.onrender.com'
      ..summary = 'Recent IT graduate with hands-on experience in IT support and web development.';

    c.skills
      ..add('IT Support: Help Desk, Active Directory, Troubleshooting')
      ..add('Development: HTML, CSS, JavaScript, Python');

    c.projects
      ..clear()
      ..add(ProjectEntry(name: 'Portfolio Website', description: 'Responsive site with admin panel'));

    c.experiences
      ..clear()
      ..add(ExperienceEntry(
        title: 'IT Support Intern',
        company: 'UTS College',
        startDate: '2025',
        endDate: '2026',
        bullets: ['Provided technical support and troubleshooting'],
      ));

    c.education
      ..clear()
      ..add(EducationEntry(degree: 'Bachelor of Information Technology', school: 'UTS', endDate: '2025'));

    final doc = await PdfService.instance.buildResume(c.toResume());
    final bytes = await PdfService.instance.save(doc);
    expect(bytes.length, greaterThan(1000));
  });
}
