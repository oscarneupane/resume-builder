import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../services/pdf_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/cover_letter_controller.dart';

class CoverLetterScreen extends ConsumerWidget {
  const CoverLetterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(coverLetterControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cover Letter Builder')),
      body: c.result == null ? _InputForm(c) : _OutputView(c),
    );
  }
}

class _InputForm extends StatelessWidget {
  final CoverLetterController c;
  const _InputForm(this.c);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppTextField(label: 'Job title', initialValue: c.jobTitle, onChanged: (v) => c.jobTitle = v),
        const SizedBox(height: 12),
        AppTextField(label: 'Company name', initialValue: c.companyName, onChanged: (v) => c.companyName = v),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Key skills (optional)',
          hint: 'e.g. Flutter, leadership, data analysis',
          initialValue: c.skills,
          onChanged: (v) => c.skills = v,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Job description (optional)',
          hint: 'Paste the JD to tailor the letter',
          maxLines: 5,
          initialValue: c.jobDescription,
          onChanged: (v) => c.jobDescription = v,
        ),
        const SizedBox(height: 20),
        Text('Tone', style: context.text.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: CoverLetterTone.values.map((t) {
            final sel = c.tone == t;
            return ChoiceChip(
              label: Text(t.label),
              selected: sel,
              onSelected: (_) => c.setTone(t),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
              backgroundColor: AppColors.cardSurface,
              side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        if (c.error != null) ...[
          _ErrorBox(c.error!),
          const SizedBox(height: 12),
        ],
        AppButton(
          label: 'Generate Cover Letter',
          icon: Icons.auto_awesome,
          loading: c.loading,
          onPressed: c.canGenerate ? c.generate : null,
        ),
        if (!c.canGenerate)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text('Enter a job title and company to continue.', style: context.text.bodySmall),
            ),
          ),
      ],
    );
  }
}

class _OutputView extends StatelessWidget {
  final CoverLetterController c;
  const _OutputView(this.c);

  @override
  Widget build(BuildContext context) {
    final r = c.result!;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Full Letter'),
              Tab(text: 'Short Email'),
              Tab(text: 'Recruiter'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _LetterTab(c: c, text: r.fullLetter, exportable: true),
                _LetterTab(c: c, text: r.shortEmail, exportable: false),
                _LetterTab(c: c, text: r.recruiterMsg, exportable: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterTab extends StatelessWidget {
  final CoverLetterController c;
  final String text;
  final bool exportable;
  const _LetterTab({required this.c, required this.text, required this.exportable});

  Future<void> _export(BuildContext context) async {
    try {
      final doc = await PdfService.instance.buildCoverLetter(
        body: text,
        jobTitle: c.jobTitle,
        companyName: c.companyName,
      );
      final name = c.companyName.trim().isEmpty
          ? 'cover_letter'
          : 'cover_letter_${c.companyName.trim().replaceAll(RegExp(r"\s+"), "_")}';
      await PdfService.instance.sharePdf(doc, filename: '$name.pdf');
    } catch (e) {
      if (context.mounted) context.showSnack('Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SelectableText(
              text.trim().isEmpty ? 'No content for this format.' : text,
              style: context.text.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('$wordCount words', style: context.text.bodySmall),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Copy',
                    icon: Icons.copy_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: text.trim().isEmpty
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: text));
                            context.showSnack('Copied to clipboard');
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Regenerate',
                    icon: Icons.refresh,
                    variant: AppButtonVariant.secondary,
                    loading: c.loading,
                    onPressed: c.generate,
                  ),
                ),
                if (exportable) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Export',
                      icon: Icons.picture_as_pdf_outlined,
                      onPressed: text.trim().isEmpty ? null : () => _export(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}
