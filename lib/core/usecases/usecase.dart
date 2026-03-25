import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:word_puzzle/core/error/failures.dart';

/// Base use case contract. Every use case returns [Either] with [Failure] or [T].
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use when the use case requires no parameters.
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
