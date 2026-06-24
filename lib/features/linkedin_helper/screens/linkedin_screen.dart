import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/linkedin_controller.dart';

class LinkedInScreen extends ConsumerWidget {
  const LinkedInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(linkedInControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('LinkedIn Helper')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            label: 'Target job title',
            hint: 'e.g. Senior Flutter Developer',
            initialValue: c.jobTitle,
            onChanged: c.setJobTitle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Years of experience',
                  keyboardType: TextInputType.number,
                  initialValue: c.yearsExp,
                  onChanged: (v) => c.yearsExp = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Key skills',
                  hint: 'comma separated',
                  initialValue: c.skills,
                  onChanged: (v) => c.skills = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!c.canGenerate)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('Enter a job title to enable generation.', style: context.text.bodySmall),
            ),
          if (c.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(c.error!, style: const TextStyle(color: AppColors.error)),
            ),
          const SizedBox(height: 12),
          for (final section in LinkedInSection.values)
            _SectionCard(controller: c, section: section),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final LinkedInController controller;
  final LinkedInSection section;
  const _SectionCard({required this.controller, required this.section});

  @override
  Widget build(BuildContext context) {
    final result = controller.results[section];
    final loading = controller.isLoading(section);
    final hasResult = result != null && result.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: context.text.titleLarge),
                    Text(section.subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: controller.canGenerate && !loading ? () => controller.generate(section) : null,
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(hasResult ? Icons.refresh : Icons.auto_awesome, size: 18),
                label: Text(loading ? '...' : (hasResult ? 'Regenerate' : 'Generate')),
              ),
            ],
          ),
          if (hasResult) ...[
            const Divider(height: 20),
            SelectableText(result, style: context.text.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copy'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result));
                  context.showSnack('Copied to clipboard');
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
