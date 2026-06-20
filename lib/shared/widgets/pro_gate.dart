import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Lock-overlay shown when a free user tries to use a Pro feature.
/// Tap CTA navigates to the subscription screen.
class ProGate extends StatelessWidget {
  final String featureName;
  final VoidCallback onUpgrade;
  const ProGate({super.key, required this.featureName, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.proGold.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.star_rounded, size: 36, color: AppColors.proGold),
            ),
            const SizedBox(height: 16),
            Text('$featureName is a Pro feature', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '7-day free trial — cancel anytime.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onUpgrade, child: const Text('Upgrade to Pro')),
          ],
        ),
      ),
    );
  }
}
