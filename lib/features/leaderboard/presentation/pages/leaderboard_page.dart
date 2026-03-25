import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:word_puzzle/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:word_puzzle/features/leaderboard/presentation/widgets/podium_widget.dart';

/// Full dark-themed leaderboard page.
///
/// The top 3 players are displayed as a podium with medals. Remaining players
/// appear in a scrollable list below showing rank, avatar, name, and score.
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LeaderboardBloc>().add(const LeaderboardLoadRequested());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            child: Column(
              children: [
                _buildAppBar(context),
                _buildSearchBar(s),
                Expanded(
              child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
                builder: (context, state) {
                  if (state is LeaderboardLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (state is LeaderboardError) {
                    return _buildError(context, state.message);
                  }

                  if (state is LeaderboardLoaded) {
                    return _buildLeaderboard(context, state);
                  }

                  // Initial state - trigger load.
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                },
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

  Widget _buildAppBar(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: Text(
              s.leaderboard,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Refresh button.
          IconButton(
            onPressed: () {
              context.read<LeaderboardBloc>().add(
                    const LeaderboardLoadRequested(),
                  );
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: s.isTr ? 'İsim ara...' : 'Search by name...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.4)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: Icon(Icons.clear_rounded,
                      color: Colors.white.withValues(alpha: 0.4)),
                )
              : null,
          filled: true,
          fillColor: AppColors.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, String message) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.leaderboard_rounded,
              color: AppColors.wrong,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              s.failedToLoad,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<LeaderboardBloc>().add(
                      const LeaderboardLoadRequested(),
                    );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Leaderboard content
  // ---------------------------------------------------------------------------

  Widget _buildLeaderboard(BuildContext context, LeaderboardLoaded state) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    final query = _searchController.text.toLowerCase();
    final entries = query.isEmpty
        ? state.entries
        : state.entries
            .where((e) => e.name.toLowerCase().contains(query))
            .toList();

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              s.noPlayersYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // When searching, show all filtered results as a flat list.
    final isSearching = query.isNotEmpty;
    final topThree = isSearching ? <LeaderboardEntry>[] : entries.take(3).toList();
    final rest = isSearching
        ? entries
        : (entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[]);

    return CustomScrollView(
      slivers: [
        if (!isSearching) ...[
        // Trophy header.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 40,
            ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
          ),
        ),

        // Podium.
        SliverToBoxAdapter(
          child: PodiumWidget(topThree: topThree),
        ),

        // Divider.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Divider(
              color: AppColors.darkBorder.withValues(alpha: 0.5),
              thickness: 1,
            ),
          ),
        ),
        ], // end if (!isSearching)

        // Remaining players list (or full search results).
        if (rest.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: rest.length,
              itemBuilder: (context, index) {
                final entry = rest[index];
                return _LeaderboardListTile(
                  entry: entry,
                  animationDelay: index * 50,
                );
              },
            ),
          ),

        // Bottom padding.
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// List tile for rank 4+
// ---------------------------------------------------------------------------

class _LeaderboardListTile extends StatelessWidget {
  final dynamic entry;
  final int animationDelay;

  const _LeaderboardListTile({
    required this.entry,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Rank number.
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar.
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.darkBorder,
            backgroundImage: entry.photoUrl.isNotEmpty
                ? NetworkImage(entry.photoUrl)
                : null,
            child: entry.photoUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: Colors.white54,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Name and level.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.level} ${entry.level}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Score.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry.score}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: animationDelay),
        )
        .slideX(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: animationDelay),
        );
  }
}
