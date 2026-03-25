import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:word_puzzle/features/duel/data/datasources/duel_remote_datasource.dart';

/// Wraps the entire app and listens for duel invites in real-time.
///
/// Three Firestore real-time listeners:
/// 1. Incoming invites (I'm receiver) → show popup
/// 2. My sent invites accepted → "Duel Starting!" + navigate
/// 3. My sent invites rejected → snackbar notification
class DuelInviteListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const DuelInviteListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<DuelInviteListener> createState() => _DuelInviteListenerState();
}

class _DuelInviteListenerState extends State<DuelInviteListener> {
  StreamSubscription<QuerySnapshot>? _incomingSub;
  StreamSubscription<QuerySnapshot>? _acceptedSub;
  StreamSubscription<QuerySnapshot>? _rejectedSub;

  String? _currentUserId;
  bool _isDialogShowing = false;
  bool _isFirstIncomingSnapshot = true;
  bool _isFirstAcceptedSnapshot = true;
  bool _isFirstRejectedSnapshot = true;

  // Track IDs we've already handled to avoid duplicates.
  final Set<String> _handledIds = {};

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }

  void _cancelAll() {
    _incomingSub?.cancel();
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _incomingSub = null;
    _acceptedSub = null;
    _rejectedSub = null;
  }

  void _startListening(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _cancelAll();
    _handledIds.clear();
    _isFirstIncomingSnapshot = true;
    _isFirstAcceptedSnapshot = true;
    _isFirstRejectedSnapshot = true;

    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection(AppConstants.duelInvitesCollection);

    // ── 1) INCOMING pending invites (I am the receiver) ──
    _incomingSub = ref
        .where('toId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (_isFirstIncomingSnapshot) {
        // Skip the initial snapshot — these are old invites already in Firestore.
        _isFirstIncomingSnapshot = false;
        // Mark existing docs as handled so they don't trigger later.
        for (final doc in snapshot.docs) {
          _handledIds.add('incoming_${doc.id}');
        }
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          final key = 'incoming_${doc.id}';
          if (_handledIds.contains(key)) continue;
          _handledIds.add(key);

          final data = doc.data() ?? {};
          final fromName = data['fromName'] as String? ?? 'Someone';

          _showIncomingPopup(doc.id, fromName);
        }
      }
    });

    // ── 2) MY SENT invites that got ACCEPTED ──
    _acceptedSub = ref
        .where('fromId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      if (_isFirstAcceptedSnapshot) {
        _isFirstAcceptedSnapshot = false;
        for (final doc in snapshot.docs) {
          _handledIds.add('accepted_${doc.id}');
        }
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          final doc = change.doc;
          final key = 'accepted_${doc.id}';
          if (_handledIds.contains(key)) continue;
          _handledIds.add(key);

          final data = doc.data() ?? {};
          final duelId = data['duelId'] as String?;
          final toName = data['toName'] as String? ?? 'Your friend';

          if (duelId != null && duelId.isNotEmpty) {
            _showDuelStartingPopup(duelId, toName);
          }
        }
      }
    });

    // ── 3) MY SENT invites that got REJECTED ──
    _rejectedSub = ref
        .where('fromId', isEqualTo: userId)
        .where('status', isEqualTo: 'rejected')
        .snapshots()
        .listen((snapshot) {
      if (_isFirstRejectedSnapshot) {
        _isFirstRejectedSnapshot = false;
        for (final doc in snapshot.docs) {
          _handledIds.add('rejected_${doc.id}');
        }
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          final doc = change.doc;
          final key = 'rejected_${doc.id}';
          if (_handledIds.contains(key)) continue;
          _handledIds.add(key);

          final data = doc.data() ?? {};
          final toName = data['toName'] as String? ?? 'Your friend';

          _showRejectedSnackbar(toName);
        }
      }
    });
  }

  void _stopListening() {
    _cancelAll();
    _currentUserId = null;
    _handledIds.clear();
  }

  // ---------------------------------------------------------------------------
  // 1. Incoming invite popup (receiver)
  // ---------------------------------------------------------------------------

  void _showIncomingPopup(String inviteId, String fromName) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) {
      _isDialogShowing = false;
      return;
    }

    showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_mma_rounded,
                    color: Color(0xFFFF6B6B), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Duel Challenge!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$fromName wants to duel you!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 15)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dCtx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.wrong,
                        side: const BorderSide(color: AppColors.wrong),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dCtx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.correct,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Accept',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((accepted) async {
      _isDialogShowing = false;
      if (accepted == true) {
        await _handleAccept(inviteId);
      } else {
        await _handleReject(inviteId);
      }
    });
  }

  Future<void> _handleAccept(String inviteId) async {
    try {
      final ds = DuelRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
      final duelId = await ds.acceptDuelInvite(inviteId, _currentUserId!);

      if (mounted) {
        final ctx = widget.navigatorKey.currentContext;
        if (ctx != null) {
          GoRouter.of(ctx).go('/duel/room', extra: {
            'duelId': duelId,
            'userId': _currentUserId!,
          });
        }
      }
    } catch (e) {
      debugPrint('Error accepting duel invite: $e');
    }
  }

  Future<void> _handleReject(String inviteId) async {
    try {
      final ds = DuelRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
      await ds.rejectDuelInvite(inviteId);
    } catch (e) {
      debugPrint('Error rejecting duel invite: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Duel starting popup (sender — opponent accepted)
  // ---------------------------------------------------------------------------

  void _showDuelStartingPopup(String duelId, String opponentName) {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(dCtx).canPop()) {
            Navigator.of(dCtx).pop();
          }
        });

        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.correct.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.correct, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Duel Starting!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$opponentName accepted your challenge!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 15)),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        );
      },
    ).then((_) {
      final routerCtx = widget.navigatorKey.currentContext;
      if (routerCtx != null && _currentUserId != null) {
        GoRouter.of(routerCtx).go('/duel/room', extra: {
          'duelId': duelId,
          'userId': _currentUserId!,
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 3. Rejection snackbar (sender — opponent rejected)
  // ---------------------------------------------------------------------------

  void _showRejectedSnackbar(String opponentName) {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;

    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$opponentName declined your duel',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.wrong,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Build — also check initial auth state
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _startListening(state.user.id);
        } else {
          _stopListening();
        }
      },
      child: Builder(
        builder: (context) {
          // Also check current auth state on first build.
          // BlocListener only fires on state *changes*, so if the user
          // is already authenticated when this widget mounts, we need
          // to manually start listening.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated && _currentUserId == null) {
              _startListening(authState.user.id);
            }
          });
          return widget.child;
        },
      ),
    );
  }
}
