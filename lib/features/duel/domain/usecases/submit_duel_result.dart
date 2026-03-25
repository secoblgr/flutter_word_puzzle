import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/duel/domain/repositories/duel_repository.dart';

/// Submits a player's score for a duel.
/// When [isFinal] is true, marks the player as done (all words solved or time up).
class SubmitDuelResult implements UseCase<void, SubmitDuelResultParams> {
  final DuelRepository repository;

  const SubmitDuelResult(this.repository);

  @override
  Future<Either<Failure, void>> call(SubmitDuelResultParams params) {
    return repository.submitDuelResult(
      params.duelId,
      params.playerId,
      params.score,
      isFinal: params.isFinal,
    );
  }
}

/// Parameters for [SubmitDuelResult].
class SubmitDuelResultParams extends Equatable {
  final String duelId;
  final String playerId;
  final int score;
  final bool isFinal;

  const SubmitDuelResultParams({
    required this.duelId,
    required this.playerId,
    required this.score,
    this.isFinal = false,
  });

  @override
  List<Object?> get props => [duelId, playerId, score, isFinal];
}
