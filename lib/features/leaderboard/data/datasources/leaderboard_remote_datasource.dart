import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/features/leaderboard/data/models/leaderboard_entry_model.dart';

/// Contract for remote leaderboard data operations.
abstract class LeaderboardRemoteDataSource {
  /// Fetches the top [limit] users ordered by score descending.
  Future<List<LeaderboardEntryModel>> getLeaderboard(int limit);

  /// Returns the rank of the user identified by [userId].
  ///
  /// Rank is computed by counting users with a higher score + 1.
  Future<int> getUserRank(String userId);
}

/// Firebase-backed implementation of [LeaderboardRemoteDataSource].
class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final FirebaseFirestore firestore;

  LeaderboardRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection(AppConstants.usersCollection);

  @override
  Future<List<LeaderboardEntryModel>> getLeaderboard(int limit) async {
    try {
      final snapshot = await _usersCollection
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return List.generate(snapshot.docs.length, (index) {
        return LeaderboardEntryModel.fromDocument(
          snapshot.docs[index],
          index + 1, // rank is 1-based
        );
      });
    } catch (e) {
      throw ServerException('Failed to fetch leaderboard: ${e.toString()}');
    }
  }

  @override
  Future<int> getUserRank(String userId) async {
    try {
      // Get the user's score first.
      final userDoc = await _usersCollection.doc(userId).get();

      if (!userDoc.exists) {
        throw const ServerException('User not found');
      }

      final userScore = userDoc.data()?['score'] as int? ?? 0;

      // Count how many users have a strictly higher score.
      final higherScoreSnapshot = await _usersCollection
          .where('score', isGreaterThan: userScore)
          .count()
          .get();

      return (higherScoreSnapshot.count ?? 0) + 1;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get user rank: ${e.toString()}');
    }
  }
}
