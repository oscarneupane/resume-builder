import 'package:flutter/material.dart';
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
          const _SectionLabel('Account'),
          _QuickTile(icon: Icons.settings_outlined, title: 'Settings', onTap: () => context.push(AppRoutes.settings)),
          const SizedBox(height: 10),
          _QuickTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Subscription',
            subtitle: 'Manage your plan or start the 7-day Pro trial.',
            onTap: () => context.push(AppRoutes.subscription),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Tools'),
          _QuickTile(icon: Icons.work_history_outlined, title: 'Job Tracker', onTap: () => context.push(AppRoutes.jobTracker)),
          const SizedBox(height: 10),
          _QuickTile(icon: Icons.auto_awesome_motion_outlined, title: 'My Materials', subtitle: 'Files & notes the AI can reuse.', onTap: () => context.push(AppRoutes.materials)),
          const SizedBox(height: 20),
          const _SectionLabel('Legal'),
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
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(_initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.capitalized, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge?.copyWith(color: Colors.white, fontSize: 20)),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(email!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFB7CDEB), fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPro ? AppColors.proGold : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPro ? Icons.star_rounded : Icons.bolt_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(isPro ? 'PRO' : 'Free plan',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(text.toUpperCase(),
            style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );
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
