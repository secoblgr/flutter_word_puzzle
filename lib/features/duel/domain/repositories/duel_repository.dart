import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/duel/data/datasources/duel_remote_datasource.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';

/// Contract for duel-related data operations.
abstract class DuelRepository {
  Future<Either<Failure, DuelEntity>> createDuel(String playerId, List<String> wordIds);
  Future<Either<Failure, DuelEntity>> joinDuel(String duelId, String playerId);
  Stream<Either<Failure, DuelEntity>> watchDuel(String duelId);
  Future<Either<Failure, void>> submitDuelResult(String duelId, String playerId, int score, {bool isFinal = false});
  Future<Either<Failure, List<DuelEntity>>> getAvailableDuels();

  // Duel invite operations
  Future<Either<Failure, void>> sendDuelInvite(String fromId, String toId);
  Future<Either<Failure, String>> acceptDuelInvite(String inviteId, String userId);
  Future<Either<Failure, void>> rejectDuelInvite(String inviteId);
  Future<Either<Failure, List<DuelInviteModel>>> getPendingDuelInvites(String userId);
}
