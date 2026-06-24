import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../models/document_model.dart';
import '../../../services/documents_repository.dart';
import '../../../services/pdf_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../dashboard/widgets/ats_score_gauge.dart';
import '../controllers/resume_builder_controller.dart';

class ResumePreviewScreen extends ConsumerStatefulWidget {
  const ResumePreviewScreen({super.key});

  @override
  ConsumerState<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends ConsumerState<ResumePreviewScreen> {
  bool _exporting = false;

  Future<void> _export(ResumeBuilderController c) async {
    setState(() => _exporting = true);
    try {
      final doc = await PdfService.instance.buildResume(c.toResume());
      final safeName = (c.fullName.trim().isEmpty ? 'resume' : c.fullName.trim().replaceAll(RegExp(r'\s+'), '_'));
      final fileName = '$safeName.pdf';
      final bytes = await PdfService.instance.save(doc);
      // Record it in My Docs, then open the share sheet.
      await DocumentsRepository.instance.save(docType: DocType.resume, fileName: fileName, bytes: bytes);
      await PdfService.instance.shareBytes(bytes, filename: fileName);
      if (mounted) context.showSnack('Saved to My Docs');
    } catch (e) {
      if (mounted) context.showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(resumeBuilderControllerProvider);
    const accent = AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(28),
                child: _ResumeCanvas(c: c, accent: accent),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.ats),
              child: const AtsScoreGauge(score: 78, size: 60),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: AppButton(
              label: _exporting ? 'Exporting…' : 'Export PDF',
              icon: Icons.picture_as_pdf_outlined,
              loading: _exporting,
              onPressed: () => _export(c),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight on-screen rendering of the draft (mirrors the PDF layout).
class _ResumeCanvas extends StatelessWidget {
  final ResumeBuilderController c;
  final Color accent;
  const _ResumeCanvas({required this.c, required this.accent});

  @override
  Widget build(BuildContext context) {
    final name = c.fullName.trim().isEmpty ? 'Your Name' : c.fullName.trim();
    final contact = [
      if (c.location.trim().isNotEmpty) c.location.trim(),
      if (c.phone.trim().isNotEmpty) c.phone.trim(),
      if (c.email.trim().isNotEmpty) c.email.trim(),
    ].join('  |  ');
    final links = [
      if (c.linkedin.trim().isNotEmpty) 'LinkedIn: ${c.linkedin.trim()}',
      if (c.github.trim().isNotEmpty) 'GitHub: ${c.github.trim()}',
      if (c.portfolio.trim().isNotEmpty) 'Portfolio: ${c.portfolio.trim()}',
    ].join('  |  ');

    final projects = c.projects.where((p) => p.name.trim().isNotEmpty || p.description.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1)),
        if (contact.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(contact, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
        if (links.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(links, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 8),
        if (c.summary.trim().isNotEmpty)
          _section('Professional Summary', Text(c.summary.trim(), style: const TextStyle(fontSize: 13, height: 1.4))),
        if (c.skills.isNotEmpty) _section('Technical Skills', _skills()),
        if (projects.isNotEmpty)
          _section(
            'Projects',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in projects)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            children: [
                              TextSpan(text: p.name.trim(), style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (p.description.trim().isNotEmpty) TextSpan(text: ' — ${p.description.trim()}'),
                            ],
                          ),
                        ),
                        if (p.link.trim().isNotEmpty)
                          Text(p.link.trim(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (c.experiences.any((e) => e.title.trim().isNotEmpty || e.company.trim().isNotEmpty))
          _section(
            'Experience',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in c.experiences.where((e) => e.title.trim().isNotEmpty || e.company.trim().isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text([e.title, e.company].where((s) => s.trim().isNotEmpty).join(' — '),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${e.startDate} – ${e.current ? 'Present' : e.endDate}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        for (final b in e.bullets.where((b) => b.trim().isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 8),
                            child: Text('• ${b.trim()}', style: const TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (c.education.any((e) => e.degree.trim().isNotEmpty || e.school.trim().isNotEmpty))
          _section(
            'Education',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in c.education.where((e) => e.degree.trim().isNotEmpty || e.school.trim().isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (e.degree.trim().isNotEmpty)
                          Text(e.degree, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text([e.school, e.endDate].where((s) => s.trim().isNotEmpty).join('  •  '),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _skills() {
    final grouped = c.skills.where((s) => s.contains(':')).toList();
    final plain = c.skills.where((s) => !s.contains(':')).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in grouped)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: '${g.substring(0, g.indexOf(':')).trim()}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: g.substring(g.indexOf(':') + 1).trim()),
                ],
              ),
            ),
          ),
        if (plain.isNotEmpty) Text(plain.join(', '), style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }

  Widget _section(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title.toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent, letterSpacing: 0.5)),
          Container(margin: const EdgeInsets.only(top: 2, bottom: 6), height: 1, color: accent),
          child,
        ],
      );
}
