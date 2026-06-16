import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resume_provider.dart';
import '../theme/app_theme.dart';
import 'preview_screen.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final selected = provider.resumeData.selectedTemplate;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Template')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: TemplateStyle.all.map((t) {
          final isSelected = selected == t.id;
          return Card(
            color: isSelected ? t.primaryColor.withOpacity(0.08) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isSelected ? t.primaryColor : Colors.transparent, width: 2),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(backgroundColor: t.primaryColor, radius: 24),
              title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(t.description),
              trailing: isSelected ? Icon(Icons.check_circle, color: t.primaryColor) : null,
              onTap: () => context.read<ResumeProvider>().setTemplate(t.id),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: selected == 0
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PreviewScreen())),
          child: const Text('Preview Resume'),
        ),
      ),
    );
  }
}
