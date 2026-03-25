import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';
import 'package:word_puzzle/features/duel/domain/repositories/duel_repository.dart';

/// Creates a new duel lobby that other players can join.
class CreateDuel implements UseCase<DuelEntity, CreateDuelParams> {
  final DuelRepository repository;

  const CreateDuel(this.repository);

  @override
  Future<Either<Failure, DuelEntity>> call(CreateDuelParams params) {
    return repository.createDuel(params.playerId, params.wordIds);
  }
}

/// Parameters for [CreateDuel].
class CreateDuelParams extends Equatable {
  final String playerId;
  final List<String> wordIds;

  const CreateDuelParams({
    required this.playerId,
    required this.wordIds,
  });

  @override
  List<Object?> get props => [playerId, wordIds];
}
