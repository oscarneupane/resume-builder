import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../auth/auth_provider.dart';
import '../../resume_builder/controllers/resume_builder_controller.dart';
import 'ats_score_gauge.dart';

class DashboardContent extends ConsumerWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetingName = ref.watch(authStateProvider).displayName.capitalized;
    // Live resume "potential" — reflects how complete/strong the user's draft is.
    final resumeScore = ref.watch(resumeBuilderControllerProvider).strengthScore;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.terrain_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('ApplyMate', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _GreetingCard(name: greetingName),
            const SizedBox(height: 16),
            _ResumeScoreCard(score: resumeScore),
            const SizedBox(height: 24),
            Text('Build your application', style: context.text.titleLarge),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.description_outlined,
              title: 'Resume Builder',
              subtitle: 'Create or edit a polished resume.',
              onTap: () => context.push(AppRoutes.resumeList),
            ),
            _FeatureCard(
              icon: Icons.verified_outlined,
              title: 'ATS Check',
              subtitle: 'Score and improve your resume against ATS. Get improvement tips.',
              onTap: () => context.push(AppRoutes.ats),
            ),
            _FeatureCard(
              icon: Icons.mail_outline,
              title: 'Cover Letter Builder',
              subtitle: 'Generate personalised cover letters that get noticed.',
              onTap: () => context.push(AppRoutes.coverLetter),
            ),
            _FeatureCard(
              icon: Icons.connect_without_contact,
              title: 'LinkedIn Summary Helper',
              subtitle: 'Create a standout LinkedIn headline and summary.',
              onTap: () => context.push(AppRoutes.linkedin),
            ),
            _FeatureCard(
              icon: Icons.psychology_outlined,
              title: 'Interview Prep',
              subtitle: 'Practice common questions and get AI-powered feedback.',
              onTap: () => context.push(AppRoutes.interview),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  const _GreetingCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2E5191)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back, $name 👋',
              style: context.text.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Let us build your best application yet.',
              style: TextStyle(color: Color(0xFFB7CDEB))),
        ],
      ),
    );
  }
}

class _ResumeScoreCard extends StatelessWidget {
  final int score;
  const _ResumeScoreCard({required this.score});

  ({String title, String subtitle}) get _copy {
    if (score == 0) {
      return (title: 'Resume potential', subtitle: 'Start your resume to see your score.');
    }
    if (score < 50) {
      return (title: 'Resume potential', subtitle: 'Getting started — add more detail to grow your score.');
    }
    if (score < 75) {
      return (title: 'Resume potential', subtitle: 'Looking good — a few sections left to strengthen.');
    }
    if (score < 100) {
      return (title: 'Resume potential', subtitle: 'Strong resume! Polish the last details.');
    }
    return (title: 'Resume potential', subtitle: 'Complete — your resume is fully built. 🎉');
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () => context.push(AppRoutes.resumeBuilder),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            AtsScoreGauge(score: score, size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.title, style: context.text.titleLarge),
                  const SizedBox(height: 4),
                  Text(copy.subtitle, style: context.text.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
