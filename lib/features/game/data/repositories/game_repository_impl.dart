import 'package:dartz/dartz.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/error/failures.dart';
import 'package:word_puzzle/features/game/data/datasources/game_remote_datasource.dart';
import 'package:word_puzzle/features/game/data/models/score_model.dart';
import 'package:word_puzzle/features/game/domain/entities/score_entity.dart';
import 'package:word_puzzle/features/game/domain/entities/word_entity.dart';
import 'package:word_puzzle/features/game/domain/repositories/game_repository.dart';

/// Concrete implementation of [GameRepository] that delegates to the remote
/// data source and maps exceptions into domain [Failure] objects.
class GameRepositoryImpl implements GameRepository {
  final GameRemoteDataSource remoteDataSource;

  const GameRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<WordEntity>>> getWordsForLevel(int level, String userId, String category, {String language = 'en'}) async {
    try {
      final words = await remoteDataSource.getWordsForLevel(level, userId: userId, category: category, language: language);
      return Right(words);
    } on ServerException catch (e) {
      return Left(GameFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitScore(ScoreEntity score) async {
    try {
      final scoreModel = ScoreModel(
        userId: score.userId,
        score: score.score,
        time: score.time,
        level: score.level,
        category: score.category,
      );
      await remoteDataSource.submitScore(scoreModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(GameFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> markWordsSolved(String userId, List<String> wordIds) async {
    await remoteDataSource.markWordsSolved(userId, wordIds);
  }

  @override
  Future<Either<Failure, ScoreEntity>> getUserScore(String userId) async {
    try {
      final score = await remoteDataSource.getUserScore(userId);
      return Right(score);
    } on ServerException catch (e) {
      return Left(GameFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
