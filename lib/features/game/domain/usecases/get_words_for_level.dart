import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/game/domain/entities/word_entity.dart';
import 'package:word_puzzle/features/game/domain/repositories/game_repository.dart';

/// Fetches the word list for a specific game level.
class GetWordsForLevel implements UseCase<List<WordEntity>, GetWordsForLevelParams> {
  final GameRepository repository;

  const GetWordsForLevel(this.repository);

  @override
  Future<Either<Failure, List<WordEntity>>> call(GetWordsForLevelParams params) {
    return repository.getWordsForLevel(params.level, params.userId, params.category, language: params.language);
  }
}

/// Parameters for [GetWordsForLevel].
class GetWordsForLevelParams extends Equatable {
  final int level;
  final String userId;
  final String category;
  final String language;

  const GetWordsForLevelParams({
    required this.level,
    required this.userId,
    this.category = 'animals',
    this.language = 'en',
  });

  @override
  List<Object?> get props => [level, userId, category, language];
}
