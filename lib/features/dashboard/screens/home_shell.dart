import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/auth_provider.dart';
import '../widgets/dashboard_content.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    (AppRoutes.dashboard, 'Home',     Icons.home_outlined,         Icons.home_rounded),
    (AppRoutes.docs,      'My Docs',  Icons.folder_outlined,       Icons.folder_rounded),
    (AppRoutes.create,    'Create',   Icons.add_circle_outline,    Icons.add_circle_rounded),
    (AppRoutes.resources, 'Resources',Icons.menu_book_outlined,    Icons.menu_book_rounded),
    (AppRoutes.profile,   'Profile',  Icons.person_outline_rounded,Icons.person_rounded),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          context.go(_tabs[i].$1);
        },
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: Icon(_tabs[i].$3, color: AppColors.textSecondary),
              selectedIcon: Icon(_tabs[i].$4, color: AppColors.primary),
              label: _tabs[i].$2,
            ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) => const DashboardContent();
}

class QuickCreateScreen extends StatelessWidget {
  const QuickCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        children: [
          Text('What would you like to create?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          _CreateCard(
            icon: Icons.description_outlined,
            color: AppColors.primary,
            title: 'New Resume',
            subtitle: 'Start from scratch or duplicate an existing one.',
            badge: 'AI-powered',
            onTap: () => context.push(AppRoutes.resumeBuilder),
          ),
          const SizedBox(height: 12),
          _CreateCard(
            icon: Icons.mail_outline,
            color: const Color(0xFF0F766E),
            title: 'Cover Letter',
            subtitle: 'AI-generated, three tones, three formats.',
            badge: 'AI-powered',
            onTap: () => context.push(AppRoutes.coverLetter),
          ),
          const SizedBox(height: 12),
          _CreateCard(
            icon: Icons.verified_outlined,
            color: const Color(0xFF7C3AED),
            title: 'ATS Check',
            subtitle: 'Paste a job description and score your resume.',
            onTap: () => context.push(AppRoutes.ats),
          ),
          const SizedBox(height: 12),
          _CreateCard(
            icon: Icons.psychology_outlined,
            color: const Color(0xFFB45309),
            title: 'Interview Prep',
            subtitle: 'Practice questions with AI feedback.',
            onTap: () => context.push(AppRoutes.interview),
          ),
          const SizedBox(height: 12),
          _CreateCard(
            icon: Icons.connect_without_contact,
            color: const Color(0xFF0369A1),
            title: 'LinkedIn Summary',
            subtitle: 'Write a headline and summary that gets noticed.',
            onTap: () => context.push(AppRoutes.linkedin),
          ),
        ],
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _CreateCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge!, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Resources coming soon',
        subtitle: 'Interview questions, resume tips, and career advice will live here.',
      ),
    );
  }
}

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ProfileHeaderCard(name: auth.displayName, email: auth.email),
          const SizedBox(height: 20),
          _SectionLabel('Account'),
          _QuickTile(icon: Icons.settings_outlined, title: 'Settings', onTap: () => context.push(AppRoutes.settings)),
          const SizedBox(height: 10),
          _QuickTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Subscription',
            subtitle: 'Manage your plan or start the 7-day Pro trial.',
            onTap: () => context.push(AppRoutes.subscription),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Tools'),
          _QuickTile(icon: Icons.work_history_outlined, title: 'Job Tracker', onTap: () => context.push(AppRoutes.jobTracker)),
          const SizedBox(height: 10),
          _QuickTile(icon: Icons.auto_awesome_motion_outlined, title: 'My Materials', subtitle: 'Files & notes the AI can reuse.', onTap: () => context.push(AppRoutes.materials)),
          const SizedBox(height: 20),
          _SectionLabel('Legal'),
          _QuickTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => context.push(AppRoutes.privacy)),
          const SizedBox(height: 10),
          _QuickTile(icon: Icons.gavel_outlined, title: 'Terms of Service', onTap: () => context.push(AppRoutes.terms)),
        ],
      ),
    );
  }
}

/// Gradient header with avatar initials, name, email and a plan badge.
class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String? email;
  final bool isPro;
  const ProfileHeaderCard({super.key, required this.name, this.email, this.isPro = false});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.