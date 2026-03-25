import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';

/// Screen shown after completing a level, displaying score, time, and stars.
class ResultPage extends StatelessWidget {
  final int totalScore;
  final int level;
  final int timeTaken;
  final String userId;
  final String category;
  final String language;

  const ResultPage({
    super.key,
    required this.totalScore,
    required this.level,
    required this.timeTaken,
    this.userId = '',
    this.category = 'animals',
    this.language = 'en',
  });

  /// Determines star count (1-3) based on total score.
  int get _starCount {
    if (totalScore >= 800) return 3;
    if (totalScore >= 400) return 2;
    return 1;
  }

  String get _formattedTime {
    final minutes = timeTaken ~/ 60;
    final seconds = timeTaken % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive(context).maxContentWidth,
            ),
            child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(s),
                const SizedBox(height: 40),
                _buildStars(),
                const SizedBox(height: 40),
                _buildScoreCard(s),
                const SizedBox(height: 48),
                _buildActions(context, s),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(AppStrings s) {
    return Column(
      children: [
        Icon(
          Icons.emoji_events_rounded,
          size: 72,
          color: _starCount >= 3
              ? AppColors.timerWarning
              : _starCount >= 2
                  ? AppColors.secondary
                  : AppColors.primary,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.0, 0.0),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 16),
        Text(
          s.levelComplete,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stars
  // ---------------------------------------------------------------------------

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isFilled = index < _starCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 48,
            color: isFilled ? AppColors.timerWarning : AppColors.darkBorder,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (400 + index * 200).ms)
              .scale(
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                delay: (400 + index * 200).ms,
                curve: Curves.elasticOut,
              ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Score card
  // ---------------------------------------------------------------------------

  Widget _buildScoreCard(AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildStatRow(
            icon: Icons.star_rounded,
            iconColor: AppColors.timerWarning,
            label: s.totalScore,
            value: '$totalScore',
          ),
          const SizedBox(height: 16),
          Divider(
            color: AppColors.darkBorder.withValues(alpha: 0.3),
            height: 1,
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            icon: Icons.timer_outlined,
            iconColor: AppColors.secondary,
            label: s.time,
            value: _formattedTime,
          ),
          const SizedBox(height: 16),
          Divider(
            color: AppColors.darkBorder.withValues(alpha: 0.3),
            height: 1,
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            icon: Icons.layers_rounded,
            iconColor: AppColors.primary,
            label: s.level,
            value: '$level',
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 800.ms)
        .slideY(begin: 0.2, duration: 500.ms, delay: 800.ms);
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Widget _buildActions(BuildContext context, AppStrings s) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go('/game', extra: {
              'level': level + 1,
              'userId': userId,
              'category': category,
              'language': language,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              '${s.nextLevel} (${level + 1})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => context.go('/home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(
                color: AppColors.darkBorder,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              s.backToHome,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1200.ms)
        .slideY(begin: 0.2, duration: 500.ms, delay: 1200.ms);
  }
}
