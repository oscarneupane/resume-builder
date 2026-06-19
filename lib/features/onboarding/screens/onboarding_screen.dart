import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

/// 5-question onboarding (Screen 2). Result saved locally so the profile
/// step on first login can upsert it into the `profiles` table.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _payload = <String, dynamic>{};
  final _jobTitleController = TextEditingController();

  static const _countries = ['Australia', 'New Zealand', 'United States', 'United Kingdom', 'Canada', 'India', 'Other'];

  static const _goals = [
    ('find_job', 'Find a new job', Icons.work_outline),
    ('promotion', 'Get promoted', Icons.trending_up),
    ('change_career', 'Change career', Icons.swap_horiz),
    ('first_job', 'My first job', Icons.school_outlined),
  ];

  static const _styles = [
    ('quick_apply', 'Quick apply', Icons.flash_on_outlined),
    ('ats', 'ATS-optimized', Icons.verified_outlined),
    ('creative', 'Creative standout', Icons.palette_outlined),
    ('simple', 'Simple & clean', Icons.format_align_left),
  ];

  @override
  void dispose() {
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefHasOnboarded, true);
    await prefs.setString(AppConstants.prefOnboardingPayload, jsonEncode(_payload));
    if (!mounted) return;
    // Flip the in-memory flag so the router lets us past onboarding immediately.
    ref.read(onboardingFlagProvider.notifier).state = true;
    context.go(AppRoutes.signup);
  }

  void _next() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _payload['careerGoal'] != null;
      case 1:
        return (_payload['jobTitle'] ?? '').toString().trim().isNotEmpty;
      case 2:
        return _payload['country'] != null;
      case 3:
        return _payload['experience'] != null;
      case 4:
        return _payload['resumeStyle'] != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / 5;
    return Scaffold(
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--)),
        title: Text('Step ${_step + 1} of 5', style: Theme.of(context).textTheme.bodySmall),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: _step == 4 ? 'Finish' : 'Next',
                onPressed: _canAdvance ? _next : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _choicePage(
          'What is your career goal?',
          _goals,
          selected: _payload['careerGoal'] as String?,
          onSelect: (v) => setState(() => _payload['careerGoal'] = v),
        );
      case 1:
        return _textPage(
          'What is your target job title?',
          subtitle: 'For example: Software Engineer, Registered Nurse, Marketing Lead.',
          controller: _jobTitleController,
          onChanged: (v) => setState(() => _payload['jobTitle'] = v),
        );
      case 2:
        return _dropdownPage(
          'Which country are you applying in?',
          options: _countries,
          selected: _payload['country'] as String?,
          onSelect: (v) => setState(() => _payload['country'] = v),
        );
      case 3:
        return _chipsPage(
          'How much experience do you have?',
          options: ExperienceLevel.values,
          selected: _payload['experience'] as String?,
          onSelect: (v) => setState(() => _payload['experience'] = v),
        );
      case 4:
        return _choicePage(
          'What kind of resume are you after?',
          _styles,
          selected: _payload['resumeStyle'] as String?,
          onSelect: (v) => setState(() => _payload['resumeStyle'] = v),
        );
    }
    return const SizedBox.shrink();
  }

  Widget _choicePage(String question, List<(String, String, IconData)> opts,
      {required String? selected, required ValueChanged<String> onSelect}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 20),
        ...opts.map((o) => _choiceCard(
              key: o.$1,
              label: o.$2,
              icon: o.$3,
              selected: selected == o.$1,
              onTap: () => onSelect(o.$1),
            )),
      ],
    );
  }

  Widget _textPage(String question,
      {required String subtitle, required TextEditingController controller, required ValueChanged<String> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        AppTextField(label: 'Target job title', controller: controller, onChanged: onChanged),
      ],
    );
  }

  Widget _dropdownPage(String question,
      {required List<String> options, required String? selected, required ValueChanged<String> onSelect}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 20),
        ...options.map((o) => _choiceCard(
              key: o,
              label: o,
              icon: Icons.public_outlined,
              selected: selected == o,
              onTap: () => onSelect(o),
            )),
      ],
    );
  }

  Widget _chipsPage(String question,
      {required List<ExperienceLevel> options, required String? selected, required ValueChanged<String> onSelect}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: options.map((l) {
            final isSel = selected == l.value;
            return ChoiceChip(
              selected: isSel,
              label: Text(l.label),
              onSelected: (_) => onSelect(l.value),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSel ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.cardSurface,
              side: BorderSide(color: isSel ? AppColors.primary : AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _choiceCard({required String key, required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
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
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
              if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
