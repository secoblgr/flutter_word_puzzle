import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/features/friends/domain/entities/friend_entity.dart';

/// Data-layer model that extends [FriendEntity] with serialization capabilities.
class FriendModel extends FriendEntity {
  const FriendModel({
    required super.id,
    required super.name,
    super.photoUrl,
    super.score,
    super.level,
    super.isOnline,
    super.friendCode,
  });

  /// Creates a [FriendModel] from a Firestore [DocumentSnapshot].
  factory FriendModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendModel.fromJson({...data, 'id': doc.id});
  }

  /// Creates a [FriendModel] from a JSON map.
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      isOnline: json['isOnline'] as bool? ?? false,
      friendCode: json['friendCode'] as String? ?? '',
    );
  }

  /// Serializes this model to a JSON map suitable for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'score': score,
      'level': level,
      'isOnline': isOnline,
      'friendCode': friendCode,
    };
  }
}
