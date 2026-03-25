import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';
import 'package:word_puzzle/features/duel/domain/repositories/duel_repository.dart';

/// Watches real-time updates for a duel match.
///
/// This is not a standard [UseCase] because it returns a [Stream] instead of
/// a [Future].
class WatchDuel {
  final DuelRepository repository;

  const WatchDuel(this.repository);

  Stream<Either<Failure, DuelEntity>> call(String duelId) {
    return repository.watchDuel(duelId);
  }
}
