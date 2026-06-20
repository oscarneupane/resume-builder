import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../auth/auth_provider.dart';
import '../../dashboard/screens/home_shell.dart' show ProfileHeaderCard;
import '../../resume_builder/controllers/resume_builder_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _aiTips = true;
  bool _weeklyReminder = true;

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Log out', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider).signOut();
      if (mounted) context.showSnack('Logged out');
    }
  }

  /// Gathers the user's data into a JSON document they can copy out (GDPR export).
  Future<void> _exportData() async {
    final auth = ref.read(authStateProvider);
    final c = ref.read(resumeBuilderControllerProvider);
    final prefs = await SharedPreferences.getInstance();
    final onboardingRaw = prefs.getString(AppConstants.prefOnboardingPayload);
    Object onboarding = {};
    if (onboardingRaw != null) {
      try {
        onboarding = jsonDecode(onboardingRaw);
      } catch (_) {/* keep empty */}
    }
    final data = {
      'app': AppConstants.appName,
      'exported_at': DateTime.now().toIso8601String(),
      'account': {'name': auth.displayName, 'email': auth.email, 'username': auth.username},
      'onboarding': onboarding,
      'resume': c.toResume().sections.map((s) => {'type': s.type.value, 'content': s.content}).toList(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(data);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Your data (JSON)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(json, style: const TextStyle(fontSize: 12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(d);
              context.showSnack('Data copied to clipboard');
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /// Two-step destructive confirm (final step requires typing DELETE), then
  /// permanently deletes the account.
  Future<void> _confirmDelete() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and all your data — resumes, '
          'cover letters, documents, and job applications. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Continue', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Type DELETE to confirm'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'DELETE'),
          onChanged: (_) => (d as Element).markNeedsBuild(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
            onPressed: ctrl.text.trim().toUpperCase() == 'DELETE' ? () => Navigator.pop(d, true) : null,
            child: const Text('Delete forever', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authControllerProvider).deleteAccount();
      if (mounted) context.showSnack('Account deleted');
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ProfileHeaderCard(name: auth.displayName, email: auth.email),
          const SizedBox(height: 24),

          _GroupCard(
            title: 'Account',
            children: [
              _SettingRow(icon: Icons.workspace_premium_outlined, label: 'Subscription', onTap: () => context.push(AppRoutes.subscription)),
              _SettingRow(icon: Icons.lock_outline, label: 'Change password', onTap: () => context.showSnack('Password reset coming soon')),
            ],
          ),
          const SizedBox(height: 16),

          _GroupCard(
            title: 'Notifications',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary),
                title: const Text('AI tips'),
                value: _aiTips,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _aiTips = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                title: const Text('Weekly progress reminder'),
                value: _weeklyReminder,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _weeklyReminder = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _GroupCard(
            title: 'Legal',
            children: [
              _SettingRow(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push(AppRoutes.privacy)),
              _SettingRow(icon: Icons.gavel_outlined, label: 'Terms of Service', onTap: () => context.push(AppRoutes.terms)),
            ],
          ),
          const SizedBox(height: 16),

          _GroupCard(
            title: 'Data & Privacy',
            children: [
              _SettingRow(icon: Icons.download_outlined, label: 'Export my data (JSON)', onTap: _exportData),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
                title: const Text('Delete account', style: TextStyle(color: AppColors.error)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: _confirmDelete,
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
              label: const Text('Log out', style: TextStyle(color: AppColors.error)),
              onPressed: _confirmLogout,
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('${AppConstants.appName}  v1.0.0', style: context.text.bodySmall)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _GroupCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title.toUpperCase(),
              style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
