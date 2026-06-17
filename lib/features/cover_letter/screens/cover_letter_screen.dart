import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class CoverLetterScreen extends StatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen> {
  final _jobTitle = TextEditingController();
  final _company = TextEditingController();
  String _tone = 'Professional';
  static const _tones = ['Professional', 'Confident', 'Friendly', 'Simple'];

  @override
  void dispose() {
    _jobTitle.dispose();
    _company.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cover Letter Builder')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(label: 'Job title', controller: _jobTitle),
          const SizedBox(height: 12),
          AppTextField(label: 'Company name', controller: _company),
          const SizedBox(height: 20),
          Text('Tone', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _tones.map((t) {
              final sel = _tone == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => _tone = t),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Generate Cover Letter', icon: Icons.auto_awesome, onPressed: () {}),
        ],
      ),
    );
  }
}
