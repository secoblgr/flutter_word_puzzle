import 'package:equatable/equatable.dart';

/// Represents an authenticated user in the domain layer.
class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final int score;
  final int level;
  final List<String> friends;

  /// A short 6-digit code uniquely identifying this user for friend requests.
  final String friendCode;

  /// Per-category level progress. Key = category name, value = current level.
  /// Falls back to global [level] for categories not yet played.
  final Map<String, int> categoryLevels;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl = '',
    this.score = 0,
    this.level = 1,
    this.friends = const [],
    this.friendCode = '',
    this.categoryLevels = const {},
  });

  /// Returns the level for a specific category, defaulting to 1.
  int levelForCategory(String category) => categoryLevels[category] ?? 1;

  @override
  List<Object?> get props =>
      [id, name, email, photoUrl, score, level, friends, friendCode, categoryLevels];
}
