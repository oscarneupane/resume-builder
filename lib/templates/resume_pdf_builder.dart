import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/resume_data.dart';
import '../theme/app_theme.dart';

/// Builds a printable PDF document for the resume, with a different layout
/// per template id (1 = Classic, 2 = Modern, 3 = Minimal).
class ResumePdfBuilder {
  static Future<pw.Document> build(ResumeData data) async {
    final doc = pw.Document();
    final style = TemplateStyle.byId(data.selectedTemplate == 0 ? 1 : data.selectedTemplate);
    final color = PdfColor.fromInt(style.primaryColor.value);
    final accent = PdfColor.fromInt(style.accentColor.value);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          switch (style.id) {
            case 2:
              return _buildModernLayout(data, color, accent);
            case 3:
              return _buildMinimalLayout(data, color, accent);
            default:
              return _buildClassicLayout(data, color, accent);
          }
        },
      ),
    );

    return doc;
  }

  static pw.Widget _header(ResumeData data, PdfColor color, {pw.CrossAxisAlignment align = pw.CrossAxisAlignment.start}) {
    final info = data.personalInfo;
    return pw.Column(
      crossAxisAlignment: align,
      children: [
        pw.Text(
          info.fullName.isEmpty ? 'Your Name' : info.fullName,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          [info.email, info.phone, info.location, info.linkedIn].where((s) => s.isNotEmpty).join('   |   '),
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color, letterSpacing: 1),
          ),
          pw.Divider(color: color, thickness: 1),
        ],
      ),
    );
  }

  static pw.Widget _experienceBlock(ResumeData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: data.experience.map((exp) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${exp.role}, ${exp.company}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('${exp.startDate} - ${exp.endDate}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              ...exp.bullets.where((b) => b.trim().isNotEmpty).map(
                (b) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, top: 2),
                  child: pw.Bullet(text: b, style: const pw.TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _educationBlock(ResumeData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: data.education.map((edu) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${edu.degree}${edu.fieldOfStudy.isNotEmpty ? ', ${edu.fieldOfStudy}' : ''}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                  pw.Text(edu.institution, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Text('${edu.startDate} - ${edu.endDate}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _skillsBlock(ResumeData data, PdfColor accent) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: data.skills.map((s) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(s, style: pw.TextStyle(fontSize: 9, color: accent)),
        );
      }).toList(),
    );
  }

  // Template 1: single column, centered header, classic ordering.
  static pw.Widget _buildClassicLayout(ResumeData data, PdfColor color, PdfColor accent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(child: _header(data, color, align: pw.CrossAxisAlignment.center)),
        if (data.personalInfo.summary.isNotEmpty) ...[
          _sectionTitle('Summary', color),
          pw.Text(data.personalInfo.summary, style: const pw.TextStyle(fontSize: 10)),
        ],
        if (data.experience.isNotEmpty) ...[
          _sectionTitle('Experience', color),
          _experienceBlock(data),
        ],
        if (data.education.isNotEmpty) ...[
          _sectionTitle('Education', color),
          _educationBlock(data),
        ],
        if (data.skills.isNotEmpty) ...[
          _sectionTitle('Skills', color),
          _skillsBlock(data, accent),
        ],
      ],
    );
  }

  // Template 2: left-aligned header with accent underline, two-column body.
  static pw.Widget _buildModernLayout(ResumeData data, PdfColor color, PdfColor accent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: accent, width: 2))),
          child: _header(data, color),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (data.experience.isNotEmpty) ...[
                    _sectionTitle('Experience', color),
                    _experienceBlock(data),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (data.personalInfo.summary.isNotEmpty) ...[
                    _sectionTitle('Summary', color),
                    pw.Text(data.personalInfo.summary, style: const pw.TextStyle(fontSize: 9)),
                  ],
                  if (data.skills.isNotEmpty) ...[
                    _sectionTitle('Skills', color),
                    _skillsBlock(data, accent),
                  ],
                  if (data.education.isNotEmpty) ...[
                    _sectionTitle('Education', color),
                    _educationBlock(data),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Template 3: grayscale, single column, generous whitespace, ATS-friendly.
  static pw.Widget _buildMinimalLayout(ResumeData data, PdfColor color, PdfColor accent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header(data, color),
        pw.SizedBox(height: 12),
        if (data.personalInfo.summary.isNotEmpty) ...[
          pw.Text(data.personalInfo.summary, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
          pw.SizedBox(height: 12),
        ],
        if (data.experience.isNotEmpty) ...[
          _sectionTitle('Experience', color),
          _experienceBlock(data),
        ],
        if (data.education.isNotEmpty) ...[
          _sectionTitle('Education', color),
          _educationBlock(data),
        ],
        if (data.skills.isNotEmpty) ...[
          _sectionTitle('Skills', color),
          _skillsBlock(data, accent),
        ],
      ],
    );
  }
}
