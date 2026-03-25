import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';

/// Data-layer model that extends [DuelEntity] with serialization capabilities.
class DuelModel extends DuelEntity {
  const DuelModel({
    required super.id,
    required super.player1Id,
    super.player2Id,
    required super.status,
    super.winnerId,
    required super.wordIds,
    super.duelWords,
    required super.player1Score,
    required super.player2Score,
    required super.createdAt,
  });

  /// Creates a [DuelModel] from a Firestore [DocumentSnapshot].
  factory DuelModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DuelModel.fromJson({...data, 'id': doc.id});
  }

  /// Creates a [DuelModel] from a JSON map.
  factory DuelModel.fromJson(Map<String, dynamic> json) {
    // Parse duelWords list from Firestore.
    final rawWords = json['duelWords'] as List<dynamic>? ?? [];
    final duelWords = rawWords
        .map((w) => DuelWord.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();

    return DuelModel(
      id: json['id'] as String? ?? '',
      player1Id: json['player1Id'] as String? ?? '',
      player2Id: json['player2Id'] as String?,
      status: _statusFromString(json['status'] as String? ?? 'waiting'),
      winnerId: json['winnerId'] as String?,
      wordIds: List<String>.from(json['wordIds'] as List? ?? []),
      duelWords: duelWords,
      player1Score: json['player1Score'] as int? ?? 0,
      player2Score: json['player2Score'] as int? ?? 0,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  /// Serializes this model to a JSON map suitable for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'player1Id': player1Id,
      'player2Id': player2Id,
      'status': status.name,
      'winnerId': winnerId,
      'wordIds': wordIds,
      'duelWords': duelWords.map((w) => w.toJson()).toList(),
      'player1Score': player1Score,
      'player2Score': player2Score,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DuelStatus _statusFromString(String value) {
    return DuelStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DuelStatus.waiting,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
