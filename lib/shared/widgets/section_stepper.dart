import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Numbered-circle stepper used in onboarding and resume builder.
class SectionStepper extends StatelessWidget {
  final int total;
  final int currentIndex; // 0-based
  const SectionStepper({super.key, required this.total, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total * 2 - 1, (i) {
        if (i.isOdd) {
          final left = (i - 1) ~/ 2;
          final filled = left < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: filled ? AppColors.primary : AppColors.border,
            ),
          );
        }
        final idx = i ~/ 2;
        final filled = idx <= currentIndex;
        return Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : Colors.white,
            border: Border.all(color: filled ? AppColors.primary : AppColors.border, width: 1.5),
            shape: BoxShape.circle,
          ),
          child: Text('${idx + 1}',
              style: TextStyle(color: filled ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        );
      }),
    );
  }
}
