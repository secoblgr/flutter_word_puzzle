import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/friends/data/datasources/friends_remote_datasource.dart';
import 'package:word_puzzle/features/friends/domain/entities/friend_entity.dart';

/// Contract for friend-related operations.
abstract class FriendsRepository {
  Future<Either<Failure, List<FriendEntity>>> getFriends(String userId);
  Future<Either<Failure, void>> addFriend(String userId, String friendId);
  Future<Either<Failure, void>> removeFriend(String userId, String friendId);
  Future<Either<Failure, List<FriendEntity>>> searchUsers(String query);
  Future<Either<Failure, FriendEntity?>> findUserById(String userId);
  Future<Either<Failure, FriendEntity?>> findUserByCode(String code);

  // Friend request operations
  Future<Either<Failure, void>> sendFriendRequest(String fromId, String toId);
  Future<Either<Failure, void>> acceptFriendRequest(String requestId, String userId, String friendId);
  Future<Either<Failure, void>> rejectFriendRequest(String requestId);
  Future<Either<Failure, List<FriendRequestModel>>> getPendingRequests(String userId);
  Future<Either<Failure, List<FriendRequestModel>>> getSentRequests(String userId);
}
