import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class LinkedInScreen extends StatelessWidget {
  const LinkedInScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LinkedIn Helper')),
      body: const EmptyState(
        icon: Icons.connect_without_contact,
        title: 'LinkedIn Helper',
        subtitle: 'Headline, About section, recruiter message and skill suggestions — coming up in Week 6.',
      ),
    );
  }
}
