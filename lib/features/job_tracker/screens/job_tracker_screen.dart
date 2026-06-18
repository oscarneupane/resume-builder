import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../models/job_application_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/job_tracker_controller.dart';

class JobTrackerScreen extends ConsumerWidget {
  const JobTrackerScreen({super.key});

  static Color statusColor(JobStatus s) => switch (s) {
        JobStatus.saved => AppColors.textSecondary,
        JobStatus.applied => AppColors.accent,
        JobStatus.interview => AppColors.warning,
        JobStatus.offer => AppColors.success,
        JobStatus.rejected => AppColors.error,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(jobTrackerControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Tracker'),
        actions: [
          if (c.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${c.total} total', style: context.text.bodySmall)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: () => _showAddSheet(context, ref),
      ),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : c.total == 0
              ? _EmptyBoard(onAdd: () => _showAddSheet(context, ref))
              : _Board(controller: c),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddJobSheet(onSubmit: (company, title, status, notes) {
        ref.read(jobTrackerControllerProvider).add(
              companyName: company,
              jobTitle: title,
              status: status,
              notes: notes,
            );
      }),
    );
  }
}

class _Board extends StatelessWidget {
  final JobTrackerController controller;
  const _Board({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: JobStatus.values.map((s) => _Column(controller: controller, status: s)).toList(),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final JobTrackerController controller;
  final JobStatus status;
  const _Column({required this.controller, required this.status});

  @override
  Widget build(BuildContext context) {
    final jobs = controller.byStatus(status);
    final color = JobTrackerScreen.statusColor(status);
    return Container(
      width: 268,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(status.label, style: context.text.titleLarge),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text('${jobs.length}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (jobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Nothing here yet', style: context.text.bodySmall),
            )
          else
            ...jobs.map((j) => _JobCard(controller: controller, job: j)),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobTrackerController controller;
  final JobApplication job;
  const _JobCard({required this.controller, required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(job.jobTitle, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              _CardMenu(controller: controller, job: job),
            ],
          ),
          Text(job.companyName, style: context.text.bodySmall),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(DateFormat('d MMM yyyy').format(job.applicationDate), style: context.text.bodySmall),
            ],
          ),
          if ((job.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(job.notes!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final JobTrackerController controller;
  final JobApplication job;
  const _CardMenu({required this.controller, required this.job});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'delete') {
          controller.remove(job);
        } else {
          controller.move(job, JobStatus.parse(value));
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(enabled: false, child: Text('Move to', style: TextStyle(fontSize: 12))),
        ...JobStatus.values.where((s) => s != job.status).map(
              (s) => PopupMenuItem(value: s.value, child: Text(s.label)),
            ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBoard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Track your applications', style: context.text.titleLarge),
            const SizedBox(height: 6),
            Text('Add a job to start your pipeline: Saved → Applied → Interview → Offer.',
                textAlign: TextAlign.center, style: context.text.bodySmall),
            const SizedBox(height: 16),
            SizedBox(width: 220, child: AppButton(label: 'Add application', icon: Icons.add, onPressed: onAdd)),
          ],
        ),
      ),
    );
  }
}

class _AddJobSheet extends StatefulWidget {
  final void Function(String company, String title, JobStatus status, String? notes) onSubmit;
  const _AddJobSheet({required this.onSubmit});

  @override
  State<_AddJobSheet> createState() => _AddJobSheetState();
}

class _AddJobSheetState extends State<_AddJobSheet> {
  final _company = TextEditingController();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  JobStatus _status = JobStatus.saved;

  @override
  void dispose() {
    _company.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _valid => _company.text.trim().isNotEmpty && _title.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add application', style: context.text.titleLarge),
          const SizedBox(height: 16),
          AppTextField(label: 'Company', controller: _company, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: 'Job title', controller: _title, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          Text('Status', style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: JobStatus.values.map((s) {
              final sel = _status == s;
              return ChoiceChip(
                label: Text(s.label),
                selected: sel,
                onSelected: (_) => setState(() => _status = s),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
                backgroundColor: AppColors.cardSurface,
                side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Notes (optional)', controller: _notes, maxLines: 2),
          const SizedBox(height: 20),
          AppButton(
            label: 'Add to tracker',
            onPressed: _valid
                ? () {
                    widget.onSubmit(
                      _company.text.trim(),
                      _title.text.trim(),
                      _status,
                      _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                    );
                    Navigator.of(context).pop();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
