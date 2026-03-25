import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/game/domain/entities/score_entity.dart';
import 'package:word_puzzle/features/game/domain/entities/word_entity.dart';

/// Contract for game-related data operations.
abstract class GameRepository {
  /// Fetches a list of words appropriate for the given [level],
  /// excluding words the user has already solved.
  Future<Either<Failure, List<WordEntity>>> getWordsForLevel(int level, String userId, String category, {String language = 'en'});

  /// Persists the player's score after completing a level.
  Future<Either<Failure, void>> submitScore(ScoreEntity score);

  /// Retrieves the cumulative score for a user by [userId].
  Future<Either<Failure, ScoreEntity>> getUserScore(String userId);

  /// Marks the given word IDs as solved for the user.
  Future<void> markWordsSolved(String userId, List<String> wordIds);
}
