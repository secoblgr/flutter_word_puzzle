import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/word_bank.dart';
import 'package:word_puzzle/features/game/data/models/score_model.dart';
import 'package:word_puzzle/features/game/data/models/word_model.dart';

/// Contract for remote game data operations.
abstract class GameRemoteDataSource {
  /// Fetches words for a given [level] and [category],
  /// excluding words already solved by [userId].
  /// [language] controls which word bank to use ('en' or 'tr').
  Future<List<WordModel>> getWordsForLevel(
    int level, {
    String userId = '',
    String category = 'animals',
    String language = 'en',
  });

  /// Writes a score document and updates the user's total score.
  Future<void> submitScore(ScoreModel score);

  /// Retrieves the most recent score entry for [userId].
  Future<ScoreModel> getUserScore(String userId);

  /// Saves the solved word IDs to the user's document.
  Future<void> markWordsSolved(String userId, List<String> wordIds);
}

/// Firebase-backed implementation of [GameRemoteDataSource].
class GameRemoteDataSourceImpl implements GameRemoteDataSource {
  final FirebaseFirestore firestore;

  GameRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _wordsCollection =>
      firestore.collection(AppConstants.wordsCollection);

  CollectionReference<Map<String, dynamic>> get _scoresCollection =>
      firestore.collection(AppConstants.scoresCollection);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection(AppConstants.usersCollection);

  @override
  Future<List<WordModel>> getWordsForLevel(
    int level, {
    String userId = '',
    String category = 'animals',
    String language = 'en',
  }) async {
    try {
      // 1. Get user's already solved words.
      Set<String> solvedWordIds = {};
      if (userId.isNotEmpty) {
        try {
          final userDoc = await _usersCollection.doc(userId).get();
          if (userDoc.exists) {
            final data = userDoc.data() ?? {};
            solvedWordIds =
                Set<String>.from(data['solvedWords'] as List? ?? []);
          }
        } catch (_) {}
      }

      // 2. Get difficulty range for this level.
      final difficultyRange = _difficultyRangeForLevel(level);

      // 3. Try Firestore first.
      try {
        final snapshot = await _wordsCollection
            .where('category', isEqualTo: category)
            .where('difficulty', isGreaterThanOrEqualTo: difficultyRange.$1)
            .where('difficulty', isLessThanOrEqualTo: difficultyRange.$2)
            .limit(50)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final words = snapshot.docs
              .map((doc) => WordModel.fromDocument(doc))
              .where((w) => !solvedWordIds.contains(w.id))
              .toList()
            ..shuffle();
          if (words.isNotEmpty) {
            return words.take(AppConstants.wordsPerLevel).toList();
          }
        }
      } catch (_) {}

      // 4. Fall back to default word bank.
      return _getDefaultWordsForLevel(level, category, solvedWordIds, language);
    } catch (e) {
      return _getDefaultWordsForLevel(level, category, {}, language);
    }
  }

  @override
  Future<void> submitScore(ScoreModel score) async {
    try {
      await _scoresCollection.add(score.toJson());

      final userDoc = _usersCollection.doc(score.userId);
      final userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        final data = userSnapshot.data() ?? {};
        final currentScore = data['score'] as int? ?? 0;
        final currentLevel = data['level'] as int? ?? 1;

        // Update per-category level in the categoryLevels map.
        final categoryLevels = Map<String, dynamic>.from(
          data['categoryLevels'] as Map? ?? {},
        );
        final currentCatLevel =
            (categoryLevels[score.category] as int?) ?? 1;
        if (score.level > currentCatLevel) {
          categoryLevels[score.category] = score.level;
        }

        await userDoc.update({
          'score': currentScore + score.score,
          'level': score.level > currentLevel ? score.level : currentLevel,
          'categoryLevels': categoryLevels,
        });
      }
    } catch (e) {
      throw ServerException('Failed to submit score: ${e.toString()}');
    }
  }

  @override
  Future<ScoreModel> getUserScore(String userId) async {
    try {
      final snapshot = await _scoresCollection
          .where('userId', isEqualTo: userId)
          .orderBy('time', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return ScoreModel(
          userId: userId,
          score: 0,
          time: DateTime.now(),
          level: 1,
        );
      }

      return ScoreModel.fromDocument(snapshot.docs.first);
    } catch (e) {
      throw ServerException('Failed to get user score: ${e.toString()}');
    }
  }

  @override
  Future<void> markWordsSolved(String userId, List<String> wordIds) async {
    if (userId.isEmpty || wordIds.isEmpty) return;
    try {
      await _usersCollection.doc(userId).update({
        'solvedWords': FieldValue.arrayUnion(wordIds),
      });
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  (int, int) _difficultyRangeForLevel(int level) {
    if (level <= 5) return (1, 1);
    if (level <= 10) return (2, 2);
    if (level <= 20) return (3, 3);
    if (level <= 30) return (4, 4);
    if (level <= 40) return (5, 6);
    if (level <= 50) return (6, 7);
    if (level <= 60) return (7, 8);
    if (level <= 80) return (8, 9);
    return (9, 10);
  }

  List<WordModel> _getDefaultWordsForLevel(
    int level,
    String category,
    Set<String> solvedWordIds, [
    String language = 'en',
  ]) {
    final range = _difficultyRangeForLevel(level);
    final bank = getWordBankForLanguage(language);
    final categoryWords = bank[category] ?? [];

    var filtered = categoryWords
        .where((w) => w.difficulty >= range.$1 && w.difficulty <= range.$2)
        .where((w) => !solvedWordIds.contains(w.id))
        .toList()
      ..shuffle();

    // If all words in this category+difficulty are solved, allow repeats.
    if (filtered.isEmpty) {
      filtered = categoryWords
          .where((w) => w.difficulty >= range.$1 && w.difficulty <= range.$2)
          .toList()
        ..shuffle();
    }

    return filtered.take(AppConstants.wordsPerLevel).toList();
  }
}
