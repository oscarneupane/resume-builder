import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: EmptyState(
        icon: Icons.folder_outlined,
        title: 'No documents yet',
        subtitle: 'Create a resume or cover letter to see it here.',
        action: SizedBox(
          width: 220,
          child: AppButton(
            label: 'Create new resume',
            icon: Icons.add,
            onPressed: () => context.push(AppRoutes.resumeBuilder),
          ),
        ),
      ),
    );
  }
}
