import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:word_puzzle/core/utils/constants.dart';

/// Manages daily quests, streak tracking, and XP rewards.
///
/// All updates go directly to Firestore so they persist across sessions.
/// Call [ensureDailyReset] on app start / home page load to reset
/// counters if the date has changed.
class DailyQuestManager {
  DailyQuestManager._();
  static final DailyQuestManager instance = DailyQuestManager._();

  final _firestore = FirebaseFirestore.instance;

  static const int xpQuickRound = 50;
  static const int xpWinDuel = 80;
  static const int xpAddFriend = 30;
  static const int quickRoundTarget = 3;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  DocumentReference _userDoc(String userId) =>
      _firestore.collection(AppConstants.usersCollection).doc(userId);

  // ---------------------------------------------------------------------------
  // Daily reset + streak
  // ---------------------------------------------------------------------------

  /// Check if the date has changed since last play.
  /// If so, reset daily counters and update streak.
  Future<void> ensureDailyReset(String userId) async {
    final doc = await _userDoc(userId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final lastPlayed = data['lastPlayedDate'] as String? ?? '';
    final today = _today;

    if (lastPlayed == today) return; // Already reset today.

    // Calculate streak
    int streak = data['streak'] as int? ?? 0;
    if (lastPlayed.isNotEmpty) {
      try {
        final lastDate = DateFormat('yyyy-MM-dd').parse(lastPlayed);
        final now = DateFormat('yyyy-MM-dd').parse(today);
        final diff = now.difference(lastDate).inDays;

        if (diff == 1) {
          // Consecutive day — increment streak.
          streak++;
        } else if (diff > 1) {
          // Missed a day — reset streak.
          streak = 1;
        }
      } catch (_) {
        streak = 1;
      }
    } else {
      streak = 1; // First time playing.
    }

    await _userDoc(userId).update({
      'lastPlayedDate': today,
      'gamesPlayedToday': 0,
      'duelsWonToday': 0,
      'friendAddedToday': false,
      'streak': streak,
    });
  }

  // ---------------------------------------------------------------------------
  // Quest: Quick Round (play 3 games)
  // ---------------------------------------------------------------------------

  /// Called when a game level is completed.
  /// Increments gamesPlayedToday and awards XP if quest completed.
  Future<void> onGameCompleted(String userId) async {
    final doc = await _userDoc(userId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final current = data['gamesPlayedToday'] as int? ?? 0;
    final newCount = current + 1;

    final updates = <String, dynamic>{
      'gamesPlayedToday': newCount,
    };

    // Award XP when quest target reached (exactly at target to avoid double award).
    if (newCount == quickRoundTarget) {
      final currentXp = data['xp'] as int? ?? 0;
      updates['xp'] = currentXp + xpQuickRound;
    }

    await _userDoc(userId).update(updates);
  }

  // ---------------------------------------------------------------------------
  // Quest: Win Duel
  // ---------------------------------------------------------------------------

  /// Called when the user wins a duel.
  Future<void> onDuelWon(String userId) async {
    final doc = await _userDoc(userId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final current = data['duelsWonToday'] as int? ?? 0;
    final newCount = current + 1;

    final updates = <String, dynamic>{
      'duelsWonToday': newCount,
    };

    // Award XP on first win of the day.
    if (current == 0) {
      final currentXp = data['xp'] as int? ?? 0;
      updates['xp'] = currentXp + xpWinDuel;
    }

    await _userDoc(userId).update(updates);
  }

  // ---------------------------------------------------------------------------
  // Quest: Add Friend
  // ---------------------------------------------------------------------------

  /// Called when a friend is successfully added.
  Future<void> onFriendAdded(String userId) async {
    final doc = await _userDoc(userId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final alreadyDone = data['friendAddedToday'] as bool? ?? false;

    if (alreadyDone) return; // Already awarded today.

    final currentXp = data['xp'] as int? ?? 0;
    await _userDoc(userId).update({
      'friendAddedToday': true,
      'xp': currentXp + xpAddFriend,
    });
  }
}
