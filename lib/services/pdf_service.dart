import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/resume_model.dart';

/// Builds and exports resume PDFs in a single clean, ATS-friendly layout
/// (single column, centered header, uppercase section rules) — the content is
/// generated/enriched by AI rather than chosen from visual templates.
class PdfService {
  PdfService._();
  static final instance = PdfService._();

  // Plain dark ink — maximally ATS/print friendly.
  static const _ink = PdfColor.fromInt(0xFF1A1A1A);

  Future<pw.Document> buildResume(Resume resume) async {
    final doc = pw.Document();
    final personal = resume.section(SectionType.personal)?.content ?? const {};
    final summary = resume.section(SectionType.summary)?.content['text'] as String? ?? '';
    final skills =
        ((resume.section(SectionType.skills)?.content['items'] as List?) ?? const [])
            .map((s) => s.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
    final projects =
        (resume.section(SectionType.projects)?.content['items'] as List?) ?? const [];
    final experience =
        (resume.section(SectionType.experience)?.content['items'] as List?) ?? const [];
    final education =
        (resume.section(SectionType.education)?.content['items'] as List?) ?? const [];

    // Embed a Unicode font so en/em dashes and bullets render. The built-in
    // Helvetica can't draw them. Falls back to the default font if offline.
    pw.ThemeData? theme;
    try {
      theme = pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
      );
    } catch (_) {/* offline — built-in font; ASCII separators still render */}

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 40, 44, 40),
        theme: theme,
        build: (ctx) => [
          _header(personal),
          if (summary.trim().isNotEmpty)
            _section('Professional Summary',
                pw.Text(summary.trim(), style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2))),
          if (skills.isNotEmpty) _section('Technical Skills', _skillsBlock(skills)),
          if (projects.isNotEmpty)
            _section(
              'Projects',
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: projects.map((p) => _projectEntry(Map<String, dynamic>.from(p as Map))).toList(),
              ),
            ),
          if (experience.isNotEmpty)
            _section(
              'Experience',
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: experience.map((e) => _experienceEntry(Map<String, dynamic>.from(e as Map))).toList(),
              ),
            ),
          if (education.isNotEmpty)
            _section(
              'Education',
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: education.map((e) => _educationEntry(Map<String, dynamic>.from(e as Map))).toList(),
              ),
            ),
        ],
      ),
    );
    return doc;
  }

  /// Render the document to PDF bytes (for saving + sharing without rebuilding).
  Future<Uint8List> save(pw.Document doc) => doc.save();

  Future<void> shareBytes(Uint8List bytes, {String filename = 'document.pdf'}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> sharePdf(pw.Document doc, {String filename = 'resume.pdf'}) async {
    await Printing.sharePdf(bytes: await doc.save(), filename: filename);
  }

  pw.Widget _header(Map<String, dynamic> p) {
    String g(String k) => (p[k] ?? '').toString().trim();
    final name = g('fullName').isEmpty ? 'Your Name' : g('fullName');
    final contact = [
      if (g('location').isNotEmpty) g('location'),
      if (g('phone').isNotEmpty) g('phone'),
      if (g('email').isNotEmpty) g('email'),
    ].join('  |  ');
    final links = [
      if (g('linkedin').isNotEmpty) 'LinkedIn: ${g('linkedin')}',
      if (g('github').isNotEmpty) 'GitHub: ${g('github')}',
      if (g('portfolio').isNotEmpty) 'Portfolio: ${g('portfolio')}',
    ].join('  |  ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(name.toUpperCase(),
            style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _ink, letterSpacing: 1)),
        if (contact.isNotEmpty) pw.SizedBox(height: 4),
        if (contact.isNotEmpty)
          pw.Text(contact, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
        if (links.isNotEmpty) pw.SizedBox(height: 2),
        if (links.isNotEmpty)
          pw.Text(links,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
        pw.SizedBox(height: 6),
      ],
    );
  }

  /// Technical Skills as category lines: "Category: a, b, c" renders the label
  /// in bold; plain entries fall back to a single comma-joined line.
  pw.Widget _skillsBlock(List<String> skills) {
    final grouped = <String>[];
    final plain = <String>[];
    for (final s in skills) {
      (s.contains(':') ? grouped : plain).add(s.trim());
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final g in grouped)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(fontSize: 10, color: _ink),
                children: [
                  pw.TextSpan(
                    text: '${g.substring(0, g.indexOf(':')).trim()}: ',
                    style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(text: g.substring(g.indexOf(':') + 1).trim()),
                ],
              ),
            ),
          ),
        if (plain.isNotEmpty)
          pw.Text(plain.join(', '), style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _projectEntry(Map<String, dynamic> p) {
    final name = (p['name'] ?? '').toString();
    final desc = (p['description'] ?? '').toString();
    final link = (p['link'] ?? '').toString();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 10.5, color: _ink),
              children: [
                pw.TextSpan(text: name, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (desc.isNotEmpty) pw.TextSpan(text: ' - $desc'),
              ],
            ),
          ),
          if (link.isNotEmpty)
            pw.Text(link, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  /// Builds a simple, ATS-friendly cover-letter PDF from plain body text.
  Future<pw.Document> buildCoverLetter({
    required String body,
    String? senderName,
    String? jobTitle,
    String? companyName,
  }) async {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFF1B3A6B);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (ctx) => [
          if ((senderName ?? '').isNotEmpty)
            pw.Text(senderName!, style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: accent)),
          if ((jobTitle ?? '').isNotEmpty || (companyName ?? '').isNotEmpty)
            pw.Text(
              [if ((jobTitle ?? '').isNotEmpty) jobTitle, if ((companyName ?? '').isNotEmpty) companyName].join(' • '),
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          pw.SizedBox(height: 20),
          // Preserve the writer's paragraph breaks.
          for (final para in body.split('\n'))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(para, style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
            ),
        ],
      ),
    );
    return doc;
  }

  pw.Widget _section(String title, pw.Widget child) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 10),
          pw.Text(title.toUpperCase(),
              style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink, letterSpacing: 0.5)),
          pw.Container(margin: const pw.EdgeInsets.only(top: 2, bottom: 5), height: 0.8, color: _ink),
          child,
        ],
      );

  pw.Widget _experienceEntry(Map<String, dynamic> e) {
    final bullets = (e['bullets'] as List?)?.map((b) => b.toString()).where((b) => b.trim().isNotEmpty).toList() ?? const [];
    final title = (e['title'] ?? '').toString();
    final company = (e['company'] ?? '').toString();
    final heading = [title, company].where((s) => s.isNotEmpty).join(' - ');
    final dates = '${e['startDate'] ?? ''} - ${e['endDate'] ?? 'Present'}';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(heading,
                    style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
              ),
              if (dates.trim() != '-')
                pw.Text(dates, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
            ],
          ),
          ...bullets.map(_bullet),
        ],
      ),
    );
  }

  /// A bullet drawn as a small filled dot — independent of font glyph support.
  pw.Widget _bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: 6, top: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 2.4,
              height: 2.4,
              margin: const pw.EdgeInsets.only(top: 3.5, right: 5),
              decoration: const pw.BoxDecoration(color: _ink, shape: pw.BoxShape.circle),
            ),
            pw.Expanded(
              child: pw.Text(text, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
            ),
          ],
        ),
      );

  pw.Widget _educationEntry(Map<String, dynamic> e) {
    final degree = (e['degree'] ?? '').toString();
    final school = (e['school'] ?? '').toString();
    final dates = [e['startDate'], e['endDate']].where((d) => (d ?? '').toString().trim().isNotEmpty).join(' - ');
    final right = [if (school.isNotEmpty) school, if (dates.isNotEmpty) dates].join('  |  ');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (degree.isNotEmpty)
            pw.Text(degree, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
          if (right.isNotEmpty)
            pw.Text(right, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
        ],
      ),
    );
  }
}
