import 'package:equatable/equatable.dart';

/// Possible states of a duel match.
enum DuelStatus {
  waiting,
  playing,
  finished,
}

/// A single word used in a duel (stored in Firestore).
class DuelWord {
  final String word;
  final String definition;
  final int difficulty;

  const DuelWord({
    required this.word,
    required this.definition,
    this.difficulty = 1,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'definition': definition,
        'difficulty': difficulty,
      };

  factory DuelWord.fromJson(Map<String, dynamic> json) => DuelWord(
        word: json['word'] as String? ?? '',
        definition: json['definition'] as String? ?? '',
        difficulty: json['difficulty'] as int? ?? 1,
      );
}

/// Domain entity representing a 1-v-1 duel between two players.
class DuelEntity extends Equatable {
  final String id;
  final String player1Id;
  final String? player2Id;
  final DuelStatus status;
  final String? winnerId;
  final List<String> wordIds;
  final List<DuelWord> duelWords;
  final int player1Score;
  final int player2Score;
  final DateTime createdAt;

  const DuelEntity({
    required this.id,
    required this.player1Id,
    this.player2Id,
    required this.status,
    this.winnerId,
    required this.wordIds,
    this.duelWords = const [],
    required this.player1Score,
    required this.player2Score,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        player1Id,
        player2Id,
        status,
        winnerId,
        wordIds,
        duelWords,
        player1Score,
        player2Score,
        createdAt,
      ];
}
