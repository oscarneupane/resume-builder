import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';

class ResumeListScreen extends StatelessWidget {
  const ResumeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Resumes')),
      body: EmptyState(
        icon: Icons.description_outlined,
        title: 'No resumes yet',
        subtitle: 'Create your first resume to get started.',
        action: SizedBox(
          width: 220,
          child: AppButton(
            label: 'Create new resume',
            icon: Icons.add,
            onPressed: () => context.push(AppRoutes.resumeBuilder),
          ),
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
