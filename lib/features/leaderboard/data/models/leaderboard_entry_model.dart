import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';

/// Data-layer model that extends [LeaderboardEntry] with serialization.
class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.userId,
    required super.name,
    required super.photoUrl,
    required super.score,
    required super.level,
    required super.rank,
  });

  /// Creates a [LeaderboardEntryModel] from a Firestore [DocumentSnapshot].
  ///
  /// The [rank] is computed externally based on query ordering and passed in.
  factory LeaderboardEntryModel.fromDocument(DocumentSnapshot doc, int rank) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LeaderboardEntryModel(
      userId: doc.id,
      name: data['name'] as String? ?? 'Unknown',
      photoUrl: data['photoUrl'] as String? ?? '',
      score: data['score'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      rank: rank,
    );
  }

  /// Creates a [LeaderboardEntryModel] from a JSON map.
  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      photoUrl: json['photoUrl'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      rank: json['rank'] as int? ?? 0,
    );
  }

  /// Serializes this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'score': score,
      'level': level,
      'rank': rank,
    };
  }
}
