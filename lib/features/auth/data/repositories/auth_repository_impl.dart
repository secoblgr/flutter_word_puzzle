import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:word_puzzle/features/auth/data/models/user_model.dart';
import 'package:word_puzzle/features/auth/domain/entities/user_entity.dart';
import 'package:word_puzzle/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] that delegates to the remote
/// data source and maps exceptions into domain [Failure] objects.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  const AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInAnonymously() async {
    try {
      final user = await remoteDataSource.signInAnonymously();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final updatedUser = await remoteDataSource.updateUser(userModel);
      return Right(updatedUser);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
