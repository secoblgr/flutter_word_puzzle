import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';

/// An animated tile displaying a single letter.
///
/// Changes appearance when [isSelected] is true and triggers [onTap] when
/// the user taps on it.
class LetterTile extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final VoidCallback? onTap;

  const LetterTile({
    super.key,
    required this.letter,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkBorder.withValues(alpha: 0.3)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.darkBorder
                : AppColors.primary.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white,
          ),
        ),
      ),
    )
        .animate(
          target: isSelected ? 1.0 : 0.0,
        )
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.9, 0.9),
          duration: 200.ms,
        );
  }
}

/// A tile shown in the answer area that can be removed by tapping.
class AnswerLetterTile extends StatelessWidget {
  final String letter;
  final VoidCallback? onTap;

  const AnswerLetterTile({
    super.key,
    required this.letter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          letter.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.easeOutBack,
        );
  }
}
