import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/resume_import.dart';

class ResumeListScreen extends ConsumerWidget {
  const ResumeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Import'),
            onPressed: () => showResumeImportSheet(context, ref),
          ),
        ],
      ),
      body: EmptyState(
        icon: Icons.description_outlined,
        title: 'No resumes yet',
        subtitle: 'Create from scratch, or import an existing resume and let AI fill it in.',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              child: AppButton(
                label: 'Create new resume',
                icon: Icons.add,
                onPressed: () => context.push(AppRoutes.resumeBuilder),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 240,
              child: AppButton(
                label: 'Import from a file',
                icon: Icons.auto_awesome,
                variant: AppButtonVariant.secondary,
                onPressed: () => showResumeImportSheet(context, ref),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New'),
        onPressed: () => context.push(AppRoutes.resumeBuilder),
      ),
    );
  }
}
