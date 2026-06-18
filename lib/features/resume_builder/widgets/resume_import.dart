import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../services/ai_service.dart';
import '../../materials/controllers/materials_controller.dart';
import '../controllers/resume_builder_controller.dart';

/// Smart Import: pick a source, AI extracts structured resume data, pre-fill the
/// builder, then open it.
Future<void> showResumeImportSheet(BuildContext context, WidgetRef ref) async {
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
              child: Text('Autofill from…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Resume photo'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (x == null) return;
              final bytes = await x.readAsBytes();
              if (context.mounted) await _run(context, ref, () => AiService.instance.scanToResume(imageBytes: bytes));
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            title: const Text('Resume PDF'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
              if (r == null || r.files.isEmpty || r.files.first.bytes == null) return;
              await _run(context, ref, () => AiService.instance.scanToResume(pdfBytes: r.files.first.bytes!));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notes_outlined, color: AppColors.primary),
            title: const Text('Paste text'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final text = await _pasteDialog(context);
              if (text == null || text.trim().isEmpty) return;
              await _run(context, ref, () => AiService.instance.scanToResume(text: text));
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_motion_outlined, color: AppColors.primary),
            title: const Text('A saved material'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              await _pickMaterial(context, ref);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _pickMaterial(BuildContext context, WidgetRef ref) async {
  final mats = ref.read(materialsControllerProvider).materials;
  if (mats.isEmpty) {
    context.showSnack('No saved materials yet — add one in Resources.');
    return;
  }
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetCtx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Use which material?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          for (final m in mats)
            ListTile(
              title: Text(m.title),
              subtitle: Text(m.preview, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _run(context, ref, () => AiService.instance.scanToResume(text: m.extractedText));
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _run(BuildContext context, WidgetRef ref, Future<AiResult> Function() scan) async {
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
            Text('Reading your resume…'),
          ]),
        ),
      ),
    ),
  );
  final res = await scan();
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // close progress
  if (!res.isOk || res.text == null) {
    if (context.mounted) context.showSnack(res.error ?? 'Could not read the file.');
    return;
  }
  try {
    final data = jsonDecode(res.text!) as Map<String, dynamic>;
    ref.read(resumeBuilderControllerProvider).applyExtracted(data);
    if (context.mounted) {
      context.showSnack('Imported — review and edit your details.');
      context.push(AppRoutes.resumeBuilder);
    }
  } catch (_) {
    if (context.mounted) context.showSnack('Could not parse the extracted data.');
  }
}

Future<String?> _pasteDialog(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('Paste resume text'),
      content: TextField(
        controller: ctrl,
        maxLines: 8,
        decoration: const InputDecoration(hintText: 'Paste your existing resume or details…'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dctx, ctrl.text), child: const Text('Import')),
      ],
    ),
  );
}
