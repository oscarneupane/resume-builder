import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/resume_provider.dart';

class PersonalInfoStep extends StatefulWidget {
  const PersonalInfoStep({super.key});

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _linkedInCtrl;
  late TextEditingController _summaryCtrl;

  @override
  void initState() {
    super.initState();
    final info = context.read<ResumeProvider>().resumeData.personalInfo;
    _nameCtrl = TextEditingController(text: info.fullName);
    _emailCtrl = TextEditingController(text: info.email);
    _phoneCtrl = TextEditingController(text: info.phone);
    _locationCtrl = TextEditingController(text: info.location);
    _linkedInCtrl = TextEditingController(text: info.linkedIn);
    _summaryCtrl = TextEditingController(text: info.summary);
  }

  void _save() {
    context.read<ResumeProvider>().updatePersonalInfo(
          fullName: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          location: _locationCtrl.text,
          linkedIn: _linkedInCtrl.text,
          summary: _summaryCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name'),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone'),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(labelText: 'Location (e.g. Sydney, NSW)'),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkedInCtrl,
            decoration: const InputDecoration(labelText: 'LinkedIn URL (optional)'),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _summaryCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Professional Summary', alignLabelWithHint: true),
            onChanged: (_) => _save(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _linkedInCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }
}
