import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../legal_content.dart';

enum LegalDoc { privacy, terms }

/// Renders the Privacy Policy or Terms in-app from [legal_content].
class LegalScreen extends StatelessWidget {
  final LegalDoc doc;
  const LegalScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = doc == LegalDoc.privacy;
    final title = isPrivacy ? 'Privacy Policy' : 'Terms of Service';
    final sections = isPrivacy ? privacyPolicySections : termsSections;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(title, style: context.text.displaySmall),
          const SizedBox(height: 4),
          Text(
            'Owned and operated by ${LegalInfo.ownerName}  •  Effective ${LegalInfo.effectiveDate}',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 20),
          for (final s in sections) ...[
            Text(s.heading, style: context.text.titleLarge?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 6),
            Text(s.body, style: context.text.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: 18),
          ],
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '© ${DateTime.now().year} ${LegalInfo.ownerName}. All rights reserved.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
