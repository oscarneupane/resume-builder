import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/interview_controller.dart';

class InterviewScreen extends ConsumerWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(interviewControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Prep')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        label: 'Job title',
                        hint: 'e.g. Product Manager',
                        initialValue: c.jobTitle,
                        onChanged: c.setJobTitle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'Level',
                        hint: 'Mid',
                        initialValue: c.experienceLevel,
                        onChanged: (v) => c.experienceLevel = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: c.questions.isEmpty ? 'Generate Questions' : 'Regenerate Questions',
                  icon: Icons.auto_awesome,
                  loading: c.questionsLoading,
                  onPressed: c.canGenerate ? c.generateQuestions : null,
                ),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(c.error!, style: const TextStyle(color: AppColors.error)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: c.questions.isEmpty
                ? const EmptyState(
                    icon: Icons.psychology_outlined,
                    title: 'No questions yet',
                    subtitle: 'Enter a job title and generate 10 role-specific questions.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: c.questions.length,
                    itemBuilder: (_, i) => _QuestionTile(controller: c, q: c.questions[i], index: i),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final InterviewController controller;
  final InterviewQuestion q;
  final int index;
  const _QuestionTile({required this.controller, required this.q, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text('${index + 1}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          title: Text(q.question, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          onExpansionChanged: (open) {
            if (open && q.answer == null && !q.answerLoading) controller.generateAnswer(q);
          },
          children: [
            if (q.answerLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Drafting a STAR answer…'),
                ]),
              )
            else if (q.answer != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(q.answer!, style: context.text.bodyMedium?.copyWith(height: 1.5)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Regenerate'),
                    onPressed: () => controller.generateAnswer(q),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copy'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: q.answer!));
                      context.showSnack('Copied to clipboard');
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
