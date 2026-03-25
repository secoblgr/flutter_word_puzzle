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

  /// Current daily streak count.
  final int streak;

  /// Total experience points.
  final int xp;

  /// ISO date string of the last day the user played (e.g. '2026-03-25').
  final String lastPlayedDate;

  /// Number of games the user has played today.
  final int gamesPlayedToday;

  /// Number of duels the user has won today.
  final int duelsWonToday;

  /// Whether the user has added a friend today.
  final bool friendAddedToday;

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
    this.streak = 0,
    this.xp = 0,
    this.lastPlayedDate = '',
    this.gamesPlayedToday = 0,
    this.duelsWonToday = 0,
    this.friendAddedToday = false,
  });

  /// Returns the level for a specific category, defaulting to 1.
  int levelForCategory(String category) => categoryLevels[category] ?? 1;

  /// Returns a copy with the given fields replaced.
  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    int? score,
    int? level,
    List<String>? friends,
    String? friendCode,
    Map<String, int>? categoryLevels,
    int? streak,
    int? xp,
    String? lastPlayedDate,
    int? gamesPlayedToday,
    int? duelsWonToday,
    bool? friendAddedToday,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      score: score ?? this.score,
      level: level ?? this.level,
      friends: friends ?? this.friends,
      friendCode: friendCode ?? this.friendCode,
      categoryLevels: categoryLevels ?? this.categoryLevels,
      streak: streak ?? this.streak,
      xp: xp ?? this.xp,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      gamesPlayedToday: gamesPlayedToday ?? this.gamesPlayedToday,
      duelsWonToday: duelsWonToday ?? this.duelsWonToday,
      friendAddedToday: friendAddedToday ?? this.friendAddedToday,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        photoUrl,
        score,
        level,
        friends,
        friendCode,
        categoryLevels,
        streak,
        xp,
        lastPlayedDate,
        gamesPlayedToday,
        duelsWonToday,
        friendAddedToday,
      ];
}
