import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../services/ai_service.dart';
import '../../../services/resume_repository.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/section_stepper.dart';
import '../controllers/resume_builder_controller.dart';
import '../widgets/builder_steps.dart';

class ResumeBuilderScreen extends ConsumerStatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  ConsumerState<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends ConsumerState<ResumeBuilderScreen> {
  int _step = 0;
  bool _summaryLoading = false;
  bool _skillsLoading = false;
  bool _saving = false;

  static const _stepNames = ['Personal', 'Summary', 'Experience', 'Education', 'Skills', 'Extras', 'Template'];

  Future<void> _saveDraft(ResumeBuilderController c) async {
    if (!SupabaseService.isConfigured) {
      context.showSnack('Draft kept in memory (connect Supabase to save to the cloud).');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ResumeRepository.instance.saveResume(
        c.toResume(),
        existingId: c.savedResumeId,
      );
      if (id != null) c.savedResumeId = id;
      if (mounted) context.showSnack('Draft saved');
    } catch (e) {
      if (mounted) context.showSnack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generateSummary(ResumeBuilderController c) async {
    setState(() => _summaryLoading = true);
    final res = await AiService.instance.generate(
      feature: AiFeature.professionalSummary,
      context: {
        'jobTitle': c.title,
        'yearsExp': '',
        'skills': c.skills.join(', '),
        'careerGoal': '',
      },
    );
    if (!mounted) return;
    setState(() => _summaryLoading = false);
    if (res.isOk && res.text != null) {
      c.update(() => c.summary = res.text!.trim());
    } else {
      context.showSnack(res.error ?? 'Could not generate summary.');
    }
  }

  Future<void> _suggestSkills(ResumeBuilderController c) async {
    setState(() => _skillsLoading = true);
    final res = await AiService.instance.generate(
      feature: AiFeature.skillsSuggest,
      context: {'jobTitle': c.title},
    );
    if (!mounted) return;
    setState(() => _skillsLoading = false);
    if (res.isOk && res.text != null) {
      try {
        final list = (jsonDecode(res.text!) as List).map((e) => e.toString());
        for (final s in list) {
          c.addSkill(s);
        }
      } catch (_) {
        context.showSnack('Could not parse skill suggestions.');
      }
    } else {
      context.showSnack(res.error ?? 'Could not suggest skills.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(resumeBuilderControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _saveDraft(c),
            child: Text(_saving ? 'Saving…' : 'Save Draft'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: c.completion,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionStepper(total: _stepNames.length, currentIndex: _step),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(_stepNames[_step], style: context.text.titleLarge),
                      const Spacer(),
                      Text('${_step + 1} / ${_stepNames.length}', style: context.text.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildStep(c),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => setState(() => _step--),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: _step == _stepNames.length - 1 ? 'Preview Resume' : 'Next',
                      onPressed: () {
                        if (_step == _stepNames.length - 1) {
                          context.push(AppRoutes.resumePreview);
                        } else {
                          setState(() => _step++);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ResumeBuilderController c) {
    switch (_step) {
      case 0:
        return PersonalStep(c);
      case 1:
        return SummaryStep(c, onAiGenerate: () => _generateSummary(c), aiLoading: _summaryLoading);
      case 2:
        return ExperienceStep(c);
      case 3:
        return EducationStep(c);
      case 4:
        return SkillsStep(c, onAiSuggest: () => _suggestSkills(c), aiLoading: _skillsLoading);
      case 5:
        return ExtrasStep(c);
      case 6:
        return _TemplateStep(c);
    }
    return const SizedBox.shrink();
  }
}

/// Step 6 — template chooser (also available from the preview screen).
class _TemplateStep extends StatelessWidget {
  final ResumeBuilderController c;
  const _TemplateStep(this.c);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pick a template', style: context.text.titleLarge),
        const SizedBox(height: 4),
        Text('You can change this anytime from the preview.',
            style: context.text.bodySmall),
        const SizedBox(height: 16),
        for (final t in AppConstants.availableTemplates)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TemplateOption(
              name: t,
              selected: c.template == t,
              onTap: () => c.setTemplate(t),
            ),
          ),
      ],
    );
  }
}

/// Reusable template option card (used in builder step and preview drawer).
class TemplateOption extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const TemplateOption({super.key, required this.name, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(name.capitalized, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
