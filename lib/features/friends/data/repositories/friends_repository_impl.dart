import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/friends/data/datasources/friends_remote_datasource.dart';
import 'package:word_puzzle/features/friends/domain/entities/friend_entity.dart';
import 'package:word_puzzle/features/friends/domain/repositories/friends_repository.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsRemoteDataSource remoteDataSource;

  const FriendsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriends(String userId) async {
    try {
      final friends = await remoteDataSource.getFriends(userId);
      return Right(friends);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFriend(String userId, String friendId) async {
    try {
      await remoteDataSource.addFriend(userId, friendId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFriend(String userId, String friendId) async {
    try {
      await remoteDataSource.removeFriend(userId, friendId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> searchUsers(String query) async {
    try {
      final users = await remoteDataSource.searchUsers(query);
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendEntity?>> findUserById(String userId) async {
    try {
      final user = await remoteDataSource.findUserById(userId);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendEntity?>> findUserByCode(String code) async {
    try {
      final user = await remoteDataSource.findUserByCode(code);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Friend Request Operations
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> sendFriendRequest(String fromId, String toId) async {
    try {
      await remoteDataSource.sendFriendRequest(fromId, toId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptFriendRequest(
      String requestId, String userId, String friendId) async {
    try {
      await remoteDataSource.acceptFriendRequest(requestId, userId, friendId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectFriendRequest(String requestId) async {
    try {
      await remoteDataSource.rejectFriendRequest(requestId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendRequestModel>>> getPendingRequests(String userId) async {
    try {
      final requests = await remoteDataSource.getPendingRequests(userId);
      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendRequestModel>>> getSentRequests(String userId) async {
    try {
      final requests = await remoteDataSource.getSentRequests(userId);
      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
