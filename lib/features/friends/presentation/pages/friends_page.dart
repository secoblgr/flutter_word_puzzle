import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:word_puzzle/features/duel/presentation/bloc/duel_bloc.dart';
import 'package:word_puzzle/features/friends/data/datasources/friends_remote_datasource.dart';
import 'package:word_puzzle/features/friends/domain/entities/friend_entity.dart';
import 'package:word_puzzle/features/friends/presentation/bloc/friends_bloc.dart';

class FriendsPage extends StatefulWidget {
  final String userId;

  const FriendsPage({super.key, required this.userId});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Real-time listeners for auto-refresh.
  StreamSubscription<DocumentSnapshot>? _userDocSub;
  StreamSubscription<QuerySnapshot>? _requestsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FriendsBloc>().add(FriendsLoadRequested(widget.userId));
        _startRealTimeListeners();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _userDocSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }

  /// Listen to user document (friends array) and friend_requests in real-time.
  /// When either changes, reload the friends list.
  void _startRealTimeListeners() {
    final firestore = FirebaseFirestore.instance;

    // Listen to user doc — when friends array changes, reload.
    bool isFirstUserSnapshot = true;
    _userDocSub = firestore
        .collection(AppConstants.usersCollection)
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (isFirstUserSnapshot) {
        isFirstUserSnapshot = false;
        return; // Skip initial snapshot.
      }
      if (mounted) {
        context.read<FriendsBloc>().add(FriendsLoadRequested(widget.userId));
      }
    });

    // Listen to incoming friend requests — when new request arrives, reload.
    bool isFirstRequestSnapshot = true;
    _requestsSub = firestore
        .collection(AppConstants.friendRequestsCollection)
        .where('toId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (isFirstRequestSnapshot) {
        isFirstRequestSnapshot = false;
        return;
      }
      if (mounted) {
        context.read<FriendsBloc>().add(FriendsLoadRequested(widget.userId));
      }
    });
  }

  String get _friendCode {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.friendCode;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(context, s),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive(context).maxContentWidth,
            ),
            child: Column(
              children: [
                _buildAppBar(context, s),
                _buildSearchBar(s),
            // Tab bar: Friends | Requests
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: s.friendsTitle),
                  // Show badge if there are pending requests
                  Tab(
                    child: BlocBuilder<FriendsBloc, FriendsState>(
                      builder: (context, state) {
                        final count = state is FriendsLoaded
                            ? state.pendingRequests.length
                            : 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s.requests),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.wrong,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$count',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Friends list
                  BlocBuilder<FriendsBloc, FriendsState>(
                    builder: (context, state) {
                      if (state is FriendsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }
                      if (state is FriendsError) {
                        return _buildError(context, state.message, s);
                      }
                      if (state is FriendsLoaded) {
                        return _buildFriendsList(context, state.friends, s);
                      }
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    },
                  ),
                  // Tab 2: Pending requests
                  BlocBuilder<FriendsBloc, FriendsState>(
                    builder: (context, state) {
                      if (state is FriendsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }
                      if (state is FriendsLoaded) {
                        return _buildRequestsList(context, state.pendingRequests, s);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(BuildContext context, AppStrings s) {
    final code = _friendCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
              ),
              Expanded(
                child: Text(s.friendsTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () {
                  context.read<FriendsBloc>().add(FriendsLoadRequested(widget.userId));
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              ),
            ],
          ),
          if (code.isNotEmpty)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(s.friendCodeCopied, textAlign: TextAlign.center),
                      backgroundColor: AppColors.correct,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    ),
                  );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.tag_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('${s.myCode}: $code',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(width: 8),
                    Icon(Icons.copy_rounded,
                        color: AppColors.primary.withValues(alpha: 0.6), size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: s.searchFriends,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.4)),
          filled: true,
          fillColor: AppColors.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, String message, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, color: AppColors.wrong, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<FriendsBloc>().add(FriendsLoadRequested(widget.userId)),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Friends list
  // ---------------------------------------------------------------------------

  Widget _buildFriendsList(BuildContext context, List<FriendEntity> friends, AppStrings s) {
    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? friends
        : friends.where((f) => f.name.toLowerCase().contains(query)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? s.noFriendsYet
                  : s.noFriendsMatch,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final friend = filtered[index];
        return _FriendListTile(
          friend: friend,
          animationDelay: index * 50,
          onDismissed: () {
            context.read<FriendsBloc>().add(
                  FriendRemoveRequested(userId: widget.userId, friendId: friend.id),
                );
          },
          onDuel: () {
            // Send a duel invite to this friend.
            context.read<DuelBloc>().add(
                  DuelInviteSendRequested(
                    fromId: widget.userId,
                    toId: friend.id,
                  ),
                );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(s.duelInviteSent(friend.name),
                      textAlign: TextAlign.center),
                  backgroundColor: const Color(0xFFFF6B6B),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
              );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Pending requests list
  // ---------------------------------------------------------------------------

  Widget _buildRequestsList(BuildContext context, List<FriendRequestModel> requests, AppStrings s) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(s.noPendingRequests,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.darkBorder,
                backgroundImage:
                    req.fromPhotoUrl.isNotEmpty ? NetworkImage(req.fromPhotoUrl) : null,
                child: req.fromPhotoUrl.isEmpty
                    ? const Icon(Icons.person_rounded, size: 22, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.fromName.isNotEmpty ? req.fromName : 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(s.wantsToBeFriend,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  ],
                ),
              ),
              // Accept button
              IconButton(
                onPressed: () {
                  context.read<FriendsBloc>().add(
                        FriendRequestAcceptRequested(
                          requestId: req.id,
                          userId: widget.userId,
                          friendId: req.fromId,
                        ),
                      );
                },
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.correct, size: 32),
                tooltip: s.accept,
              ),
              // Reject button
              IconButton(
                onPressed: () {
                  context.read<FriendsBloc>().add(
                        FriendRequestRejectRequested(
                          requestId: req.id,
                          userId: widget.userId,
                        ),
                      );
                },
                icon: const Icon(Icons.cancel_rounded, color: AppColors.wrong, size: 32),
                tooltip: s.reject,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 60));
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Add friend dialog — sends REQUEST, not direct add.
  // ---------------------------------------------------------------------------

  void _showAddFriendDialog(BuildContext outerContext, AppStrings s) {
    final friendsBloc = outerContext.read<FriendsBloc>();

    showDialog<String>(
      context: outerContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: friendsBloc,
          child: _AddFriendDialog(userId: widget.userId),
        );
      },
    ).then((selectedFriendId) {
      if (selectedFriendId != null && selectedFriendId.isNotEmpty) {
        // Send friend REQUEST (not direct add).
        friendsBloc.add(
          FriendRequestSendRequested(fromId: widget.userId, toId: selectedFriendId),
        );
        ScaffoldMessenger.of(outerContext)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(s.friendRequestSent, textAlign: TextAlign.center),
              backgroundColor: AppColors.correct,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
          );
      }
      // Reload friends list.
      friendsBloc.add(FriendsLoadRequested(widget.userId));
    });
  }
}

// ---------------------------------------------------------------------------
// Friend list tile with duel button + swipe-to-remove
// ---------------------------------------------------------------------------

class _FriendListTile extends StatelessWidget {
  final FriendEntity friend;
  final int animationDelay;
  final VoidCallback onDismissed;
  final VoidCallback onDuel;

  const _FriendListTile({
    required this.friend,
    required this.animationDelay,
    required this.onDismissed,
    required this.onDuel,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Dismissible(
      key: ValueKey(friend.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.wrong.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.person_remove_rounded, color: AppColors.wrong),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.darkBorder,
                  backgroundImage:
                      friend.photoUrl.isNotEmpty ? NetworkImage(friend.photoUrl) : null,
                  child: friend.photoUrl.isEmpty
                      ? const Icon(Icons.person_rounded, size: 22, color: Colors.white54)
                      : null,
                ),
                if (friend.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.correct,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.darkCard, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name & level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${s.level} ${friend.level}  •  ${friend.score} ${s.pts}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                ],
              ),
            ),
            // Duel button
            GestureDetector(
              onTap: onDuel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_mma_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(s.duel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: animationDelay))
        .slideX(
            begin: 0.1,
            end: 0,
            duration: 300.ms,
            delay: Duration(milliseconds: animationDelay));
  }
}

// ---------------------------------------------------------------------------
// Add friend dialog — searches by code, returns user ID for REQUEST.
// ---------------------------------------------------------------------------

class _AddFriendDialog extends StatefulWidget {
  final String userId;

  const _AddFriendDialog({required this.userId});

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _searchByCode() {
    final value = _codeController.text.trim();
    if (value.isNotEmpty) {
      context.read<FriendsBloc>().add(FriendSearchByIdRequested(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.addFriend,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Code input
            TextField(
              controller: _codeController,
              style:
                  const TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 18),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  letterSpacing: 4,
                  fontSize: 18,
                ),
                counterText: '',
                prefixIcon:
                    const Icon(Icons.tag_rounded, color: AppColors.primary),
                suffixIcon: IconButton(
                  onPressed: _searchByCode,
                  icon:
                      const Icon(Icons.search_rounded, color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _searchByCode(),
            ),
            const SizedBox(height: 8),
            Text(
              s.enterFriendCode,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Results
            SizedBox(
              height: 140,
              child: BlocBuilder<FriendsBloc, FriendsState>(
                builder: (context, state) {
                  if (state is FriendsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (state is FriendsSearchResults) {
                    if (state.users.isEmpty) {
                      return Center(
                        child: Text(s.noUserFound,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5))),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        final isSelf = user.id == widget.userId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.darkBorder.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.darkBorder,
                                backgroundImage: user.photoUrl.isNotEmpty
                                    ? NetworkImage(user.photoUrl)
                                    : null,
                                child: user.photoUrl.isEmpty
                                    ? const Icon(Icons.person_rounded,
                                        size: 18, color: Colors.white54)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    Text(
                                        isSelf
                                            ? s.thisIsYou
                                            : '${s.level} ${user.level}',
                                        style: TextStyle(
                                            color: isSelf
                                                ? AppColors.timerWarning
                                                : Colors.white
                                                    .withValues(alpha: 0.4),
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (!isSelf)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Return user ID — request will be sent after dialog closes.
                                    Navigator.of(context).pop(user.id);
                                  },
                                  icon: const Icon(Icons.send_rounded, size: 14),
                                  label: Text(s.send),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  // Default placeholder
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_rounded,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(s.findFriend,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
