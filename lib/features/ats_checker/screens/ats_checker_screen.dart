import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../services/ai_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../dashboard/widgets/ats_score_gauge.dart';

class AtsCheckerScreen extends ConsumerStatefulWidget {
  const AtsCheckerScreen({super.key});

  @override
  ConsumerState<AtsCheckerScreen> createState() => _AtsCheckerScreenState();
}

class _AtsCheckerScreenState extends ConsumerState<AtsCheckerScreen> {
  final _jdCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _jdCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_jdCtrl.text.trim().length < 20) {
      context.showSnack('Paste a longer job description.');
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });
    final res = await AiService.instance.generate(
      feature: AiFeature.atsCheck,
      context: {'resumeText': '[user resume placeholder]', 'jobDescription': _jdCtrl.text.trim()},
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!res.isOk) {
        _error = res.error;
        return;
      }
      try {
        _result = jsonDecode(res.text!) as Map<String, dynamic>;
      } catch (_) {
        _error = 'Could not parse AI response.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ATS Check')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            label: 'Job description',
            hint: 'Paste the full job description here',
            controller: _jdCtrl,
            maxLines: 8,
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Check ATS Score', onPressed: _run, loading: _loading),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            Center(child: AtsScoreGauge(score: (_result!['score'] as num).toInt(), size: 110)),
            const SizedBox(height: 24),
            _KeywordSection(
              title: 'Matched keywords',
              items: List<String>.from(_result!['matching_keywords'] ?? const []),
              good: true,
            ),
            const SizedBox(height: 16),
            _KeywordSection(
              title: 'Missing keywords',
              items: List<String>.from(_result!['missing_keywords'] ?? const []),
              good: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _KeywordSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool good;
  const _KeywordSection({required this.title, required this.items, required this.good});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final color = good ? AppColors.success : AppColors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items
              .map((k) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(k, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
