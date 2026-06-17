import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/resume_model.dart';

/// Builds and exports resume PDFs. Three templates per blueprint (classic /
/// modern / minimal). Layout is intentionally simple here — refine as the
/// builder UI evolves.
class PdfService {
  PdfService._();
  static final instance = PdfService._();

  Future<pw.Document> buildResume(Resume resume) async {
    final doc = pw.Document();
    final personal = resume.section(SectionType.personal)?.content ?? const {};
    final summary = resume.section(SectionType.summary)?.content['text'] as String? ?? '';
    final experience =
        (resume.section(SectionType.experience)?.content['items'] as List?) ?? const [];
    final education =
        (resume.section(SectionType.education)?.content['items'] as List?) ?? const [];
    final skills =
        ((resume.section(SectionType.skills)?.content['items'] as List?) ?? const [])
            .map((s) => s.toString())
            .toList();

    final accent = switch (resume.template) {
      'modern' => PdfColor.fromInt(0xFF2E75B6),
      'minimal' => PdfColor.fromInt(0xFF1A1A1A),
      _ => PdfColor.fromInt(0xFF1B3A6B),
    };

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          _header(personal, accent),
          if (summary.isNotEmpty) _section('Summary', accent, pw.Text(summary)),
          if (experience.isNotEmpty)
            _section(
              'Experience',
              accent,
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: experience.map((e) => _experienceEntry(Map<String, dynamic>.from(e as Map))).toList(),
              ),
            ),
          if (education.isNotEmpty)
            _section(
              'Education',
              accent,
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: education.map((e) => _educationEntry(Map<String, dynamic>.from(e as Map))).toList(),
              ),
            ),
          if (skills.isNotEmpty) _section('Skills', accent, pw.Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in skills)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                    color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(12)),
                child: pw.Text(s, style: const pw.TextStyle(fontSize: 10)),
              )
          ])),
        ],
      ),
    );
    return doc;
  }

  Future<void> sharePdf(pw.Document doc, {String filename = 'resume.pdf'}) async {
    await Printing.sharePdf(bytes: await doc.save(), filename: filename);
  }

  pw.Widget _header(Map<String, dynamic> p, PdfColor accent) {
    final name = (p['fullName'] ?? '').toString();
    final title = (p['title'] ?? '').toString();
    final contact = [
      if ((p['email'] ?? '').toString().isNotEmpty) p['email'],
      if ((p['phone'] ?? '').toString().isNotEmpty) p['phone'],
      if ((p['location'] ?? '').toString().isNotEmpty) p['location'],
      if ((p['linkedin'] ?? '').toString().isNotEmpty) p['linkedin'],
    ].join('  •  ');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: accent)),
        if (title.isNotEmpty)
          pw.Text(title, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        if (contact.isNotEmpty) pw.SizedBox(height: 4),
        if (contact.isNotEmpty) pw.Text(contact, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _section(String title, PdfColor accent, pw.Widget child) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 8),
          pw.Text(title.toUpperCase(),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.Container(margin: const pw.EdgeInsets.symmetric(vertical: 4), height: 1, color: accent),
          child,
        ],
      );

  pw.Widget _experienceEntry(Map<String, dynamic> e) {
    final bullets = (e['bullets'] as List?)?.map((b) => b.toString()).toList() ?? const [];
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${e['title'] ?? ''} • ${e['company'] ?? ''}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.Text('${e['startDate'] ?? ''} — ${e['endDate'] ?? 'Present'}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ...bullets.map((b) => pw.Bullet(text: b, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  pw.Widget _educationEntry(Map<String, dynamic> e) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('${e['degree'] ?? ''}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text('${e['school'] ?? ''} • ${e['endDate'] ?? ''}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      );
}
