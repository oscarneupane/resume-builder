import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class InterviewScreen extends StatelessWidget {
  const InterviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Prep')),
      body: const EmptyState(
        icon: Icons.psychology_outlined,
        title: 'Interview Prep',
        subtitle: 'Question bank + STAR-method answers — coming up in Week 6.',
      ),
    );
  }
}
