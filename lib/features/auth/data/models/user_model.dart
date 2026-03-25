import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:word_puzzle/features/auth/domain/entities/user_entity.dart';

/// Data-layer model that extends [UserEntity] with serialization capabilities.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.photoUrl,
    super.score,
    super.level,
    super.friends,
    super.friendCode,
    super.categoryLevels,
  });

  /// Creates a [UserModel] from a Firestore document snapshot map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      friends: List<String>.from(json['friends'] as List? ?? []),
      friendCode: json['friendCode'] as String? ?? '',
      categoryLevels: _parseCategoryLevels(json['categoryLevels']),
    );
  }

  /// Creates a [UserModel] from a Firestore [DocumentSnapshot].
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson({...data, 'id': doc.id});
  }

  /// Creates a [UserModel] from a Firebase Auth [User] with default game values.
  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    // Generate unique guest name for anonymous users.
    final guestName = () {
      final hash = user.uid.hashCode.abs().toRadixString(16).toUpperCase();
      final suffix = hash.length >= 4 ? hash.substring(0, 4) : hash.padLeft(4, '0');
      return 'Guest_$suffix';
    }();

    return UserModel(
      id: user.uid,
      name: user.displayName ?? guestName,
      email: user.email ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }

  /// Creates a [UserModel] from a domain [UserEntity].
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      photoUrl: entity.photoUrl,
      score: entity.score,
      level: entity.level,
      friends: entity.friends,
      friendCode: entity.friendCode,
      categoryLevels: entity.categoryLevels,
    );
  }

  /// Serializes this model to a JSON map suitable for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'score': score,
      'level': level,
      'friends': friends,
      'friendCode': friendCode,
      'categoryLevels': categoryLevels,
    };
  }

  /// Returns a copy with the given fields replaced.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    int? score,
    int? level,
    List<String>? friends,
    String? friendCode,
    Map<String, int>? categoryLevels,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      score: score ?? this.score,
      level: level ?? this.level,
      friends: friends ?? this.friends,
      friendCode: friendCode ?? this.friendCode,
      categoryLevels: categoryLevels ?? this.categoryLevels,
    );
  }

  /// Safely parses the categoryLevels field from Firestore.
  static Map<String, int> _parseCategoryLevels(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 1));
    }
    return {};
  }
}
