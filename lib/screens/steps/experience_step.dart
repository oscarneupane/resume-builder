import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resume_data.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/bullet_editor.dart';

class ExperienceStep extends StatelessWidget {
  const ExperienceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final list = provider.resumeData.experience;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'No work experience added yet.\nTap below to add a role.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => _ExperienceCard(index: index, experience: list[index]),
                  ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Work Experience'),
              onPressed: () => context.read<ResumeProvider>().addExperience(Experience()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatefulWidget {
  final int index;
  final Experience experience;
  const _ExperienceCard({required this.index, required this.experience});

  @override
  State<_ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<_ExperienceCard> {
  late TextEditingController _company;
  late TextEditingController _role;
  late TextEditingController _location;
  late TextEditingController _start;
  late TextEditingController _end;

  @override
  void initState() {
    super.initState();
    _company = TextEditingController(text: widget.experience.company);
    _role = TextEditingController(text: widget.experience.role);
    _location = TextEditingController(text: widget.experience.location);
    _start = TextEditingController(text: widget.experience.startDate);
    _end = TextEditingController(text: widget.experience.endDate);
  }

  void _save() {
    widget.experience.company = _company.text;
    widget.experience.role = _role.text;
    widget.experience.location = _location.text;
    widget.experience.startDate = _start.text;
    widget.experience.endDate = _end.text;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Role #${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => context.read<ResumeProvider>().removeExperience(widget.index),
                ),
              ],
            ),
            TextField(
              controller: _role,
              decoration: const InputDecoration(labelText: 'Job Title'),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _company,
              decoration: const InputDecoration(labelText: 'Company'),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location'),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _start,
                    decoration: const InputDecoration(labelText: 'Start (e.g. Jan 2024)'),
                    onChanged: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _end,
                    decoration: const InputDecoration(labelText: 'End (or "Present")'),
                    onChanged: (_) => _save(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BulletEditor(experienceIndex: widget.index, experience: widget.experience),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _company.dispose();
    _role.dispose();
    _location.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }
}
