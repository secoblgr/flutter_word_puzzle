import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/features/duel/data/datasources/duel_remote_datasource.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';
import 'package:word_puzzle/features/duel/presentation/bloc/duel_bloc.dart';

/// Lobby screen where players can create a new duel, join an existing one,
/// or respond to duel invites from friends.
class DuelLobbyPage extends StatefulWidget {
  final String userId;

  const DuelLobbyPage({super.key, required this.userId});

  @override
  State<DuelLobbyPage> createState() => _DuelLobbyPageState();
}

class _DuelLobbyPageState extends State<DuelLobbyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Load both available duels AND pending invites.
        context
            .read<DuelBloc>()
            .add(DuelInvitesLoadRequested(userId: widget.userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive(context).maxContentWidth,
            ),
            child: BlocConsumer<DuelBloc, DuelState>(
          listener: _blocListener,
          builder: (context, state) {
            return Column(
              children: [
                _buildTopBar(context, s),
                const SizedBox(height: 16),
                _buildCreateButton(context, s),
                const SizedBox(height: 20),
                // Pending invites section
                _buildInvitesSection(context, state),
                const SizedBox(height: 16),
                _buildSectionTitle(s.availableDuels),
                const SizedBox(height: 8),
                Expanded(child: _buildDuelList(context, state, s)),
              ],
            );
          },
          ),
        ),
      ),
      ),
    );
  }

  void _blocListener(BuildContext context, DuelState state) {
    if (state is DuelCreated) {
      context.go('/duel/room', extra: {
        'duelId': state.duel.id,
        'userId': widget.userId,
      });
    }

    if (state is DuelPlaying) {
      context.go('/duel/room', extra: {
        'duelId': state.duel.id,
        'userId': widget.userId,
      });
    }

    if (state is DuelInviteAccepted) {
      // Navigate to the duel room.
      context.go('/duel/room', extra: {
        'duelId': state.duelId,
        'userId': widget.userId,
      });
    }

    if (state is DuelInviteRejected) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Duel invite rejected', textAlign: TextAlign.center),
            backgroundColor: Colors.white24,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          ),
        );
      // Reload.
      context.read<DuelBloc>().add(DuelInvitesLoadRequested(userId: widget.userId));
    }

    if (state is DuelError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.wrong,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Text(s.duelArena,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            onPressed: () {
              context.read<DuelBloc>().add(DuelInvitesLoadRequested(userId: widget.userId));
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ---------------------------------------------------------------------------
  // Create button
  // ---------------------------------------------------------------------------

  Widget _buildCreateButton(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            context.read<DuelBloc>().add(DuelCreateRequested(playerId: widget.userId));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, size: 24),
              const SizedBox(width: 10),
              Text(s.createDuel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, duration: 400.ms, delay: 100.ms);
  }

  // ---------------------------------------------------------------------------
  // Section title
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Invites section
  // ---------------------------------------------------------------------------

  Widget _buildInvitesSection(BuildContext context, DuelState state) {
    List<DuelInviteModel> invites = [];
    if (state is DuelAvailableList) {
      invites = state.pendingInvites;
    }

    if (invites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Duel Invites'),
        const SizedBox(height: 8),
        ...invites.asMap().entries.map((entry) {
          final index = entry.key;
          final invite = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_mma_rounded,
                        color: Color(0xFFFF6B6B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invite.fromName.isNotEmpty ? invite.fromName : 'Unknown',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text('wants to duel you!',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      ],
                    ),
                  ),
                  // Accept
                  IconButton(
                    onPressed: () {
                      context.read<DuelBloc>().add(
                            DuelInviteAcceptRequested(
                              inviteId: invite.id,
                              userId: widget.userId,
                            ),
                          );
                    },
                    icon: const Icon(Icons.check_circle_rounded,
                        color: AppColors.correct, size: 32),
                    tooltip: 'Accept',
                  ),
                  // Reject
                  IconButton(
                    onPressed: () {
                      context.read<DuelBloc>().add(
                            DuelInviteRejectRequested(
                              inviteId: invite.id,
                              userId: widget.userId,
                            ),
                          );
                    },
                    icon: const Icon(Icons.cancel_rounded, color: AppColors.wrong, size: 32),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 60)),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Duel list
  // ---------------------------------------------------------------------------

  Widget _buildDuelList(BuildContext context, DuelState state, AppStrings s) {
    if (state is DuelLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state is DuelAvailableList) {
      if (state.duels.isEmpty) {
        return _buildEmptyState(s);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.duels.length,
        itemBuilder: (context, index) {
          return _buildDuelCard(context, state.duels[index], index);
        },
      );
    }

    return _buildEmptyState(s);
  }

  Widget _buildEmptyState(AppStrings s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_esports_outlined,
              color: Colors.white.withValues(alpha: 0.2), size: 64),
          const SizedBox(height: 16),
          Text(s.noDuelsAvailable,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)),
          const SizedBox(height: 8),
          Text(s.createOneInvite,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildDuelCard(BuildContext context, DuelEntity duel, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Player ${duel.player1Id.substring(0, duel.player1Id.length.clamp(0, 6))}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded,
                        color: Colors.white.withValues(alpha: 0.4), size: 14),
                    const SizedBox(width: 4),
                    Text('${duel.wordIds.length} words',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                context.read<DuelBloc>().add(
                      DuelJoinRequested(duelId: duel.id, playerId: widget.userId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.darkBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (80 * index).ms)
        .slideX(begin: 0.1, duration: 300.ms, delay: (80 * index).ms);
  }
}
