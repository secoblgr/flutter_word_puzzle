import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';

/// Displays the top 3 players as a podium with gold, silver, and bronze medals.
///
/// Layout order: Silver (2nd) | Gold (1st, taller) | Bronze (3rd).
class PodiumWidget extends StatelessWidget {
  final List<LeaderboardEntry> topThree;

  const PodiumWidget({super.key, required this.topThree});

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Silver - 2nd place (left).
          if (second != null)
            Expanded(
              child: _PodiumPlayer(
                entry: second,
                podiumHeight: 90,
                medalColor: const Color(0xFFC0C0C0),
                medalLabel: '2',
                delay: 200,
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),

          const SizedBox(width: 8),

          // Gold - 1st place (center, tallest).
          if (first != null)
            Expanded(
              child: _PodiumPlayer(
                entry: first,
                podiumHeight: 120,
                medalColor: const Color(0xFFFFD700),
                medalLabel: '1',
                delay: 0,
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),

          const SizedBox(width: 8),

          // Bronze - 3rd place (right).
          if (third != null)
            Expanded(
              child: _PodiumPlayer(
                entry: third,
                podiumHeight: 70,
                medalColor: const Color(0xFFCD7F32),
                medalLabel: '3',
                delay: 400,
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single podium player
// ---------------------------------------------------------------------------

class _PodiumPlayer extends StatelessWidget {
  final LeaderboardEntry entry;
  final double podiumHeight;
  final Color medalColor;
  final String medalLabel;
  final int delay;

  const _PodiumPlayer({
    required this.entry,
    required this.podiumHeight,
    required this.medalColor,
    required this.medalLabel,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal badge.
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: medalColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            medalLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Avatar.
        CircleAvatar(
          radius: medalLabel == '1' ? 36 : 28,
          backgroundColor: AppColors.darkBorder,
          backgroundImage: entry.photoUrl.isNotEmpty
              ? NetworkImage(entry.photoUrl)
              : null,
          child: entry.photoUrl.isEmpty
              ? Icon(
                  Icons.person_rounded,
                  size: medalLabel == '1' ? 36 : 28,
                  color: Colors.white54,
                )
              : null,
        ),

        const SizedBox(height: 8),

        // Name.
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 4),

        // Score.
        Text(
          '${entry.score} pts',
          style: TextStyle(
            color: medalColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 8),

        // Podium bar.
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.6),
                medalColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            border: Border.all(
              color: medalColor.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'Lv ${entry.level}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
          delay: Duration(milliseconds: delay),
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay));
  }
}
