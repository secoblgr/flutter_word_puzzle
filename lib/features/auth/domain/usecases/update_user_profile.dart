import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/auth/domain/entities/user_entity.dart';
import 'package:word_puzzle/features/auth/domain/repositories/auth_repository.dart';

/// Updates the user profile (name, photoUrl, etc.) in Firestore.
class UpdateUserProfile implements UseCase<UserEntity, UserEntity> {
  final AuthRepository repository;

  const UpdateUserProfile(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UserEntity params) {
    return repository.updateUser(params);
  }
}
