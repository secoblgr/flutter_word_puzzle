import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/features/game/domain/entities/word_entity.dart';

/// Data-layer model that extends [WordEntity] with serialization capabilities.
class WordModel extends WordEntity {
  const WordModel({
    required super.id,
    required super.word,
    required super.definition,
    required super.difficulty,
    super.category,
  });

  /// Creates a [WordModel] from a JSON map.
  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] as String? ?? '',
      word: (json['word'] as String? ?? '').toUpperCase(),
      definition: json['definition'] as String? ?? '',
      difficulty: json['difficulty'] as int? ?? 1,
      category: json['category'] as String? ?? 'animals',
    );
  }

  /// Creates a [WordModel] from a Firestore [DocumentSnapshot].
  factory WordModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WordModel.fromJson({...data, 'id': doc.id});
  }

  /// Serializes this model to a JSON map suitable for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'difficulty': difficulty,
      'category': category,
    };
  }
}
