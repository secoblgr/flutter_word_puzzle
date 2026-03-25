import 'package:equatable/equatable.dart';

/// Represents a player's score for a completed level.
class ScoreEntity extends Equatable {
  final String userId;
  final int score;
  final DateTime time;
  final int level;
  final String category;

  const ScoreEntity({
    required this.userId,
    required this.score,
    required this.time,
    required this.level,
    this.category = 'animals',
  });

  @override
  List<Object?> get props => [userId, score, time, level, category];
}
