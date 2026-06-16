import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/resume_provider.dart';

/// First step in the wizard. Asks a few quick questions about the user's
/// target role and what matters most to them, so later AI suggestions are
/// tailored instead of generic.
class GoalsStep extends StatefulWidget {
  const GoalsStep({super.key});

  @override
  State<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends State<GoalsStep> {
  late TextEditingController _fieldCtrl;
  late TextEditingController _titleCtrl;
  late String _experienceLevel;
  late List<String> _priorities;

  static const List<String> _priorityOptions = [
    'Leadership',
    'Technical skills',
    'Customer service',
    'Results / achievements',
    'Certifications',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    final goals = context.read<ResumeProvider>().resumeData.goals;
    _fieldCtrl = TextEditingController(text: goals.targetField);
    _titleCtrl = TextEditingController(text: goals.targetJobTitle);
    _experienceLevel = goals.experienceLevel;
    _priorities = List.from(goals.priorities);
  }

  void _save() {
    context.read<ResumeProvider>().updateGoals(
          targetField: _fieldCtrl.text,
          targetJobTitle: _titleCtrl.text,
          experienceLevel: _experienceLevel,
          priorities: _priorities,
        );
  }

  void _togglePriority(String option) {
    setState(() {
      if (_priorities.contains(option)) {
        _priorities.remove(option);
      } else {
        _priorities.add(option);
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A few quick questions help AI tailor suggestions to you, instead of giving generic advice.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fieldCtrl,
            decoration: const InputDecoration(labelText: 'Target industry / field (e.g. IT, Retail, Trades)'),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Target job title (e.g. Junior Software Developer)'),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _experienceLevel,
            decoration: const InputDecoration(labelText: 'Experience level'),
            items: const ['Entry-level', 'Mid-level', 'Senior']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => _experienceLevel = val);
              _save();
            },
          ),
          const SizedBox(height: 20),
          const Text("What's most important to highlight?", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _priorityOptions.map((option) {
              final selected = _priorities.contains(option);
              return FilterChip(
                label: Text(option),
                selected: selected,
                onSelected: (_) => _togglePriority(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fieldCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }
}
