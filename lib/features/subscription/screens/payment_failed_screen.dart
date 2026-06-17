import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/app_button.dart';

class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key});

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
                backgroundColor: AppColors.error,
                radius: 40,
                child: Icon(Icons.close, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              Text('Payment could not be processed', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Please try again or contact support.', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AppButton(label: 'Try again', onPressed: () => context.pop()),
              const SizedBox(height: 8),
              TextButton(onPressed: () {}, child: const Text('Contact support')),
            ],
          ),
        ),
      ),
    );
  }
}
