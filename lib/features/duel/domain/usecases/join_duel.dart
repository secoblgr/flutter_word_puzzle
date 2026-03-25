import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';
import 'package:word_puzzle/features/duel/domain/repositories/duel_repository.dart';

/// Joins an existing duel as the second player.
class JoinDuel implements UseCase<DuelEntity, JoinDuelParams> {
  final DuelRepository repository;

  const JoinDuel(this.repository);

  @override
  Future<Either<Failure, DuelEntity>> call(JoinDuelParams params) {
    return repository.joinDuel(params.duelId, params.playerId);
  }
}

/// Parameters for [JoinDuel].
class JoinDuelParams extends Equatable {
  final String duelId;
  final String playerId;

  const JoinDuelParams({
    required this.duelId,
    required this.playerId,
  });

  @override
  List<Object?> get props => [duelId, playerId];
}
