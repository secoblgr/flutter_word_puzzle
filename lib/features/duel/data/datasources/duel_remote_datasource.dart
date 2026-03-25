import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/features/duel/data/models/duel_model.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/animals_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/food_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/jobs_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/nature_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/sports_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/technology_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/music_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/geography_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/science_words.dart';
import 'package:word_puzzle/features/game/data/datasources/word_bank/history_words.dart';
import 'package:word_puzzle/features/game/data/models/word_model.dart';

// ---------------------------------------------------------------------------
// Duel invite model
// ---------------------------------------------------------------------------

class DuelInviteModel {
  final String id;
  final String fromId;
  final String toId;
  final String fromName;
  final String toName;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? duelId; // Set when accepted and duel is created.
  final DateTime createdAt;

  const DuelInviteModel({
    required this.id,
    required this.fromId,
    required this.toId,
    this.fromName = '',
    this.toName = '',
    this.status = 'pending',
    this.duelId,
    required this.createdAt,
  });

  factory DuelInviteModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DuelInviteModel(
      id: doc.id,
      fromId: data['fromId'] as String? ?? '',
      toId: data['toId'] as String? ?? '',
      fromName: data['fromName'] as String? ?? '',
      toName: data['toName'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      duelId: data['duelId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Contract
// ---------------------------------------------------------------------------

abstract class DuelRemoteDataSource {
  Future<DuelModel> createDuel(String playerId, List<String> wordIds);
  Future<DuelModel> joinDuel(String duelId, String playerId);
  Stream<DuelModel> watchDuel(String duelId);
  Future<void> submitDuelResult(String duelId, String playerId, int score, {bool isFinal = false});
  Future<List<DuelModel>> getAvailableDuels();

  // Duel invite operations
  Future<void> sendDuelInvite(String fromId, String toId);
  Future<String> acceptDuelInvite(String inviteId, String userId);
  Future<void> rejectDuelInvite(String inviteId);
  Future<List<DuelInviteModel>> getPendingDuelInvites(String userId);
  Stream<List<DuelInviteModel>> watchPendingDuelInvites(String userId);
}

// ---------------------------------------------------------------------------
// Firebase implementation
// ---------------------------------------------------------------------------

class DuelRemoteDataSourceImpl implements DuelRemoteDataSource {
  final FirebaseFirestore firestore;

  DuelRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _duelsCollection =>
      firestore.collection(AppConstants.duelsCollection);

  CollectionReference<Map<String, dynamic>> get _invitesCollection =>
      firestore.collection(AppConstants.duelInvitesCollection);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection(AppConstants.usersCollection);

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  @override
  Future<DuelModel> createDuel(String playerId, List<String> wordIds) async {
    try {
      // Generate real duel words: 8 words, easy → hard.
      final duelWords = _generateDuelWords();

      final now = FieldValue.serverTimestamp();
      final data = {
        'player1Id': playerId,
        'player2Id': null,
        'status': 'waiting',
        'winnerId': null,
        'wordIds': duelWords.map((w) => w.word).toList(),
        'duelWords': duelWords.map((w) => w.toJson()).toList(),
        'player1Score': 0,
        'player2Score': 0,
        'player1Submitted': false,
        'player2Submitted': false,
        'createdAt': now,
      };

      final docRef = await _duelsCollection.add(data);
      final snapshot = await docRef.get();
      return DuelModel.fromDocument(snapshot);
    } catch (e) {
      throw ServerException('Failed to create duel: ${e.toString()}');
    }
  }

  /// Generate duel words: progressive difficulty (3→4→5→6→7→8 letters).
  /// 3 words per difficulty level = 18 words total.
  /// Words go from easy to hard so the duel gets harder over time.
  List<DuelWord> _generateDuelWords() {
    final rng = Random();

    // Combine all 10 word banks.
    final allWords = <WordModel>[
      ...animalsWords,
      ...foodWords,
      ...jobsWords,
      ...natureWords,
      ...sportsWords,
      ...technologyWords,
      ...musicWords,
      ...geographyWords,
      ...scienceWords,
      ...historyWords,
    ];

    // difficulty 1 = 3 letters, 2 = 4 letters, ..., 6 = 8 letters
    // 3 words from each level → 18 total, ordered easy → hard
    final selected = <WordModel>[];
    for (int diff = 1; diff <= 6; diff++) {
      final pool = allWords.where((w) => w.difficulty == diff).toList()
        ..shuffle(rng);
      selected.addAll(pool.take(3));
    }

    return selected
        .map((w) => DuelWord(
              word: w.word,
              definition: w.definition,
              difficulty: w.difficulty,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Join
  // ---------------------------------------------------------------------------

  @override
  Future<DuelModel> joinDuel(String duelId, String playerId) async {
    try {
      final docRef = _duelsCollection.doc(duelId);

      await docRef.update({
        'player2Id': playerId,
        'status': 'playing',
      });

      final snapshot = await docRef.get();
      return DuelModel.fromDocument(snapshot);
    } catch (e) {
      throw ServerException('Failed to join duel: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Watch
  // ---------------------------------------------------------------------------

  @override
  Stream<DuelModel> watchDuel(String duelId) {
    return _duelsCollection.doc(duelId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw ServerException('Duel not found');
      }
      return DuelModel.fromDocument(snapshot);
    });
  }

  // ---------------------------------------------------------------------------
  // Submit result
  // ---------------------------------------------------------------------------

  @override
  Future<void> submitDuelResult(
    String duelId,
    String playerId,
    int score, {
    bool isFinal = false,
  }) async {
    try {
      final docRef = _duelsCollection.doc(duelId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        throw ServerException('Duel not found');
      }

      final data = snapshot.data()!;
      final currentStatus = data['status'] as String? ?? 'playing';

      // Don't update if duel is already finished.
      if (currentStatus == 'finished') return;

      final isPlayer1 = data['player1Id'] == playerId;

      final updates = <String, dynamic>{};
      if (isPlayer1) {
        updates['player1Score'] = score;
        // Only mark as submitted when player is truly done (all words or time up).
        if (isFinal) updates['player1Submitted'] = true;
      } else {
        updates['player2Score'] = score;
        if (isFinal) updates['player2Submitted'] = true;
      }

      await docRef.update(updates);

      // Only check for game end when this is a final submission.
      if (isFinal) {
        final updatedSnapshot = await docRef.get();
        final updatedData = updatedSnapshot.data()!;

        final player1Submitted = updatedData['player1Submitted'] as bool? ?? false;
        final player2Submitted = updatedData['player2Submitted'] as bool? ?? false;

        if (player1Submitted && player2Submitted) {
          final p1Score = updatedData['player1Score'] as int? ?? 0;
          final p2Score = updatedData['player2Score'] as int? ?? 0;

          String? winnerId;
          if (p1Score > p2Score) {
            winnerId = updatedData['player1Id'] as String?;
          } else if (p2Score > p1Score) {
            winnerId = updatedData['player2Id'] as String?;
          }

          await docRef.update({
            'status': 'finished',
            'winnerId': winnerId,
          });
        }
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to submit duel result: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Available duels
  // ---------------------------------------------------------------------------

  @override
  Future<List<DuelModel>> getAvailableDuels() async {
    try {
      final snapshot = await _duelsCollection
          .where('status', isEqualTo: 'waiting')
          .get();

      final duels =
          snapshot.docs.map((doc) => DuelModel.fromDocument(doc)).toList();

      duels.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return duels;
    } catch (e) {
      throw ServerException('Failed to fetch available duels: ${e.toString()}');
    }
  }

  // ===========================================================================
  // DUEL INVITE OPERATIONS
  // ===========================================================================

  @override
  Future<void> sendDuelInvite(String fromId, String toId) async {
    try {
      // Check for existing pending invite.
      final existing = await _invitesCollection
          .where('fromId', isEqualTo: fromId)
          .where('toId', isEqualTo: toId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw const ServerException('Duel invite already sent');
      }

      // Get sender name.
      final fromDoc = await _usersCollection.doc(fromId).get();
      final fromData = fromDoc.data() ?? {};
      final fromName = fromData['name'] as String? ?? '';

      // Get receiver name.
      final toDoc = await _usersCollection.doc(toId).get();
      final toData = toDoc.data() ?? {};
      final toName = toData['name'] as String? ?? '';

      await _invitesCollection.add({
        'fromId': fromId,
        'toId': toId,
        'fromName': fromName,
        'toName': toName,
        'status': 'pending',
        'duelId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to send duel invite: ${e.toString()}');
    }
  }

  @override
  Future<String> acceptDuelInvite(String inviteId, String userId) async {
    try {
      final inviteDoc = await _invitesCollection.doc(inviteId).get();
      if (!inviteDoc.exists) {
        throw const ServerException('Invite not found');
      }

      final inviteData = inviteDoc.data()!;
      final fromId = inviteData['fromId'] as String;

      // Create a duel with both players.
      final wordIds = List.generate(5, (i) => 'w${i + 1}');
      final duel = await createDuel(fromId, wordIds);

      // Join the second player.
      await joinDuel(duel.id, userId);

      // Update invite to accepted with duelId.
      await _invitesCollection.doc(inviteId).update({
        'status': 'accepted',
        'duelId': duel.id,
      });

      return duel.id;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to accept duel invite: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectDuelInvite(String inviteId) async {
    try {
      await _invitesCollection.doc(inviteId).update({
        'status': 'rejected',
      });
    } catch (e) {
      throw ServerException('Failed to reject duel invite: ${e.toString()}');
    }
  }

  @override
  Future<List<DuelInviteModel>> getPendingDuelInvites(String userId) async {
    try {
      final snapshot = await _invitesCollection
          .where('toId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final invites = snapshot.docs
          .map((doc) => DuelInviteModel.fromDocument(doc))
          .toList();

      invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return invites;
    } catch (e) {
      throw ServerException('Failed to get duel invites: ${e.toString()}');
    }
  }

  @override
  Stream<List<DuelInviteModel>> watchPendingDuelInvites(String userId) {
    return _invitesCollection
        .where('toId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DuelInviteModel.fromDocument(doc))
            .toList());
  }
}
