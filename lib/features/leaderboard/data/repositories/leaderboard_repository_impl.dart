import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import 'package:word_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:word_puzzle/features/leaderboard/domain/repositories/leaderboard_repository.dart';

/// Concrete implementation of [LeaderboardRepository] that delegates to the
/// remote data source and maps exceptions into domain [Failure] objects.
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource remoteDataSource;

  const LeaderboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard({
    int limit = 50,
  }) async {
    try {
      final entries = await remoteDataSource.getLeaderboard(limit);
      return Right(entries);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUserRank(String userId) async {
    try {
      final rank = await remoteDataSource.getUserRank(userId);
      return Right(rank);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
