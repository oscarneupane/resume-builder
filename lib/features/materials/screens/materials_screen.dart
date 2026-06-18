import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../models/material_model.dart' as mat;
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/materials_controller.dart';

/// "My Materials" — upload pics/PDFs/notes; AI scans them into reusable data.
class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(materialsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Materials')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: c.busy ? null : () => showMaterialAddSheet(context, ref),
      ),
      body: Stack(
        children: [
          if (c.loading)
            const Center(child: CircularProgressIndicator())
          else if (c.materials.isEmpty)
            EmptyState(
              icon: Icons.auto_awesome_motion_outlined,
              title: 'No materials yet',
              subtitle: 'Upload a resume photo, a PDF, or paste notes. AI scans them so you can reuse the info anywhere.',
              action: SizedBox(width: 220, child: AppButton(label: 'Add material', icon: Icons.add, onPressed: () => showMaterialAddSheet(context, ref))),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: c.materials.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _MaterialCard(controller: c, material: c.materials[i]),
            ),
          if (c.busy)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                      SizedBox(width: 14),
                      Text('Scanning with AI…'),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet to choose an upload source. Reused by Smart Import too.
Future<void> showMaterialAddSheet(BuildContext context, WidgetRef ref) async {
  final c = ref.read(materialsControllerProvider);
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Photo from gallery'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (x == null) return;
              await c.addImage(await x.readAsBytes(), x.name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            title: const Text('Take a photo'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
              if (x == null) return;
              await c.addImage(await x.readAsBytes(), x.name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            title: const Text('PDF file'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
              if (r == null || r.files.isEmpty || r.files.first.bytes == null) return;
              final f = r.files.first;
              await c.addPdf(f.bytes!, f.name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notes_outlined, color: AppColors.primary),
            title: const Text('Paste text'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              await _showPasteDialog(context, c);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _showPasteDialog(BuildContext context, MaterialsController c) async {
  final title = TextEditingController(text: 'Notes');
  final body = TextEditingController();
  await showDialog(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('Paste text'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppTextField(label: 'Title', controller: title),
          const SizedBox(height: 10),
          AppTextField(label: 'Content', controller: body, maxLines: 6, hint: 'Paste your notes, experience, anything…'),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (body.text.trim().isEmpty) return;
            Navigator.pop(dctx);
            c.addText(title.text, body.text);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _MaterialCard extends StatelessWidget {
  final MaterialsController controller;
  final mat.Material material;
  const _MaterialCard({required this.controller, required this.material});

  IconData get _icon => switch (material.kind) {
        mat.MaterialKind.image => Icons.image_outlined,
        mat.MaterialKind.pdf => Icons.picture_as_pdf_outlined,
        mat.MaterialKind.text => Icons.notes_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text('${material.kind.label}  •  ${DateFormat('d MMM yyyy').format(material.createdAt)}', style: context.text.bodySmall),
                if (material.preview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(material.preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: () => controller.remove(material),
          ),
        ],
      ),
    );
  }
}
