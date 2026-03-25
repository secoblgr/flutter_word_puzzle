import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/friends/domain/repositories/friends_repository.dart';

/// Adds a friend relationship between two users.
class AddFriend implements UseCase<void, AddFriendParams> {
  final FriendsRepository repository;

  const AddFriend(this.repository);

  @override
  Future<Either<Failure, void>> call(AddFriendParams params) {
    return repository.addFriend(params.userId, params.friendId);
  }
}

class AddFriendParams extends Equatable {
  final String userId;
  final String friendId;

  const AddFriendParams({required this.userId, required this.friendId});

  @override
  List<Object> get props => [userId, friendId];
}
