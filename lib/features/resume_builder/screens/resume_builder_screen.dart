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
  bool _generatingAll = false;
  bool _saving = false;
  String? _improvingBulletKey;
  final _personalFormKey = GlobalKey<FormState>();

  static const _stepNames = ['Personal', 'Summary', 'Experience', 'Education', 'Projects', 'Skills', 'Extras', 'Generate'];

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

  /// Final step action: AI turns everything entered into a complete resume in
  /// the app's single ATS layout, then opens the preview. Enriches wording —
  /// does not invent employers/schools/dates (enforced in the prompt).
  Future<void> _generateFullResume(ResumeBuilderController c) async {
    final role = c.aiTargetRole.trim().isNotEmpty ? c.aiTargetRole.trim() : c.title.trim();

    setState(() => _generatingAll = true);
    final res = await AiService.instance.generate(
      feature: AiFeature.fullResume,
      context: {
        'jobTitle': role,
        'notes': c.aiNotes.trim(),
        'details': c.aiDetails(),
      },
    );
    if (!mounted) return;
    setState(() => _generatingAll = false);

    if (!res.isOk || res.text == null) {
      context.showSnack(res.error ?? 'Could not generate the resume.');
      return;
    }
    try {
      final data = jsonDecode(res.text!) as Map<String, dynamic>;
      // Fresh AI pass owns skills/projects — clear so grouped output isn't merged.
      c.update(() {
        c.skills.clear();
        c.projects
          ..clear()
          ..add(ProjectEntry());
      });
      c.applyExtracted(data);
      if (!mounted) return;
      context.showSnack('Resume generated — review and export.');
      context.push(AppRoutes.resumePreview);
    } catch (_) {
      context.showSnack('The AI returned an unexpected format. Please try again.');
    }
  }

  void _onNext() {
    // Step 0 (Personal) gates on required fields.
    if (_step == 0) {
      final ok = _personalFormKey.currentState?.validate() ?? true;
      if (!ok) {
        context.showSnack('Please complete the required fields.');
        return;
      }
    }
    setState(() => _step++);
  }

  /// AI-rewrites a single experience bullet into a stronger, quantified version.
  Future<void> _improveBullet(ResumeBuilderController c, ExperienceEntry e, int b) async {
    final original = e.bullets[b].trim();
    if (original.isEmpty) return;
    final i = c.experiences.indexOf(e);
    setState(() => _improvingBulletKey = 'exp-$i-bullet-$b');
    final res = await AiService.instance.generate(
      feature: AiFeature.bulletImprover,
      context: {'bullet': original, 'jobTitle': c.title},
    );
    if (!mounted) return;
    setState(() => _improvingBulletKey = null);
    if (res.isOk && res.text != null && res.text!.trim().isNotEmpty) {
      c.update(() => e.bullets[b] = res.text!.trim());
    } else {
      context.showSnack(res.error ?? 'Could not improve the bullet.');
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
                // Re-key on revision so Smart Import re-seeds field initialValues.
                child: KeyedSubtree(key: ValueKey('step-$_step-rev-${c.revision}'), child: _buildStep(c)),
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
                    child: _step == _stepNames.length - 1
                        ? AppButton(
                            label: _generatingAll ? 'Generating…' : 'Generate',
                            icon: Icons.auto_awesome,
                            loading: _generatingAll,
                            onPressed: () => _generateFullResume(c),
                          )
                        : AppButton(
                            label: 'Next',
                            onPressed: () => _onNext(),
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
        return PersonalStep(c, formKey: _personalFormKey);
      case 1:
        return SummaryStep(c, onAiGenerate: () => _generateSummary(c), aiLoading: _summaryLoading);
      case 2:
        return ExperienceStep(
          c,
          onImproveBullet: (e, b) => _improveBullet(c, e, b),
          improvingBulletKey: _improvingBulletKey,
        );
      case 3:
        return EducationStep(c);
      case 4:
        return ProjectsStep(c);
      case 5:
        return SkillsStep(c, onAiSuggest: () => _suggestSkills(c), aiLoading: _skillsLoading);
      case 6:
        return ExtrasStep(c);
      case 7:
        return GenerateStep(c);
    }
    return const SizedBox.shrink();
  }
}
