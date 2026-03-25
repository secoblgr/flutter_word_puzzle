import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/constants.dart';

/// A circular countdown timer that changes color based on remaining time.
///
/// - Green when more than 30 seconds remain.
/// - Yellow (warning) when 10-30 seconds remain.
/// - Red with a pulse animation when fewer than 10 seconds remain.
class TimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const TimerWidget({
    super.key,
    required this.remainingSeconds,
    this.totalSeconds = AppConstants.baseTimerSeconds,
  });

  Color get _timerColor {
    if (remainingSeconds > 30) return AppColors.correct;
    if (remainingSeconds > 10) return AppColors.timerWarning;
    return AppColors.timerDanger;
  }

  double get _progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

  @override
  Widget build(BuildContext context) {
    final timerContent = SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring.
          CustomPaint(
            size: const Size(56, 56),
            painter: _TimerRingPainter(
              progress: _progress,
              color: _timerColor,
              backgroundColor: AppColors.darkBorder.withValues(alpha: 0.3),
            ),
          ),
          // Seconds text.
          Text(
            '$remainingSeconds',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _timerColor,
            ),
          ),
        ],
      ),
    );

    // Add pulse when danger zone.
    if (remainingSeconds <= 10 && remainingSeconds > 0) {
      return timerContent
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.1, 1.1),
            duration: 500.ms,
          );
    }

    return timerContent;
  }
}

/// Custom painter that draws an arc ring to visualize remaining time.
class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle.
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc.
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top.
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
