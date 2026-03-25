import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/duel/data/datasources/duel_remote_datasource.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';
import 'package:word_puzzle/features/duel/domain/repositories/duel_repository.dart';

class DuelRepositoryImpl implements DuelRepository {
  final DuelRemoteDataSource remoteDataSource;

  const DuelRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DuelEntity>> createDuel(
    String playerId,
    List<String> wordIds,
  ) async {
    try {
      final duel = await remoteDataSource.createDuel(playerId, wordIds);
      return Right(duel);
    } on ServerException catch (e) {
      return Left(DuelFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DuelEntity>> joinDuel(
    String duelId,
    String playerId,
  ) async {
    try {
      final duel = await remoteDataSource.joinDuel(duelId, playerId);
      return Right(duel);
    } on ServerException catch (e) {
      return Left(DuelFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, DuelEntity>> watchDuel(String duelId) {
    return remoteDataSource
        .watchDuel(duelId)
        .map<Either<Failure, DuelEntity>>((duel) => Right(duel))
        .handleError(
          (error) => Left<Failure, DuelEntity>(
            error is ServerException
                ? DuelFailure(message: error.message)
                : ServerFailure(message: error.toString()),
          ),
        );
  }

  @override
  Future<Either<Failure, void>> submitDuelResult(
    String duelId,
    String playerId,
    int score, {
    bool isFinal = false,
  }) async {
    try {
      await remoteDataSource.submitDuelResult(duelId, playerId, score, isFinal: isFinal);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(DuelFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DuelEntity>>> getAvailableDuels() async {
    try {
      final duels = await remoteDataSource.getAvailableDuels();
      return Right(duels);
    } on ServerException catch (e) {
      return Left(DuelFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Duel invite operations
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> sendDuelInvite(String fromId, String toId) async {
    try {
      await remoteDataSource.sendDuelInvite(fromId, toId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(DuelFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> acceptDuelInvite(String inviteId, String userId) async {
    try {
      final duelId = await remoteDataSource.acceptDuelInvite(inviteId, userId);
      return Right(duelId);
    } on ServerException catch (e) {
      return Left(DuelFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectDuelInvite(String inviteId) async {
    try {
      await remoteDataSource.rejectDuelInvite(inviteId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(DuelFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DuelInviteModel>>> getPendingDuelInvites(String userId) async {
    try {
      final invites = await remoteDataSource.getPendingDuelInvites(userId);
      return Right(invites);
    } on ServerException catch (e) {
      return Left(DuelFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
