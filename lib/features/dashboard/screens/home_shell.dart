import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/dashboard_content.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    (AppRoutes.dashboard, 'Home', Icons.home_outlined, Icons.home),
    (AppRoutes.docs, 'My Docs', Icons.folder_outlined, Icons.folder),
    (AppRoutes.create, 'Create', Icons.add_circle_outline, Icons.add_circle),
    (AppRoutes.resources, 'Resources', Icons.menu_book_outlined, Icons.menu_book),
    (AppRoutes.profile, 'Profile', Icons.person_outline, Icons.person),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => context.go(_tabs[i].$1),
        items: [
          for (var i = 0; i < _tabs.length; i++)
            BottomNavigationBarItem(
              icon: Icon(i == idx ? _tabs[i].$4 : _tabs[i].$3),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _QuickTile(
            icon: Icons.description_outlined,
            title: 'New Resume',
            subtitle: 'Start from scratch or duplicate an existing one.',
            onTap: () => context.push(AppRoutes.resumeBuilder),
          ),
          const SizedBox(height: 12),
          _QuickTile(
            icon: Icons.mail_outline,
            title: 'New Cover Letter',
            subtitle: 'AI-generated, three tones, three formats.',
            onTap: () => context.push(AppRoutes.coverLetter),
          ),
          const SizedBox(height: 12),
          _QuickTile(
            icon: Icons.verified_outlined,
            title: 'New ATS Check',
            subtitle: 'Paste a job description and score your resume.',
            onTap: () => context.push(AppRoutes.ats),
          ),
        ],
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

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _QuickTile(icon: Icons.settings_outlined, title: 'Settings', onTap: () => context.push(AppRoutes.settings)),
          const SizedBox(height: 12),
          _QuickTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Subscription',
            subtitle: 'Manage your plan or start the 7-day Pro trial.',
            onTap: () => context.push(AppRoutes.subscription),
          ),
          const SizedBox(height: 12),
          _QuickTile(
            icon: Icons.work_history_outlined,
            title: 'Job Tracker',
            onTap: () => context.push(AppRoutes.jobTracker),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall),
                  ],
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
