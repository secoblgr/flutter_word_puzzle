import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/auth/domain/repositories/auth_repository.dart';

/// Signs out the current user.
class SignOut implements UseCase<void, NoParams> {
  final AuthRepository repository;

  const SignOut(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.signOut();
  }
}
