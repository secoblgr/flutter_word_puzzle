import 'package:word_puzzle/core/utils/constants.dart';

/// Calculates score based on time remaining and difficulty.
class ScoreCalculator {
  ScoreCalculator._();

  /// Calculates score for a single word based on [remainingSeconds] and [level].
  static int calculate({
    required int remainingSeconds,
    required int level,
  }) {
    final difficultyMultiplier = _getDifficultyMultiplier(level);
    final timeBonus = (remainingSeconds * 2).clamp(0, 200);
    final base = AppConstants.basePointsPerWord;

    return ((base + timeBonus) * difficultyMultiplier).round();
  }

  static double _getDifficultyMultiplier(int level) {
    if (level <= AppConstants.easyMaxLevel) return 1.0;
    if (level <= AppConstants.mediumMaxLevel) return 1.5;
    return 2.0;
  }
}
