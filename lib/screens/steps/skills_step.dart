import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/resume_provider.dart';

class SkillsStep extends StatefulWidget {
  const SkillsStep({super.key});

  @override
  State<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<SkillsStep> {
  final TextEditingController _inputCtrl = TextEditingController();
  late List<String> _skills;

  @override
  void initState() {
    super.initState();
    _skills = List.from(context.read<ResumeProvider>().resumeData.skills);
  }

  void _addSkill(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _skills.contains(trimmed)) return;
    setState(() => _skills.add(trimmed));
    _inputCtrl.clear();
    context.read<ResumeProvider>().setSkills(_skills);
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
    context.read<ResumeProvider>().setSkills(_skills);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add your key skills (press enter after each one):'),
          const SizedBox(height: 8),
          TextField(
            controller: _inputCtrl,
            decoration: const InputDecoration(hintText: 'e.g. JavaScript, SQL, Power BI'),
            onSubmitted: _addSkill,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills
                .map((skill) => Chip(
                      label: Text(skill),
                      onDeleted: () => _removeSkill(skill),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }
}
