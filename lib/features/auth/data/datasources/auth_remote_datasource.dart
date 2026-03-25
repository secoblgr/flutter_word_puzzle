import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:word_puzzle/core/error/exceptions.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/features/auth/data/models/user_model.dart';

/// Contract for remote authentication data operations.
abstract class AuthRemoteDataSource {
  /// Signs in with Google and returns the user model.
  /// If the current user is anonymous, links the Google account to keep progress.
  Future<UserModel> signInWithGoogle();

  /// Signs in anonymously and returns the user model.
  /// Reuses the existing anonymous session if one is still alive.
  Future<UserModel> signInAnonymously();

  /// Signs out the current user.
  /// For anonymous users this only clears the app state — the Firebase
  /// anonymous session is preserved so progress is not lost.
  Future<void> signOut();

  /// Returns the current user from Firestore, or null if unauthenticated.
  Future<UserModel?> getCurrentUser();

  /// Updates the user document in Firestore and returns the updated model.
  Future<UserModel> updateUser(UserModel user);
}

/// Firebase-backed implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.firestore,
  });

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection(AppConstants.usersCollection);

  // ---------------------------------------------------------------------------
  // Google Sign-In (with anonymous account linking)
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = firebaseAuth.currentUser;

      User? firebaseUser;

      // If the current user is anonymous, try to link the Google credential
      // so all guest progress is preserved under the new Google account.
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          final linked = await currentUser.linkWithCredential(credential);
          firebaseUser = linked.user;
        } on FirebaseAuthException catch (e) {
          // credential-already-in-use → the Google account already exists.
          // Sign in normally instead.
          if (e.code == 'credential-already-in-use') {
            final userCredential =
                await firebaseAuth.signInWithCredential(credential);
            firebaseUser = userCredential.user;
          } else {
            rethrow;
          }
        }
      } else {
        final userCredential =
            await firebaseAuth.signInWithCredential(credential);
        firebaseUser = userCredential.user;
      }

      if (firebaseUser == null) {
        throw const AuthException('Firebase sign-in returned no user');
      }

      return await _createOrUpdateFirestoreUser(firebaseUser);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Google sign-in failed: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Anonymous Sign-In (reuse existing session)
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel> signInAnonymously() async {
    try {
      // If there is already an anonymous session, reuse it.
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        return await _createOrUpdateFirestoreUser(currentUser);
      }

      // No existing session → create a new anonymous user.
      final userCredential = await firebaseAuth.signInAnonymously();
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Anonymous sign-in returned no user');
      }

      return await _createOrUpdateFirestoreUser(firebaseUser);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Anonymous sign-in failed: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    try {
      final currentUser = firebaseAuth.currentUser;

      // For anonymous users, do NOT sign out of Firebase Auth.
      // The anonymous session stays alive so the user can resume later
      // without losing progress.
      if (currentUser != null && currentUser.isAnonymous) {
        // Only sign out of Google (no-op for anon, but safe).
        await googleSignIn.signOut();
        return;
      }

      // For Google / email users, fully sign out.
      await Future.wait([
        firebaseAuth.signOut(),
        googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Sign-out failed: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Get Current User
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final doc = await _usersCollection.doc(firebaseUser.uid).get();
      if (!doc.exists) {
        return UserModel.fromFirebaseUser(firebaseUser);
      }

      return UserModel.fromDocument(doc);
    } catch (e) {
      throw AuthException('Failed to get current user: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Update User
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());

      final updatedDoc = await _usersCollection.doc(user.id).get();
      return UserModel.fromDocument(updatedDoc);
    } catch (e) {
      throw AuthException('Failed to update user: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Creates or merges a Firestore user document from a Firebase Auth user.
  Future<UserModel> _createOrUpdateFirestoreUser(User firebaseUser) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      // Merge updated auth profile fields while preserving game data.
      final existingName = data['name'] as String? ?? '';
      final updates = <String, dynamic>{
        'name': firebaseUser.displayName ??
            (existingName.isNotEmpty ? existingName : _generateGuestName(firebaseUser.uid)),
        'email': firebaseUser.email ?? data['email'] ?? '',
        'photoUrl': firebaseUser.photoURL ?? data['photoUrl'] ?? '',
      };

      // Generate friendCode if missing.
      if ((data['friendCode'] as String? ?? '').isEmpty) {
        updates['friendCode'] = await _generateUniqueFriendCode();
      }

      await docRef.update(updates);
    } else {
      final friendCode = await _generateUniqueFriendCode();
      final newUser = UserModel.fromFirebaseUser(firebaseUser)
          .copyWith(friendCode: friendCode);
      await docRef.set(newUser.toJson());
    }

    final updatedDoc = await docRef.get();
    return UserModel.fromDocument(updatedDoc);
  }

  /// Generates a unique 6-digit numeric code not used by any other user.
  Future<String> _generateUniqueFriendCode() async {
    final rng = Random();
    for (int attempt = 0; attempt < 50; attempt++) {
      final code = (100000 + rng.nextInt(900000)).toString(); // 100000–999999
      final existing = await _usersCollection
          .where('friendCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return code;
    }
    // Fallback: extremely unlikely we collide 50 times.
    return (100000 + rng.nextInt(900000)).toString();
  }

  /// Generates a unique guest nickname from the user's UID.
  /// Format: Guest_XXXX (4 hex chars from uid hash).
  String _generateGuestName(String uid) {
    final hash = uid.hashCode.abs().toRadixString(16).toUpperCase();
    final suffix = hash.length >= 4 ? hash.substring(0, 4) : hash.padLeft(4, '0');
    return 'Guest_$suffix';
  }
}
