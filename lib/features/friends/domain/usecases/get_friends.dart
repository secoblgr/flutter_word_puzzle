import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/friends/domain/entities/friend_entity.dart';
import 'package:word_puzzle/features/friends/domain/repositories/friends_repository.dart';

/// Fetches the friend list for a given user.
class GetFriends implements UseCase<List<FriendEntity>, String> {
  final FriendsRepository repository;

  const GetFriends(this.repository);

  @override
  Future<Either<Failure, List<FriendEntity>>> call(String userId) {
    return repository.getFriends(userId);
  }
}
