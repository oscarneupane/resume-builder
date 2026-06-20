import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../models/document_model.dart';
import '../../../services/ai_service.dart';
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
        // Primary path: screenshot a job ad → AI writes the letter from it + your details.
        AppButton(
          label: 'Scan a job post',
          icon: Icons.document_scanner_outlined,
          onPressed: () => _scanJobPost(context, ref, c),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Screenshot a job ad — AI reads it and writes the letter using your saved details.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('or fill in manually', style: context.text.bodySmall),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 16),
        _BackgroundPicker(c: c, parentRef: ref),
        const SizedBox(height: 12),
        AppTextField(
          key: ValueKey('cl-title-${c.jobTitle.hashCode}'),
          label: 'Job title',
          initialValue: c.jobTitle,
          onChanged: c.setJobTitle,
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: ValueKey('cl-company-${c.companyName.hashCode}'),
          label: 'Company name',
          initialValue: c.companyName,
          onChanged: c.setCompanyName,
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: ValueKey('cl-skills-${c.skills.hashCode}'),
          label: 'Key skills (optional)',
          hint: 'e.g. Flutter, leadership, data analysis',
          initialValue: c.skills,
          onChanged: (v) => c.skills = v,
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: ValueKey('cl-jd-${c.jobDescription.hashCode}'),
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

/// Lets the user pick a job-post source (screenshot/photo, PDF, or pasted text),
/// then scans it and writes the cover letter in one go.
Future<void> _scanJobPost(BuildContext context, WidgetRef ref, CoverLetterController c) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Scan a job post from…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Screenshot or photo'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
              if (x == null) return;
              final bytes = await x.readAsBytes();
              if (context.mounted) {
                await _runJobScan(context, ref, c, () => AiService.instance.scanJobPost(imageBytes: bytes));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            title: const Text('PDF'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
              if (r == null || r.files.isEmpty || r.files.first.bytes == null) return;
              if (context.mounted) {
                await _runJobScan(context, ref, c, () => AiService.instance.scanJobPost(pdfBytes: r.files.first.bytes!));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notes_outlined, color: AppColors.primary),
            title: const Text('Paste text'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final text = await _pasteJobDialog(context);
              if (text == null || text.trim().isEmpty) return;
              if (context.mounted) {
                await _runJobScan(context, ref, c, () => AiService.instance.scanJobPost(text: text));
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _runJobScan(
  BuildContext context,
  WidgetRef ref,
  CoverLetterController c,
  Future<AiResult> Function() scan,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
            SizedBox(width: 14),
            Text('Reading the job post…'),
          ]),
        ),
      ),
    ),
  );

  final res = await scan();
  if (!res.isOk || res.text == null) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) context.showSnack(res.error ?? 'Could not read the job post.');
    return;
  }

  Map<String, dynamic> data;
  try {
    data = jsonDecode(res.text!) as Map<String, dynamic>;
  } catch (_) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) context.showSnack('Could not read the job post. Try a clearer screenshot.');
    return;
  }

  c.applyJobScan(data);

  // "The app has your details": attach your most recent saved material as
  // background so the letter is personalised without re-entering anything.
  final mats = ref.read(materialsControllerProvider).materials;
  if (c.backgroundLabel == null && mats.isNotEmpty) {
    c.attachBackground(mats.first.title, mats.first.extractedText);
  }

  // Enough to write the letter → do it now (one tap from screenshot to result).
  if (c.canGenerate) await c.generate();

  if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // close progress
  if (!context.mounted) return;
  if (c.result == null) {
    context.showSnack(c.canGenerate
        ? (c.error ?? 'Could not write the letter. Try again.')
        : 'Scanned — add the job title and company, then tap Generate.');
  }
}

Future<String?> _pasteJobDialog(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('Paste the job post'),
      content: TextField(
        controller: ctrl,
        maxLines: 8,
        decoration: const InputDecoration(hintText: 'Paste the job ad / description here…'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dctx, ctrl.text), child: const Text('Scan')),
      ],
    ),
  );
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
