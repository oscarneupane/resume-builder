import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../models/job_application_model.dart';

class JobTrackerScreen extends StatelessWidget {
  const JobTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statuses = JobStatus.values;
    return Scaffold(
      appBar: AppBar(title: const Text('Job Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: statuses
            .map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: _color(s), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(s.label, style: context.text.titleLarge),
                      const Spacer(),
                      const Text('0', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _color(JobStatus s) => switch (s) {
        JobStatus.saved => AppColors.textSecondary,
        JobStatus.applied => AppColors.accent,
        JobStatus.interview => AppColors.warning,
        JobStatus.offer => AppColors.success,
        JobStatus.rejected => AppColors.error,
      };
}
