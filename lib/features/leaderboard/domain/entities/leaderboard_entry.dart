import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  final String userId;
  final String name;
  final String photoUrl;
  final int score;
  final int level;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.score,
    required this.level,
    required this.rank,
  });

  @override
  List<Object?> get props => [userId, name, photoUrl, score, level, rank];
}
