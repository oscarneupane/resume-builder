import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/section_stepper.dart';

/// Multi-step resume builder. State is kept locally for now; once the
/// Supabase tables exist, persist each section to `resume_sections`.
class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  int _step = 0;
  final _steps = const ['Personal', 'Summary', 'Experience', 'Education', 'Skills', 'Extras', 'Template'];

  // Trivial local form state — replace with proper controller + JSONB sync later.
  final fullName = TextEditingController();
  final title = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();
  final linkedin = TextEditingController();
  final summary = TextEditingController();

  @override
  void dispose() {
    for (final c in [fullName, title, email, phone, location, linkedin, summary]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [TextButton(onPressed: () => context.showSnack('Draft saved'), child: const Text('Save Draft'))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: SectionStepper(total: _steps.length, currentIndex: _step),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(_steps[_step], style: context.text.titleLarge),
                  const Spacer(),
                  Text('${_step + 1} / ${_steps.length}', style: context.text.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildStepBody(),
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
                      label: _step == _steps.length - 1 ? 'Preview Resume' : 'Next',
                      onPressed: () {
                        if (_step == _steps.length - 1) {
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

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return Column(
          children: [
            AppTextField(label: 'Full name', controller: fullName),
            const SizedBox(height: 12),
            AppTextField(label: 'Professional title', controller: title),
            const SizedBox(height: 12),
            AppTextField(label: 'Email', controller: email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            AppTextField(label: 'Phone', controller: phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            AppTextField(label: 'Location', controller: location),
            const SizedBox(height: 12),
            AppTextField(label: 'LinkedIn URL', controller: linkedin),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(label: 'Professional summary', controller: summary, maxLines: 6),
            const SizedBox(height: 12),
            AppButton(
              label: 'AI Generate',
              icon: Icons.auto_awesome,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                summary.text = 'Results-driven professional with experience in [field]. '
                    'Skilled at delivering measurable impact across cross-functional teams. '
                    'Eager to bring strong technical fundamentals to your team.';
                setState(() {});
              },
            ),
          ],
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: Text('${_steps[_step]} editor coming in the next pass',
                style: context.text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
        );
    }
  }
}
