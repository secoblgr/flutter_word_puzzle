import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/features/game/domain/entities/word_category.dart';

/// Page where the player picks a word category before starting the game.
class CategorySelectPage extends StatelessWidget {
  final String userId;
  final Map<String, int> categoryLevels;
  final String language;

  const CategorySelectPage({
    super.key,
    required this.userId,
    this.categoryLevels = const {},
    this.language = 'en',
  });

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildTopBar(context),
                  const SizedBox(height: 20),
                  Text(
                    s.selectCategory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 6),
                  Text(
                    s.isTr
                        ? 'Her kategorinin kendi seviye ilerlemesi var'
                        : 'Each category has its own level progress',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: WordCategory.values.length,
                      itemBuilder: (context, index) {
                        final cat = WordCategory.values[index];
                        final catLevel = categoryLevels[cat.name] ?? 1;
                        return _CategoryCard(
                          category: cat,
                          level: catLevel,
                          language: language,
                          onTap: () => context.go('/game', extra: {
                            'level': catLevel,
                            'userId': userId,
                            'category': cat.name,
                            'language': language,
                          }),
                        )
                            .animate()
                            .fadeIn(
                                delay: (80 * index).ms, duration: 350.ms)
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              delay: (80 * index).ms,
                              duration: 350.ms,
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        // Language indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            language == 'tr' ? '🇹🇷 Türkçe' : '🇬🇧 English',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Category card widget
// -----------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  final WordCategory category;
  final int level;
  final String language;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.level,
    this.language = 'en',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.color.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            // Name
            Text(
              s.categoryName(category.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              category.localizedSubtitle(language),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Level badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${s.level} $level',
                style: TextStyle(
                  color: category.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
