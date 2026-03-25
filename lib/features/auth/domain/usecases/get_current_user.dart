import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/auth/domain/entities/user_entity.dart';
import 'package:word_puzzle/features/auth/domain/repositories/auth_repository.dart';

/// Retrieves the currently authenticated user, or null if none.
class GetCurrentUser implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  const GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
