import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:word_puzzle/features/leaderboard/domain/repositories/leaderboard_repository.dart';

/// Retrieves the top players for the leaderboard.
class GetLeaderboard extends UseCase<List<LeaderboardEntry>, GetLeaderboardParams> {
  final LeaderboardRepository repository;

  GetLeaderboard({required this.repository});

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> call(
    GetLeaderboardParams params,
  ) {
    return repository.getLeaderboard(limit: params.limit);
  }
}

/// Parameters for the [GetLeaderboard] use case.
class GetLeaderboardParams extends Equatable {
  final int limit;

  const GetLeaderboardParams({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}
