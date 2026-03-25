import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';

/// Contract for leaderboard data operations.
abstract class LeaderboardRepository {
  /// Fetches the top [limit] leaderboard entries ordered by score descending.
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard({int limit});

  /// Returns the current rank of the user identified by [userId].
  Future<Either<Failure, int>> getUserRank(String userId);
}
