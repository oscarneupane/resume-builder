import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';

class AtsScoreGauge extends StatelessWidget {
  final int score;
  final double size;
  const AtsScoreGauge({super.key, required this.score, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final color = score >= AppConstants.atsThresholdGood
        ? AppColors.success
        : score >= AppConstants.atsThresholdMid
            ? AppColors.warning
            : AppColors.error;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(score: score.clamp(0, 100).toDouble(), color: color),
        child: Center(
          child: Text(
            '$score%',
            style: TextStyle(fontSize: size * 0.24, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.10;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bg);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * (score / 100), false, fg);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score || old.color != color;
}
