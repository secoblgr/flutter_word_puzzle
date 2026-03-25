import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/friends/domain/repositories/friends_repository.dart';

/// Removes a friend relationship between two users.
class RemoveFriend implements UseCase<void, RemoveFriendParams> {
  final FriendsRepository repository;

  const RemoveFriend(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveFriendParams params) {
    return repository.removeFriend(params.userId, params.friendId);
  }
}

class RemoveFriendParams extends Equatable {
  final String userId;
  final String friendId;

  const RemoveFriendParams({required this.userId, required this.friendId});

  @override
  List<Object> get props => [userId, friendId];
}
