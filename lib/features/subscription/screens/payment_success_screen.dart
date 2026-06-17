import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/app_button.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.success,
                radius: 40,
                child: Icon(Icons.check, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              Text('You are now Pro!', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text("Unlimited AI generations, premium templates, and more — let's go."),
              const SizedBox(height: 32),
              AppButton(label: 'Explore Pro features', onPressed: () => context.go(AppRoutes.dashboard)),
            ],
          ),
        ),
      ),
    );
  }
}
