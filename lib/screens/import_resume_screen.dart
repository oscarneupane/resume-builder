import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resume_provider.dart';
import '../services/ai_service.dart';
import 'resume_builder_screen.dart';

/// Lets the user paste in the text of an existing resume. AI parses it into
/// structured fields (and improves the wording along the way), then we drop
/// them straight into the same wizard used for building from scratch so
/// they can review and tweak everything before exporting.
class ImportResumeScreen extends StatefulWidget {
  const ImportResumeScreen({super.key});

  @override
  State<ImportResumeScreen> createState() => _ImportResumeScreenState();
}

class _ImportResumeScreenState extends State<ImportResumeScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final AIService _aiService = AIService();
  bool _loading = false;

  Future<void> _analyze() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste your resume text first.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final parsed = await _aiService.parseResume(text);
      if (!mounted) return;
      context.read<ResumeProvider>().loadImportedResume(parsed);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not analyze resume: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Existing Resume')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Paste the full text of your current resume below. AI will split it into sections "
              "(contact info, experience, education, skills) and you'll review and improve "
              "everything before exporting.",
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Paste your resume text here...',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Analyzing...' : 'Analyze & Improve with AI'),
                onPressed: _loading ? null : _analyze,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }
}
