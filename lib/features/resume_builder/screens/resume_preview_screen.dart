import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../services/pdf_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../dashboard/widgets/ats_score_gauge.dart';
import '../controllers/resume_builder_controller.dart';
import 'resume_builder_screen.dart' show TemplateOption;

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
      await PdfService.instance.sharePdf(doc, filename: '$safeName.pdf');
    } catch (e) {
      if (mounted) context.showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openTemplateDrawer(ResumeBuilderController c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose a template', style: context.text.titleLarge),
            const SizedBox(height: 16),
            for (final t in AppConstants.availableTemplates)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TemplateOption(
                  name: t,
                  selected: c.template == t,
                  onTap: () {
                    c.setTemplate(t);
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(resumeBuilderControllerProvider);
    final accent = switch (c.template) {
      'modern' => AppColors.accent,
      'minimal' => AppColors.textPrimary,
      _ => AppColors.primary,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            tooltip: 'Change template',
            icon: const Icon(Icons.style_outlined),
            onPressed: () => _openTemplateDrawer(c),
          ),
        ],
      ),
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
      if (c.email.trim().isNotEmpty) c.email.trim(),
      if (c.phone.trim().isNotEmpty) c.phone.trim(),
      if (c.location.trim().isNotEmpty) c.location.trim(),
      if (c.linkedin.trim().isNotEmpty) c.linkedin.trim(),
    ].join('  •  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: accent)),
        if (c.title.trim().isNotEmpty)
          Text(c.title.trim(), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        if (contact.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(contact, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 12),
        if (c.summary.trim().isNotEmpty) _section('Summary', Text(c.summary.trim())),
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
                        Text('${e.title} • ${e.company}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${e.startDate} — ${e.current ? 'Present' : e.endDate}',
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
                        Text(e.degree, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${e.school} • ${e.endDate}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (c.skills.isNotEmpty)
          _section(
            'Skills',
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: c.skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _section(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(title.toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent)),
          Container(margin: const EdgeInsets.symmetric(vertical: 4), height: 1, color: accent.withValues(alpha: 0.4)),
          child,
        ],
      );
}
