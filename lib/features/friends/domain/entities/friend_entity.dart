import 'package:equatable/equatable.dart';

/// Represents a friend in the domain layer.
class FriendEntity extends Equatable {
  final String id;
  final String name;
  final String photoUrl;
  final int score;
  final int level;
  final bool isOnline;
  final String friendCode;

  const FriendEntity({
    required this.id,
    required this.name,
    this.photoUrl = '',
    this.score = 0,
    this.level = 1,
    this.isOnline = false,
    this.friendCode = '',
  });

  @override
  List<Object?> get props => [id, name, photoUrl, score, level, isOnline, friendCode];
}
