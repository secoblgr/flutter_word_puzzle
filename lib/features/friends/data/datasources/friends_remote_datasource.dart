import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/features/friends/data/models/friend_model.dart';

/// Contract for remote friend data operations.
abstract class FriendsRemoteDataSource {
  Future<List<FriendModel>> getFriends(String userId);
  Future<void> addFriend(String userId, String friendId);
  Future<void> removeFriend(String userId, String friendId);
  Future<List<FriendModel>> searchUsers(String query);
  Future<FriendModel?> findUserById(String userId);
  Future<FriendModel?> findUserByCode(String code);

  // Friend request operations
  Future<void> sendFriendRequest(String fromId, String toId);
  Future<void> acceptFriendRequest(String requestId, String userId, String friendId);
  Future<void> rejectFriendRequest(String requestId);
  Future<List<FriendRequestModel>> getPendingRequests(String userId);
  Future<List<FriendRequestModel>> getSentRequests(String userId);
}

/// Represents a friend request document.
class FriendRequestModel {
  final String id;
  final String fromId;
  final String toId;
  final String fromName;
  final String fromPhotoUrl;
  final String fromFriendCode;
  final String toName;
  final String toPhotoUrl;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  const FriendRequestModel({
    required this.id,
    required this.fromId,
    required this.toId,
    this.fromName = '',
    this.fromPhotoUrl = '',
    this.fromFriendCode = '',
    this.toName = '',
    this.toPhotoUrl = '',
    this.status = 'pending',
    required this.createdAt,
  });

  factory FriendRequestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendRequestModel(
      id: doc.id,
      fromId: data['fromId'] as String? ?? '',
      toId: data['toId'] as String? ?? '',
      fromName: data['fromName'] as String? ?? '',
      fromPhotoUrl: data['fromPhotoUrl'] as String? ?? '',
      fromFriendCode: data['fromFriendCode'] as String? ?? '',
      toName: data['toName'] as String? ?? '',
      toPhotoUrl: data['toPhotoUrl'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Firebase-backed implementation of [FriendsRemoteDataSource].
class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  final FirebaseFirestore firestore;

  FriendsRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      firestore.collection(AppConstants.friendRequestsCollection);

  @override
  Future<List<FriendModel>> getFriends(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw const ServerException('User not found');
      }

      final data = userDoc.data() ?? {};
      final friendIds = List<String>.from(data['friends'] as List? ?? []);

      if (friendIds.isEmpty) return [];

      final friends = <FriendModel>[];
      for (final friendId in friendIds) {
        final friendDoc = await _usersCollection.doc(friendId).get();
        if (friendDoc.exists) {
          friends.add(FriendModel.fromDocument(friendDoc));
        }
      }

      return friends;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to get friends: ${e.toString()}');
    }
  }

  @override
  Future<void> addFriend(String userId, String friendId) async {
    try {
      final batch = firestore.batch();

      batch.update(_usersCollection.doc(userId), {
        'friends': FieldValue.arrayUnion([friendId]),
      });

      batch.update(_usersCollection.doc(friendId), {
        'friends': FieldValue.arrayUnion([userId]),
      });

      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to add friend: ${e.toString()}');
    }
  }

  @override
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      final batch = firestore.batch();

      batch.update(_usersCollection.doc(userId), {
        'friends': FieldValue.arrayRemove([friendId]),
      });

      batch.update(_usersCollection.doc(friendId), {
        'friends': FieldValue.arrayRemove([userId]),
      });

      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to remove friend: ${e.toString()}');
    }
  }

  @override
  Future<List<FriendModel>> searchUsers(String query) async {
    try {
      final querySnapshot = await _usersCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => FriendModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to search users: ${e.toString()}');
    }
  }

  @override
  Future<FriendModel?> findUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return FriendModel.fromDocument(doc);
    } catch (e) {
      throw ServerException('Failed to find user: ${e.toString()}');
    }
  }

  @override
  Future<FriendModel?> findUserByCode(String code) async {
    try {
      final snapshot = await _usersCollection
          .where('friendCode', isEqualTo: code)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return FriendModel.fromDocument(snapshot.docs.first);
    } catch (e) {
      throw ServerException('Failed to find user by code: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Friend Request Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendFriendRequest(String fromId, String toId) async {
    try {
      // Check if a pending request already exists.
      // Use only fromId filter to avoid composite index requirement,
      // then filter client-side.
      final existingSnapshot = await _requestsCollection
          .where('fromId', isEqualTo: fromId)
          .get();

      final alreadySent = existingSnapshot.docs.any((doc) {
        final data = doc.data();
        return data['toId'] == toId && data['status'] == 'pending';
      });

      if (alreadySent) {
        throw const ServerException('Friend request already sent');
      }

      // Check if already friends.
      final userDoc = await _usersCollection.doc(fromId).get();
      final userData = userDoc.data() ?? {};
      final currentFriends = List<String>.from(userData['friends'] as List? ?? []);
      if (currentFriends.contains(toId)) {
        throw const ServerException('Already friends');
      }

      // Get sender info for the request.
      final fromName = userData['name'] as String? ?? '';
      final fromPhotoUrl = userData['photoUrl'] as String? ?? '';
      final fromFriendCode = userData['friendCode'] as String? ?? '';

      // Get receiver info.
      final toDoc = await _usersCollection.doc(toId).get();
      final toData = toDoc.data() ?? {};
      final toName = toData['name'] as String? ?? '';
      final toPhotoUrl = toData['photoUrl'] as String? ?? '';

      await _requestsCollection.add({
        'fromId': fromId,
        'toId': toId,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'fromFriendCode': fromFriendCode,
        'toName': toName,
        'toPhotoUrl': toPhotoUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to send friend request: ${e.toString()}');
    }
  }

  @override
  Future<void> acceptFriendRequest(String requestId, String userId, String friendId) async {
    try {
      // Update request status.
      await _requestsCollection.doc(requestId).update({
        'status': 'accepted',
      });

      // Add each other as friends.
      await addFriend(userId, friendId);
    } catch (e) {
      throw ServerException('Failed to accept friend request: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _requestsCollection.doc(requestId).update({
        'status': 'rejected',
      });
    } catch (e) {
      throw ServerException('Failed to reject friend request: ${e.toString()}');
    }
  }

  @override
  Future<List<FriendRequestModel>> getPendingRequests(String userId) async {
    try {
      // No orderBy to avoid composite index requirement.
      final snapshot = await _requestsCollection
          .where('toId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final requests = snapshot.docs
          .map((doc) => FriendRequestModel.fromDocument(doc))
          .toList();

      // Sort client-side, newest first.
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      throw ServerException('Failed to get pending requests: ${e.toString()}');
    }
  }

  @override
  Future<List<FriendRequestModel>> getSentRequests(String userId) async {
    try {
      final snapshot = await _requestsCollection
          .where('fromId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final requests = snapshot.docs
          .map((doc) => FriendRequestModel.fromDocument(doc))
          .toList();

      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      throw ServerException('Failed to get sent requests: ${e.toString()}');
    }
  }
}
