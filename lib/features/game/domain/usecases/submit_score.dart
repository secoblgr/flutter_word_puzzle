import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/game/domain/entities/score_entity.dart';
import 'package:word_puzzle/features/game/domain/repositories/game_repository.dart';

/// Submits the player's score after completing a level.
class SubmitScore implements UseCase<void, ScoreEntity> {
  final GameRepository repository;

  const SubmitScore(this.repository);

  @override
  Future<Either<Failure, void>> call(ScoreEntity params) {
    return repository.submitScore(params);
  }
}
