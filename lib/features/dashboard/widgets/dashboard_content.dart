import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../auth/auth_provider.dart';
import '../../resume_builder/controllers/resume_builder_controller.dart';
import 'ats_score_gauge.dart';

/// Returns "Good morning", "Good afternoon", or "Good evening" based on current hour.
String _timeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class DashboardContent extends ConsumerWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetingName = ref.watch(authStateProvider).displayName.capitalized;
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => HapticFeedback.lightImpact(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              _GreetingCard(name: greetingName),
              const SizedBox(height: 14),
              _ResumeScoreCard(score: resumeScore),
              const SizedBox(height: 24),
              // Quick-action row
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'New Resume',
                      onTap: () => context.push(AppRoutes.resumeBuilder),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.mail_outline_rounded,
                      label: 'Cover Letter',
                      onTap: () => context.push(AppRoutes.coverLetter),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.verified_outlined,
                      label: 'ATS Check',
                      onTap: () => context.push(AppRoutes.ats),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('All tools', style: context.text.titleLarge),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.description_outlined,
                color: AppColors.primary,
                title: 'Resume Builder',
                subtitle: 'Create or edit a polished, ATS-ready resume.',
                onTap: () => context.push(AppRoutes.resumeList),
              ),
              _FeatureCard(
                icon: Icons.verified_outlined,
                color: const Color(0xFF7C3AED),
                title: 'ATS Check',
                subtitle: 'Score and improve your resume against job listings.',
                onTap: () => context.push(AppRoutes.ats),
              ),
              _FeatureCard(
                icon: Icons.mail_outline,
                color: const Color(0xFF0F766E),
                title: 'Cover Letter Builder',
                subtitle: 'AI-generated cover letters in multiple tones.',
                onTap: () => context.push(AppRoutes.coverLetter),
              ),
              _FeatureCard(
                icon: Icons.connect_without_contact,
                color: const Color(0xFF0369A1),
                title: 'LinkedIn Summary',
                subtitle: 'Create a standout headline and summary.',
                onTap: () => context.push(AppRoutes.linkedin),
              ),
              _FeatureCard(
                icon: Icons.psychology_outlined,
                color: const Color(0xFFB45309),
                title: 'Interview Prep',
                subtitle: 'Practice questions and get AI-powered feedback.',
                onTap: () => context.push(AppRoutes.interview),
              ),
              _FeatureCard(
                icon: Icons.work_history_outlined,
                color: const Color(0xFF4F46E5),
                title: 'Job Tracker',
                subtitle: 'Track every application in one place.',
                onTap: () => context.push(AppRoutes.jobTracker),
              ),
            ],
          ),
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
    final greeting = _timeGreeting();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2E5191)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, $name 👋',
                    style: context.text.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                const Text("Let's build your best application yet.",
                    style: TextStyle(color: Color(0xFFB7CDEB), fontSize: 13)),
              ],
            ),
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ResumeScoreCard extends S