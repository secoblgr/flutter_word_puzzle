import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/features/game/domain/entities/score_entity.dart';

/// Data-layer model that extends [ScoreEntity] with serialization capabilities.
class ScoreModel extends ScoreEntity {
  const ScoreModel({
    required super.userId,
    required super.score,
    required super.time,
    required super.level,
    super.category,
  });

  /// Creates a [ScoreModel] from a JSON map.
  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    return ScoreModel(
      userId: json['userId'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      time: json['time'] is Timestamp
          ? (json['time'] as Timestamp).toDate()
          : DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      level: json['level'] as int? ?? 1,
      category: json['category'] as String? ?? 'animals',
    );
  }

  /// Creates a [ScoreModel] from a Firestore [DocumentSnapshot].
  factory ScoreModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ScoreModel.fromJson({...data, 'userId': doc.id});
  }

  /// Serializes this model to a JSON map suitable for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'score': score,
      'time': Timestamp.fromDate(time),
      'level': level,
      'category': category,
    };
  }
}
