import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../models/document_model.dart';
import '../../../services/documents_repository.dart';
import '../../../services/pdf_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../materials/controllers/materials_controller.dart';
import '../controllers/cover_letter_controller.dart';

/// Lets the user attach a saved Material as background the AI uses when writing.
class _BackgroundPicker extends StatelessWidget {
  final CoverLetterController c;
  final WidgetRef parentRef;
  const _BackgroundPicker({required this.c, required this.parentRef});

  @override
  Widget build(BuildContext context) {
    if (c.backgroundLabel != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Using: ${c.backgroundLabel}', style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
            GestureDetector(onTap: c.clearBackground, child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: const Text('Use one of my materials'),
      onPressed: () {
        final mats = parentRef.read(materialsControllerProvider).materials;
        if (mats.isEmpty) {
          context.showSnack('No saved materials yet — add one in Resources.');
          return;
        }
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (sheetCtx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(padding: EdgeInsets.all(16), child: Text('Use which material?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                for (final m in mats)
                  ListTile(
                    title: Text(m.title),
                    subtitle: Text(m.preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      c.attachBackground(m.title, m.extractedText);
                      Navigator.pop(sheetCtx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CoverLetterScreen extends ConsumerWidget {
  const CoverLetterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(coverLetterControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cover Letter Builder')),
      body: c.result == null ? _InputForm(c, ref) : _OutputView(c),
    );
  }
}

class _InputForm extends StatelessWidget {
  final CoverLetterController c;
  final WidgetRef ref;
  const _InputForm(this.c, this.ref);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _BackgroundPicker(c: c, parentRef: ref),
        const SizedBox(height: 12),
        AppTextField(label: 'Job title', initialValue: c.jobTitle, onChanged: c.setJobTitle),
        const SizedBox(height: 12),
        AppTextField(label: 'Company name', initialValue: c.companyName, onChanged: c.setCompanyName),
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
      final fileName = '$name.pdf';
      final bytes = await PdfService.instance.save(doc);
      await DocumentsRepository.instance.save(docType: DocType.coverLetter, fileName: fileName, bytes: bytes);
      await PdfService.instance.shareBytes(bytes, filename: fileName);
      if (context.mounted) context.showSnack('Saved to My Docs');
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
