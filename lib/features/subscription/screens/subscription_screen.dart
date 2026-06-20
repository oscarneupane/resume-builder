import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../services/stripe_service.dart';
import '../../../shared/widgets/app_button.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;

  Future<void> _startTrial() async {
    setState(() => _loading = true);
    try {
      await StripeService.instance.startCheckout();
    } catch (e) {
      if (!mounted) return;
      context.showSnack('Stripe Checkout requires Supabase + Stripe to be configured.');
      context.push(AppRoutes.paymentFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const features = [
      ('Unlimited AI generations', true),
      ('Full ATS analysis', true),
      ('Unlimited cover letters (3 formats)', true),
      ('All premium resume templates', true),
      ('LinkedIn Helper', true),
      ('Interview Prep + STAR coach', true),
      ('Job tracker', true),
      ('Unlimited cloud document storage', true),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('ApplyMate Pro')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF142A50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.proGold),
                    SizedBox(width: 8),
                    Text('ApplyMate Pro',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
                  ],
                ),
                SizedBox(height: 6),
                Text('AUD \$14.99 / month — 7-day free trial',
                    style: TextStyle(color: Color(0xFFB7CDEB))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("What's included", style: context.text.titleLarge),
          const SizedBox(height: 8),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f.$1)),
                ]),
              )),
          const SizedBox(height: 24),
          AppButton(
            label: 'Start 7-Day Free Trial',
            onPressed: _startTrial,
            loading: _loading,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'No charge during trial. Cancel anytime.',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
