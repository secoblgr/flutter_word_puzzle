/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Word Puzzle';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String wordsCollection = 'words';
  static const String scoresCollection = 'scores';
  static const String duelsCollection = 'duels';
  static const String friendRequestsCollection = 'friend_requests';
  static const String duelInvitesCollection = 'duel_invites';

  // Game settings
  static const int maxLevel = 100;
  static const int wordsPerLevel = 5;
  static const int baseTimerSeconds = 120;
  static const int bonusTimePerCorrect = 8;
  static const int basePointsPerWord = 100;
  static const int maxHintsPerGame = 3;

  // Difficulty thresholds (levels)
  // Level  1-5  → difficulty 1  (3-letter words)
  // Level  6-10 → difficulty 2  (4-letter words)
  // Level 11-20 → difficulty 3  (5-letter words)
  // Level 21-30 → difficulty 4  (6-letter words)
  // Level 31-40 → difficulty 5-6 (6-7 letter words)
  // Level 41-60 → difficulty 7-8 (7-9 letter words)
  // Level 61+   → difficulty 9-10 (10+ letter words)
  static const int easyMaxLevel = 30;
  static const int mediumMaxLevel = 60;
  // Above 60 = hard

  // Duel settings
  static const int duelWordCount = 18;
  static const int duelTimerSeconds = 300;
}
