import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/address_autocomplete_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/resume_builder_controller.dart';

// NOTE on state: text fields write to the model directly in onChanged WITHOUT
// calling notifyListeners. That avoids rebuilding the step on every keystroke
// (which would jump the cursor / drop focus). Structural changes — add/remove
// entries, toggles, template — DO notify, and on the resulting rebuild each
// field re-seeds its initialValue from the model, which already holds the
// latest typed text. This keeps typing smooth and the model consistent.

/// Step 0 — Personal info. Required fields (name, email, phone, location) are
/// validated via [formKey], which the screen calls before advancing.
class PersonalStep extends StatelessWidget {
  final ResumeBuilderController c;
  final GlobalKey<FormState> formKey;
  const PersonalStep(this.c, {super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          AppTextField(
            label: 'Full name *',
            initialValue: c.fullName,
            onChanged: (v) => c.fullName = v,
            validator: (v) => Validators.required(v, 'Full name'),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Professional title', initialValue: c.title, onChanged: (v) => c.title = v),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Email *',
            keyboardType: TextInputType.emailAddress,
            initialValue: c.email,
            onChanged: (v) => c.email = v,
            validator: Validators.email,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Phone *',
            keyboardType: TextInputType.phone,
            initialValue: c.phone,
            onChanged: (v) => c.phone = v,
            validator: Validators.phone,
          ),
          const SizedBox(height: 12),
          AddressAutocompleteField(
            label: 'Location / address *',
            hint: 'Start typing your address…',
            initialValue: c.location,
            onChanged: (v) => c.location = v,
            validator: (v) => Validators.required(v, 'Location'),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'LinkedIn URL', initialValue: c.linkedin, onChanged: (v) => c.linkedin = v),
        ],
      ),
    );
  }
}

/// Step 1 — Summary with an AI-generate helper.
class SummaryStep extends StatelessWidget {
  final ResumeBuilderController c;
  final VoidCallback onAiGenerate;
  final bool aiLoading;
  const SummaryStep(this.c, {super.key, required this.onAiGenerate, this.aiLoading = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Keyed by current text so an AI-generated value re-seeds the field.
        AppTextField(
          key: ValueKey('summary-${c.summary.hashCode}'),
          label: 'Professional summary',
          hint: 'A 3-4 sentence overview of who you are professionally.',
          maxLines: 6,
          initialValue: c.summary,
          onChanged: (v) => c.summary = v,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: aiLoading ? 'Generating…' : 'AI Generate',
          icon: Icons.auto_awesome,
          variant: AppButtonVariant.secondary,
          loading: aiLoading,
          onPressed: onAiGenerate,
        ),
      ],
    );
  }
}

/// Step 2 — Work experience (repeating).
class ExperienceStep extends StatelessWidget {
  final ResumeBuilderController c;
  const ExperienceStep(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < c.experiences.length; i++) _entry(context, i),
        const SizedBox(height: 8),
        AppButton(
          label: 'Add Experience',
          icon: Icons.add,
          variant: AppButtonVariant.secondary,
          onPressed: c.addExperience,
        ),
      ],
    );
  }

  Widget _entry(BuildContext context, int i) {
    final e = c.experiences[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Experience ${i + 1}', style: context.text.titleLarge),
              const Spacer(),
              if (c.experiences.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => c.removeExperience(i),
                ),
            ],
          ),
          AppTextField(label: 'Job title', initialValue: e.title, onChanged: (v) => e.title = v),
          const SizedBox(height: 10),
          AppTextField(label: 'Company', initialValue: e.company, onChanged: (v) => e.company = v),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: AppTextField(
                      label: 'Start', hint: 'Jan 2022', initialValue: e.startDate, onChanged: (v) => e.startDate = v)),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  key: ValueKey('exp-end-$i-${e.current}'),
                  label: 'End',
                  hint: e.current ? 'Present' : 'Dec 2023',
                  initialValue: e.current ? '' : e.endDate,
                  onChanged: (v) => e.endDate = v,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I currently work here'),
            value: e.current,
            activeColor: AppColors.primary,
            onChanged: (v) => c.update(() => e.current = v),
          ),
          const Divider(),
          Text('Bullet points', style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          for (var b = 0; b < e.bullets.length; b++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: e.bullets[b],
                      maxLines: 2,
                      minLines: 1,
                      decoration: const InputDecoration(hintText: 'Achieved X by doing Y, resulting in Z'),
                      onChanged: (v) => e.bullets[b] = v,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: e.bullets.length > 1 ? () => c.update(() => e.bullets.removeAt(b)) : null,
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add bullet'),
              onPressed: () => c.update(() => e.bullets.add('')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 3 — Education (repeating).
class EducationStep extends StatelessWidget {
  final ResumeBuilderController c;
  const EducationStep(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < c.education.length; i++) _entry(context, i),
        const SizedBox(height: 8),
        AppButton(
          label: 'Add Education',
          icon: Icons.add,
          variant: AppButtonVariant.secondary,
          onPressed: c.addEducation,
        ),
      ],
    );
  }

  Widget _entry(BuildContext context, int i) {
    final e = c.education[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Education ${i + 1}', style: context.text.titleLarge),
              const Spacer(),
              if (c.education.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => c.removeEducation(i),
                ),
            ],
          ),
          AppTextField(label: 'Degree', initialValue: e.degree, onChanged: (v) => e.degree = v),
          const SizedBox(height: 10),
          AppTextField(label: 'School', initialValue: e.school, onChanged: (v) => e.school = v),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: AppTextField(
                      label: 'Start', hint: '2018', initialValue: e.startDate, onChanged: (v) => e.startDate = v)),
              const SizedBox(width: 10),
              Expanded(
                  child: AppTextField(
                      label: 'End', hint: '2022', initialValue: e.endDate, onChanged: (v) => e.endDate = v)),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(label: 'GPA (optional)', initialValue: e.gpa, onChanged: (v) => e.gpa = v),
        ],
      ),
    );
  }
}

/// Step 4 — Skills as chips, with AI-suggest.
class SkillsStep extends StatefulWidget {
  final ResumeBuilderController c;
  final VoidCallback onAiSuggest;
  final bool aiLoading;
  const SkillsStep(this.c, {super.key, required this.onAiSuggest, this.aiLoading = false});

  @override
  State<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<SkillsStep> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    widget.c.addSkill(_input.text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(hintText: 'Add a skill and press +'),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add),
              onPressed: _add,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.c.skills.isEmpty)
          Text('No skills yet.', style: context.text.bodySmall)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.c.skills
                .map((s) => Chip(
                      label: Text(s),
                      onDeleted: () => widget.c.removeSkill(s),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      side: const BorderSide(color: AppColors.border),
                    ))
                .toList(),
          ),
        const SizedBox(height: 16),
        AppButton(
          label: widget.aiLoading ? 'Suggesting…' : 'AI Suggest Skills',
          icon: Icons.auto_awesome,
          variant: AppButtonVariant.secondary,
          loading: widget.aiLoading,
          onPressed: widget.onAiSuggest,
        ),
      ],
    );
  }
}

/// Step 5 — Extras: certifications + languages.
class ExtrasStep extends StatefulWidget {
  final ResumeBuilderController c;
  const ExtrasStep(this.c, {super.key});

  @override
  State<ExtrasStep> createState() => _ExtrasStepState();
}

class _ExtrasStepState extends State<ExtrasStep> {
  final _cert = TextEditingController();
  final _lang = TextEditingController();

  @override
  void dispose() {
    _cert.dispose();
    _lang.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _listEditor(context, 'Certifications', widget.c.certifications, _cert),
        const SizedBox(height: 20),
        _listEditor(context, 'Languages', widget.c.languages, _lang),
      ],
    );
  }

  Widget _listEditor(BuildContext context, String title, List<String> list, TextEditingController ctrl) {
    void add() {
      widget.c.toggleSimpleListItem(list, ctrl.text);
      ctrl.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: context.text.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(hintText: 'Add ${title.toLowerCase()}'),
                onSubmitted: (_) => add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add),
              onPressed: add,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list
              .map((s) => Chip(
                    label: Text(s),
                    onDeleted: () => widget.c.toggleSimpleListItem(list, s),
                    backgroundColor: AppColors.cardSurface,
                    side: const BorderSide(color: AppColors.border),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
