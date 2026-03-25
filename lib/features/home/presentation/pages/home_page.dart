import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/daily_quest_manager.dart';
import 'package:word_puzzle/core/utils/notification_manager.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _dailyResetDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
        if (state is AuthAuthenticated && !_dailyResetDone) {
          _dailyResetDone = true;
          final uid = state.user.id;
          // Save FCM token for push notifications.
          NotificationManager.instance.saveToken(uid);
          // Ensure daily counters are reset if date changed, update streak.
          DailyQuestManager.instance.ensureDailyReset(uid).then((_) {
            // Reload user data to reflect reset values.
            if (mounted) {
              context.read<AuthBloc>().add(const AuthCheckRequested());
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive(context).maxContentWidth,
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  String name = 'Player';
                  String? photoUrl;
                  int score = 0;
                  int totalLevel = 0;
                  int streak = 0;
                  int xp = 0;
                  int gamesPlayedToday = 0;
                  int duelsWonToday = 0;
                  bool friendAddedToday = false;

                  if (state is AuthAuthenticated) {
                    final user = state.user;
                    name = user.name;
                    photoUrl = user.photoUrl;
                    score = user.score;
                    streak = user.streak;
                    xp = user.xp;
                    gamesPlayedToday = user.gamesPlayedToday;
                    duelsWonToday = user.duelsWonToday;
                    friendAddedToday = user.friendAddedToday;
                    if (user.categoryLevels.isNotEmpty) {
                      totalLevel = user.categoryLevels.values
                          .fold(0, (sum, lv) => sum + lv);
                    } else {
                      totalLevel = user.level;
                    }
                  }

                  // XP for level progress (1000 XP per level)
                  final xpForLevel = 1000;
                  final currentXp = xp % xpForLevel;
                  final xpProgress = currentXp / xpForLevel;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header
                        _buildHeader(s, name, photoUrl),
                        const SizedBox(height: 16),

                        // 2. Streak Card
                        _buildStreakCard(s, streak),
                        const SizedBox(height: 16),

                        // 3. Stats Row (Score + Level + Rank)
                        _buildStatsRow(s, score, totalLevel),
                        const SizedBox(height: 16),

                        // 4. XP Progress
                        _buildXpProgress(s, currentXp, xpForLevel, xpProgress),
                        const SizedBox(height: 24),

                        // 5. Daily Quests
                        _buildDailyQuests(
                            s, gamesPlayedToday, duelsWonToday, friendAddedToday),
                        const SizedBox(height: 24),

                        // 6. Play Button
                        _buildPlayButton(s, state),
                        const SizedBox(height: 16),

                        // 7. Menu Row
                        _buildMenuRow(s, state),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header — Avatar + Name + Language + Notification + Settings
  // ---------------------------------------------------------------------------

  Widget _buildHeader(AppStrings s, String name, String? photoUrl) {
    return Row(
      children: [
        // Avatar — tappable, goes to profile page
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: _buildHomeAvatar(name, photoUrl),
        ),
        const SizedBox(width: 12),
        // Greeting + Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.greeting,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Language toggle
        Consumer<AppLanguageNotifier>(
          builder: (context, langNotifier, _) {
            return _iconButton(
              child: Text(langNotifier.language.flag,
                  style: const TextStyle(fontSize: 18)),
              onTap: () => langNotifier.toggle(),
            );
          },
        ),
        const SizedBox(width: 8),
        // Settings / Logout
        _iconButton(
          child: const Icon(Icons.settings_rounded,
              color: Colors.white54, size: 20),
          onTap: () => context.read<AuthBloc>().add(AuthSignOutRequested()),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _iconButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }

  static const _avatarColors = [
    Color(0xFF6C63FF), Color(0xFF03DAC6), Color(0xFFFF6B6B),
    Color(0xFFFF9800), Color(0xFF4CAF50), Color(0xFFE91E63),
    Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFF00BCD4),
    Color(0xFFFF5722), Color(0xFF795548), Color(0xFF607D8B),
  ];
  static const _avatarEmojis = [
    '\u{1F60E}', '\u{1F916}', '\u{1F47E}', '\u{1F98A}', '\u{1F431}', '\u{1F436}',
    '\u{1F981}', '\u{1F438}', '\u{1F984}', '\u{1F3AE}', '\u{1F9D9}', '\u{1F977}',
  ];

  Widget _buildHomeAvatar(String name, String? photoUrl) {
    if (photoUrl != null && photoUrl.startsWith('avatar:')) {
      final idx = int.tryParse(photoUrl.replaceFirst('avatar:', '')) ?? 0;
      final i = idx.clamp(0, _avatarColors.length - 1);
      return Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _avatarColors[i],
          border: Border.all(color: _avatarColors[i].withValues(alpha: 0.5), width: 2),
        ),
        child: Center(child: Text(_avatarEmojis[i], style: const TextStyle(fontSize: 22))),
      );
    }
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarFallback(name)))
          : _avatarFallback(name),
    );
  }

  Widget _avatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Streak Card
  // ---------------------------------------------------------------------------

  Widget _buildStreakCard(AppStrings s, int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B7AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.dailyStreak,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      '$streak ${s.streakDays}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.streakMotivation,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Trophy icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🏅', style: TextStyle(fontSize: 32)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.08);
  }

  // ---------------------------------------------------------------------------
  // 3. Stats Row — Score + Level + Rank
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow(AppStrings s, int score, int totalLevel) {
    final cards = [
      _StatCard(
        emoji: '⭐',
        value: _formatNumber(score),
        label: s.totalScore,
        color: AppColors.timerWarning,
      ),
      _StatCard(
        emoji: '🎯',
        value: '$totalLevel',
        label: s.level,
        color: AppColors.secondary,
      ),
      _StatCard(
        emoji: '🏆',
        value: '#—',
        label: s.rank,
        color: const Color(0xFFFF9800),
      ),
    ];

    return Row(
      children: cards.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: e.key == 0 ? 0 : 4,
              right: e.key == cards.length - 1 ? 0 : 4,
            ),
            child: e.value
                .animate()
                .fadeIn(duration: 350.ms, delay: (150 + e.key * 80).ms)
                .slideY(begin: 0.1),
          ),
        );
      }).toList(),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  // ---------------------------------------------------------------------------
  // 4. XP Progress Bar
  // ---------------------------------------------------------------------------

  Widget _buildXpProgress(
      AppStrings s, int currentXp, int xpForLevel, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.levelProgress,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$currentXp / $xpForLevel XP',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 350.ms);
  }

  // ---------------------------------------------------------------------------
  // 5. Daily Quests
  // ---------------------------------------------------------------------------

  Widget _buildDailyQuests(
      AppStrings s, int gamesPlayed, int duelsWon, bool friendAdded) {
    final quests = [
      _QuestData(
        emoji: '⚡',
        title: s.quickRound,
        progress: '${gamesPlayed.clamp(0, 3)}/3',
        isComplete: gamesPlayed >= 3,
        xpReward: 50,
      ),
      _QuestData(
        emoji: '🏆',
        title: s.winDuel,
        progress: '${duelsWon.clamp(0, 1)}/1',
        isComplete: duelsWon >= 1,
        xpReward: 80,
      ),
      _QuestData(
        emoji: '👥',
        title: s.addFriendQuest,
        progress: friendAdded ? '1/1' : '0/1',
        isComplete: friendAdded,
        xpReward: 30,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.dailyQuests,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: quests.asMap().entries.map((e) {
            final q = e.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: e.key == 0 ? 0 : 5,
                  right: e.key == quests.length - 1 ? 0 : 5,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: q.isComplete
                          ? AppColors.correct.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(q.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(
                        q.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        q.progress,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: q.isComplete
                              ? AppColors.correct.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          q.isComplete
                              ? '✓ ${q.xpReward} XP'
                              : '+${q.xpReward} XP',
                          style: TextStyle(
                            color: q.isComplete
                                ? AppColors.correct
                                : AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                        duration: 350.ms, delay: (400 + e.key * 80).ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      delay: (400 + e.key * 80).ms,
                      duration: 350.ms,
                    ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Play Button
  // ---------------------------------------------------------------------------

  Widget _buildPlayButton(AppStrings s, AuthState state) {
    return GestureDetector(
      onTap: () {
        final uid = state is AuthAuthenticated ? state.user.id : '';
        final catLevels = state is AuthAuthenticated
            ? state.user.categoryLevels
            : <String, int>{};
        final lang = context.read<AppLanguageNotifier>().language.name;
        context.go('/categories', extra: {
          'userId': uid,
          'categoryLevels': catLevels,
          'language': lang,
        });
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              s.startGame,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 550.ms)
        .slideY(begin: 0.1);
  }

  // ---------------------------------------------------------------------------
  // 7. Menu Row — Duel, Rankings, Friends
  // ---------------------------------------------------------------------------

  Widget _buildMenuRow(AppStrings s, AuthState state) {
    final uid = state is AuthAuthenticated ? state.user.id : '';

    final items = [
      _QuickAction(
        icon: Icons.sports_esports_rounded,
        label: s.duel,
        color: AppColors.secondary,
        onTap: () => context.go('/duel', extra: {'userId': uid}),
      ),
      _QuickAction(
        icon: Icons.leaderboard_rounded,
        label: s.rankings,
        color: const Color(0xFFFF9800),
        onTap: () => context.go('/leaderboard'),
      ),
      _QuickAction(
        icon: Icons.people_rounded,
        label: s.friends,
        color: AppColors.accent,
        onTap: () => context.go('/friends', extra: {'userId': uid}),
      ),
    ];

    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 5,
              right: index == items.length - 1 ? 0 : 5,
            ),
            child: GestureDetector(
              onTap: item.onTap,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: item.color.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(
                    delay: (600 + 80 * index).ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.88, 0.88),
                  delay: (600 + 80 * index).ms,
                  duration: 350.ms,
                ),
          ),
        );
      }).toList(),
    );
  }
}

// -----------------------------------------------------------------------------
// Helper widgets
// -----------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestData {
  final String emoji;
  final String title;
  final String progress;
  final bool isComplete;
  final int xpReward;

  _QuestData({
    required this.emoji,
    required this.title,
    required this.progress,
    required this.isComplete,
    required this.xpReward,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
