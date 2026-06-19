import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF142A50)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Center(
                  child: Icon(Icons.terrain_rounded, size: 56, color: Colors.white),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB7CDEB)),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
