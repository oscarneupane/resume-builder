import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../dashboard/widgets/ats_score_gauge.dart';

class ResumePreviewScreen extends StatelessWidget {
  const ResumePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(icon: const Icon(Icons.style_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your Name', style: context.text.displaySmall),
                  Text('Your Title', style: context.text.bodySmall),
                  const Divider(height: 24),
                  Text('SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('Your summary goes here…', style: context.text.bodyMedium),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.ats),
              child: const AtsScoreGauge(score: 78, size: 64),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: AppButton(label: 'Export PDF', icon: Icons.picture_as_pdf_outlined, onPressed: () {}),
          ),
        ],
      ),
    );
  }
}
