import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/auth/domain/entities/user_entity.dart';

/// Contract for authentication operations.
abstract class AuthRepository {
  /// Signs in the user with Google credentials.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Signs in the user anonymously as a guest.
  Future<Either<Failure, UserEntity>> signInAnonymously();

  /// Signs out the current user.
  Future<Either<Failure, void>> signOut();

  /// Returns the currently authenticated user, or null if unauthenticated.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Updates the user profile in the remote store.
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);
}
