import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resume_data.dart';
import '../../providers/resume_provider.dart';

class EducationStep extends StatelessWidget {
  const EducationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final list = provider.resumeData.education;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'No education added yet.\nTap below to add your degree.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => _EducationCard(index: index, education: list[index]),
                  ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Education'),
              onPressed: () => context.read<ResumeProvider>().addEducation(Education()),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationCard extends StatefulWidget {
  final int index;
  final Education education;
  const _EducationCard({required this.index, required this.education});

  @override
  State<_EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<_EducationCard> {
  late TextEditingController _institution;
  late TextEditingController _degree;
  late TextEditingController _field;
  late TextEditingController _start;
  late TextEditingController _end;

  @override
  void initState() {
    super.initState();
    _institution = TextEditingController(text: widget.education.institution);
    _degree = TextEditingController(text: widget.education.degree);
    _field = TextEditingController(text: widget.education.fieldOfStudy);
    _start = TextEditingController(text: widget.education.startDate);
    _end = TextEditingController(text: widget.education.endDate);
  }

  void _save() {
    widget.education.institution = _institution.text;
    widget.education.degree = _degree.text;
    widget.education.fieldOfStudy = _field.text;
    widget.education.startDate = _start.text;
    widget.education.endDate = _end.text;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Education #${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => context.read<ResumeProvider>().removeEducation(widget.index),
                ),
              ],
            ),
            TextField(
              controller: _institution,
              decoration: const InputDecoration(labelText: 'Institution'),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _degree,
              decoration: const InputDecoration(labelText: 'Degree (e.g. Bachelor of IT)'),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _field,
              decoration: const InputDecoration(labelText: 'Field of Study'),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _start,
                    decoration: const InputDecoration(labelText: 'Start (e.g. 2022)'),
                    onChanged: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _end,
                    decoration: const InputDecoration(labelText: 'End (e.g. 2025)'),
                    onChanged: (_) => _save(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _institution.dispose();
    _degree.dispose();
    _field.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }
}
