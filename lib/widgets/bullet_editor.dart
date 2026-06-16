import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/resume_data.dart';
import '../providers/resume_provider.dart';
import '../services/ai_service.dart';

/// Renders the editable list of bullet points for one work experience
/// entry, each with an "Improve with AI" action that rewrites it to sound
/// more impactful and quantified.
class BulletEditor extends StatefulWidget {
  final int experienceIndex;
  final Experience experience;

  const BulletEditor({
    super.key,
    required this.experienceIndex,
    required this.experience,
  });

  @override
  State<BulletEditor> createState() => _BulletEditorState();
}

class _BulletEditorState extends State<BulletEditor> {
  final AIService _aiService = AIService();
  int? _loadingBulletIndex;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.experience.bullets.map((b) => TextEditingController(text: b)).toList();
  }

  @override
  void didUpdateWidget(covariant BulletEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bullets = widget.experience.bullets;
    // Only rebuild controllers when the number of bullets changed (add/remove)
    // — rebuilding on every keystroke would reset the cursor position.
    if (_controllers.length != bullets.length) {
      for (final c in _controllers) {
        c.dispose();
      }
      _controllers = bullets.map((b) => TextEditingController(text: b)).toList();
    }
  }

  Future<void> _improveBullet(int bulletIndex) async {
    final original = widget.experience.bullets[bulletIndex];
    if (original.trim().isEmpty) return;

    setState(() => _loadingBulletIndex = bulletIndex);
    try {
      final goals = context.read<ResumeProvider>().resumeData.goals;
      final improved = await _aiService.improveBulletPoint(
        original: original,
        role: widget.experience.role,
        company: widget.experience.company,
        targetField: goals.targetField,
        targetJobTitle: goals.targetJobTitle,
        priorities: goals.priorities,
      );
      if (!mounted) return;
      context.read<ResumeProvider>().updateExperienceBullet(widget.experienceIndex, bulletIndex, improved);
      _controllers[bulletIndex].text = improved;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI improvement failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingBulletIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Responsibilities & Achievements', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        for (int i = 0; i < widget.experience.bullets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllers[i],
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'e.g. Helped with customer service'),
                    onChanged: (val) =>
                        context.read<ResumeProvider>().updateExperienceBullet(widget.experienceIndex, i, val),
                  ),
                ),
                const SizedBox(width: 4),
                _loadingBulletIndex == i
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Color(0xFF5FA8D3)),
                        tooltip: 'Improve with AI',
                        onPressed: () => _improveBullet(i),
                      ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      context.read<ResumeProvider>().removeBulletFromExperience(widget.experienceIndex, i),
                ),
              ],
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add bullet point'),
          onPressed: () => context.read<ResumeProvider>().addBulletToExperience(widget.experienceIndex),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}
