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
  final _personalFormKey = GlobalKey<FormState>();

  static const _stepNames = ['Personal', 'Summary', 'Experience', 'Education', 'Projects', 'Skills', 'Extras'];

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

  /// AI writes a complete resume from whatever the user has entered so far,
  /// formatted into the app's single ATS layout. Enriches wording — does not
  /// invent employers/schools/dates (enforced in the prompt).
  Future<void> _generateFullResume(ResumeBuilderController c) async {
    final input = await _showGenerateDialog(c);
    if (input == null) return;

    setState(() => _generatingAll = true);
    final res = await AiService.instance.generate(
      feature: AiFeature.fullResume,
      context: {
        'jobTitle': input.$1,
        'notes': input.$2,
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

  /// Collects a target role (defaults to the entered title) and optional notes.
  Future<(String, String)?> _showGenerateDialog(ResumeBuilderController c) {
    final roleCtrl = TextEditingController(text: c.title);
    final notesCtrl = TextEditingController();
    return showDialog<(String, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate with AI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI will write a complete resume from the details you’ve entered, '
              'using real facts only — it won’t invent jobs or dates.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: 'Target role', hintText: 'e.g. IT Support Officer'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Anything else? (optional)',
                hintText: 'Tone, focus areas, target company…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, (roleCtrl.text.trim(), notesCtrl.text.trim())),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
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
    if (_step == _stepNames.length - 1) {
      context.push(AppRoutes.resumePreview);
    } else {
      setState(() => _step++);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatingAll ? null : () => _generateFullResume(c),
        icon: _generatingAll
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome),
        label: Text(_generatingAll ? 'Writing…' : 'Generate with AI'),
        backgroundColor: AppColors.primary,
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
                    child: AppButton(
                      label: _step == _stepNames.length - 1 ? 'Preview Resume' : 'Next',
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
        return ExperienceStep(c);
      case 3:
        return EducationStep(c);
      case 4:
        return ProjectsStep(c);
      case 5:
        return SkillsStep(c, onAiSuggest: () => _suggestSkills(c), aiLoading: _skillsLoading);
      case 6:
        return ExtrasStep(c);
    }
    return const SizedBox.shrink();
  }
}
