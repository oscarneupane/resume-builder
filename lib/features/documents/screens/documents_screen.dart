import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../models/document_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/documents_controller.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(documentsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.loading ? null : c.load,
          ),
        ],
      ),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : c.documents.isEmpty
              ? _Empty(onCreate: () => context.push(AppRoutes.resumeBuilder))
              : RefreshIndicator(
                  onRefresh: c.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: c.documents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _DocCard(controller: c, doc: c.documents[i]),
                  ),
                ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final DocumentsController controller;
  final Document doc;
  const _DocCard({required this.controller, required this.doc});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () => controller.open(doc),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${doc.docType.label}  •  ${DateFormat('d MMM yyyy').format(doc.createdAt)}  •  ${doc.prettySize}',
                      style: context.text.bodySmall),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (v) {
                if (v == 'open') controller.open(doc);
                if (v == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'open', child: Text('Open / Share')),
                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('“${doc.fileName}” will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              controller.remove(doc);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;
  const _Empty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.folder_outlined,
      title: 'No documents yet',
      subtitle: 'Export a resume or cover letter and it will appear here.',
      action: SizedBox(
        width: 220,
        child: AppButton(label: 'Create a resume', icon: Icons.add, onPressed: onCreate),
      ),
    );
  }
}
