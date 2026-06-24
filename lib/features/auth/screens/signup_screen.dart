import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  int _strength = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
          );
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(AppRoutes.login)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create your account', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 4),
                Text("Let's get your applications standing out.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Full name',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Username',
                  hint: 'How you’ll appear in ApplyMate',
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: Validators.username,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Email address',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  onChanged: (v) => setState(() => _strength = Validators.passwordStrength(v)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 8),
                _StrengthMeter(score: _strength),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Confirm password',
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.matches(v, _passwordCtrl.text),
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Create account', onPressed: _submit, loading: _loading),
                const SizedBox(height: 20),
                const GoogleSignInButton(),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    children: [
                      Text('Already have an account? ', style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: const Text('Log in',
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final int score; // 0..4
  const _StrengthMeter({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = switch (score) {
      <= 1 => AppColors.error,
      2 => AppColors.warning,
      3 => AppColors.accent,
      _ => AppColors.success,
    };
    return Row(
      children: List.generate(4, (i) {
        final filled = i < score;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
            decoration: BoxDecoration(
              color: filled ? color : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
