import 'package:equatable/equatable.dart';

/// Represents a word in the puzzle game domain.
class WordEntity extends Equatable {
  final String id;
  final String word;
  final String definition;
  final int difficulty;
  final String category;

  const WordEntity({
    required this.id,
    required this.word,
    required this.definition,
    required this.difficulty,
    this.category = 'animals',
  });

  @override
  List<Object?> get props => [id, word, definition, difficulty, category];
}
