import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';
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
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Practice your answer',
                  style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('ua-${q.question.hashCode}'),
              initialValue: q.userAnswer,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Type your own answer, then get AI feedback…'),
              onChanged: (v) => q.userAnswer = v,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: q.feedbackLoading ? 'Scoring…' : 'Get AI Feedback',
              icon: Icons.fact_check_outlined,
              variant: AppButtonVariant.secondary,
              loading: q.feedbackLoading,
              onPressed: () => controller.getFeedback(q),
            ),
            if (q.feedback != null) ...[
              const SizedBox(height: 12),
              _FeedbackBox(q.feedback!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders AI feedback on the user's practice answer: score + strengths + fixes.
class _FeedbackBox extends StatelessWidget {
  final Map<String, dynamic> fb;
  const _FeedbackBox(this.fb);

  @override
  Widget build(BuildContext context) {
    final score = (fb['score'] as num?)?.toInt() ?? 0;
    final color = score >= AppConstants.atsThresholdGood
        ? AppColors.success
        : score >= AppConstants.atsThresholdMid
            ? AppColors.warning
            : AppColors.error;
    final strengths = ((fb['strengths'] as List?) ?? const []).map((e) => e.toString()).toList();
    final improvements = ((fb['improvements'] as List?) ?? const []).map((e) => e.toString()).toList();
    final summary = (fb['summary'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('$score / 100', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              if (summary.isNotEmpty) Expanded(child: Text(summary, style: context.text.bodySmall)),
            ],
          ),
          for (final s in strengths)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(child: Text(s, style: context.text.bodyMedium)),
              ]),
            ),
          for (final s in improvements)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.arrow_circle_up_outlined, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(child: Text(s, style: context.text.bodyMedium)),
              ]),
            ),
        ],
      ),
    );
  }
}
